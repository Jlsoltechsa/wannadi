/// wannadi/queue — local-first offline queue.
///
/// Persists user actions to SQLite and flushes them to a configurable
/// HTTP endpoint with retries. See [`USAGE.md`](USAGE.md) for the full
/// API; the short version is:
///
/// ```dart
/// final cola = Cola(
///   endpoint: Uri.parse('https://api.example.com/sync/ingest'),
///   tokenProvider: () async => auth.token,
/// );
/// await cola.init();
///
/// await cola.enqueue(ColaEvent(
///   type: 'note.create',
///   payload: {'title': 'Hello'},
/// ));
/// ```
library;

export 'src/cola.dart';
export 'src/event.dart';
export 'src/result.dart';
