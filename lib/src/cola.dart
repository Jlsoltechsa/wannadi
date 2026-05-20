import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart' show Sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'event.dart';
import 'result.dart';

/// Local-first outbox.
///
/// 1. [enqueue] writes a [ColaEvent] to a SQLite table.
/// 2. [flush] POSTs a batch to [endpoint] (auto-fired on enqueue and on
///    a [flushInterval] timer).
/// 3. The server's response is interpreted row by row:
///    - status ∈ [terminalStatuses] → the row is deleted from the outbox.
///    - any other status → `attempts` is bumped, `last_error` is stored,
///      and the row stays in the queue for the next cycle.
///
/// Network failures (timeout / non-200 / parse error) bump `attempts` on
/// every queued row and leave them in place — no row is ever dropped on
/// a transport failure.
///
/// The engine is agnostic of how the host app obtains its bearer token.
/// Pass a [tokenProvider]; if it returns `null`, the request is sent
/// without an `Authorization` header. Pass `null` as the provider to
/// skip auth entirely.
class Cola extends ChangeNotifier {
  Cola({
    required this.endpoint,
    this.tokenProvider,
    this.databaseName = 'cola.db',
    this.tableName = 'cola_events',
    this.flushInterval = const Duration(seconds: 30),
    this.batchSize = 50,
    this.terminalStatuses = const {'applied', 'duplicate', 'stale'},
    this.httpClient,
  });

  /// URL to POST batches to. Receives a JSON body of shape
  /// `{ "events": [ColaEvent.toJson(), …] }`.
  final Uri endpoint;

  /// How to obtain the bearer token for each request. Called once per
  /// flush. Return `null` to skip the `Authorization` header for that
  /// flush; the whole field may be `null` to skip auth entirely.
  final Future<String?> Function()? tokenProvider;

  /// SQLite file name. Defaults to `'cola.db'`.
  final String databaseName;

  /// SQLite table name. Defaults to `'cola_events'`.
  final String tableName;

  /// How often the background timer attempts a [flush]. Defaults to 30 s.
  final Duration flushInterval;

  /// Max number of rows per flush. Larger queues spread over several
  /// flushes; smaller batches reduce request size.
  final int batchSize;

  /// Server statuses that mean "you may delete this row from the
  /// outbox". Anything outside the set is kept for retry.
  final Set<String> terminalStatuses;

  /// Optional HTTP client override (useful for tests).
  final http.Client? httpClient;

  Database? _db;
  Timer? _timer;
  bool _flushing = false;
  int _pending = 0;
  String? _lastError;

  /// Rows currently waiting to be flushed.
  int get pending => _pending;

  /// Last transport-level error, or `null` when the previous flush
  /// succeeded.
  String? get lastError => _lastError;

  /// Whether [init] has been called and the DB is ready.
  bool get isReady => _db != null;

  /// Opens (or creates) the SQLite database and starts the background
  /// flush timer. Must be awaited before [enqueue] or [flush] are used.
  Future<void> init() async {
    _db = await openDatabase(
      databaseName,
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE $tableName (
            client_event_id TEXT PRIMARY KEY,
            type            TEXT NOT NULL,
            entity_type     TEXT,
            entity_id       TEXT,
            payload         TEXT,
            metadata        TEXT,
            occurred_at     TEXT NOT NULL,
            attempts        INTEGER NOT NULL DEFAULT 0,
            last_error      TEXT,
            created_at      TEXT NOT NULL
          )
        ''');
      },
    );
    await _refreshPendingCount();
    _timer = Timer.periodic(flushInterval, (_) => flush());
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _db?.close();
    _db = null;
    super.dispose();
  }

  /// Persists [event] to the outbox and triggers an opportunistic flush.
  /// Returns the [ColaEvent.clientEventId] used (auto-generated when the
  /// caller doesn't pass one).
  Future<String> enqueue(ColaEvent event) async {
    final db = _db;
    if (db == null) throw StateError('Cola.init() must be awaited first');
    final now = DateTime.now().toUtc();
    await db.insert(tableName, {
      'client_event_id': event.clientEventId,
      'type': event.type,
      'entity_type': event.entityType,
      'entity_id': event.entityId,
      'payload': event.payload == null ? null : jsonEncode(event.payload),
      'metadata': event.metadata.isEmpty ? null : jsonEncode(event.metadata),
      'occurred_at': event.occurredAt.toIso8601String(),
      'attempts': 0,
      'created_at': now.toIso8601String(),
    });
    await _refreshPendingCount();
    unawaited(flush());
    return event.clientEventId;
  }

  /// Drops every queued event without contacting the server. Use only
  /// when the user logs out or the local database is reset.
  Future<void> clear() async {
    final db = _db;
    if (db == null) return;
    await db.delete(tableName);
    await _refreshPendingCount();
  }

  /// Dispatches up to [batchSize] events to [endpoint]. Safe to call
  /// concurrently — overlapping calls return immediately.
  Future<void> flush() async {
    if (_flushing) return;
    final db = _db;
    if (db == null) return;
    _flushing = true;
    try {
      final rows = await db.query(
        tableName,
        orderBy: 'created_at ASC',
        limit: batchSize,
      );
      if (rows.isEmpty) {
        _lastError = null;
        return;
      }

      final events = [
        for (final r in rows) _rowToWire(r),
      ];

      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (tokenProvider != null) {
        final tok = await tokenProvider!.call();
        if (tok != null) headers['Authorization'] = 'Bearer $tok';
      }

      try {
        final client = httpClient ?? http.Client();
        final res = await client.post(
          endpoint,
          headers: headers,
          body: utf8.encode(jsonEncode({'events': events})),
        );
        if (httpClient == null) client.close();

        if (res.statusCode < 200 || res.statusCode >= 300) {
          _lastError = 'HTTP ${res.statusCode}';
          await _bumpAttempts(rows, _lastError!);
          return;
        }
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final results = (body['results'] as List)
            .map((e) =>
                ColaEventResult.fromJson((e as Map).cast<String, dynamic>()))
            .toList();

        for (final r in results) {
          if (terminalStatuses.contains(r.status)) {
            await db.delete(
              tableName,
              where: 'client_event_id = ?',
              whereArgs: [r.clientEventId],
            );
          } else {
            final existing = rows.firstWhere(
              (e) => e['client_event_id'] == r.clientEventId,
              orElse: () => const {},
            );
            final prevAttempts = (existing['attempts'] as int?) ?? 0;
            await db.update(
              tableName,
              {
                'attempts': prevAttempts + 1,
                'last_error': r.detail ?? r.status,
              },
              where: 'client_event_id = ?',
              whereArgs: [r.clientEventId],
            );
          }
        }
        _lastError = null;
      } catch (e) {
        _lastError = e.toString();
        await _bumpAttempts(rows, _lastError!);
      }
    } finally {
      _flushing = false;
      await _refreshPendingCount();
    }
  }

  Map<String, dynamic> _rowToWire(Map<String, dynamic> row) {
    final out = <String, dynamic>{
      'client_event_id': row['client_event_id'],
      'type': row['type'],
      if (row['entity_type'] != null) 'entity_type': row['entity_type'],
      if (row['entity_id'] != null) 'entity_id': row['entity_id'],
      if (row['payload'] != null)
        'payload': jsonDecode(row['payload'] as String),
      'occurred_at': row['occurred_at'],
    };
    if (row['metadata'] != null) {
      final md = (jsonDecode(row['metadata'] as String) as Map)
          .cast<String, dynamic>();
      out.addAll(md);
    }
    return out;
  }

  Future<void> _bumpAttempts(
    List<Map<String, dynamic>> rows,
    String error,
  ) async {
    final db = _db!;
    for (final r in rows) {
      await db.update(
        tableName,
        {
          'attempts': ((r['attempts'] as int?) ?? 0) + 1,
          'last_error': error,
        },
        where: 'client_event_id = ?',
        whereArgs: [r['client_event_id']],
      );
    }
  }

  Future<void> _refreshPendingCount() async {
    final db = _db;
    if (db == null) return;
    final c = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $tableName')) ??
        0;
    if (c != _pending) {
      _pending = c;
      notifyListeners();
    }
  }
}
