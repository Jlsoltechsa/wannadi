import 'package:uuid/uuid.dart';

/// A single unit of work to be flushed to the server.
///
/// Events are JSON-serializable. The framework adds a UUID when missing
/// and stamps `occurred_at` so the server receives a monotonically
/// increasing timeline.
///
/// `payload` carries the user-facing data of the action (e.g. the new
/// note's title). `metadata` carries flat string-valued tags used for
/// routing on the server side (tenant id, instance id, actor id, …).
/// The wire format flattens `metadata` to top-level keys so backends
/// can index without unpacking nested JSON.
class ColaEvent {
  ColaEvent({
    String? clientEventId,
    required this.type,
    this.entityType,
    this.entityId,
    this.payload,
    this.metadata = const {},
    DateTime? occurredAt,
  })  : clientEventId = clientEventId ?? const Uuid().v4(),
        occurredAt = occurredAt ?? DateTime.now().toUtc();

  /// Stable identifier the server uses to dedupe retries.
  final String clientEventId;

  /// Short verb describing the action — `'note.create'`,
  /// `'attendance.mark'`, etc. Routed server-side.
  final String type;

  /// Optional entity classification — e.g. `'note'`, `'student'`.
  final String? entityType;

  /// Optional entity primary key on the server.
  final String? entityId;

  /// Action payload. Anything JSON-encodable.
  final Map<String, dynamic>? payload;

  /// Routing tags. Flattened to top-level keys on the wire.
  final Map<String, String> metadata;

  /// Logical event time (UTC). Defaults to "now" at construction.
  final DateTime occurredAt;

  /// Wire format. Keys in [metadata] are merged at the top level so
  /// they can be indexed without unpacking the payload.
  Map<String, dynamic> toJson() => {
        'client_event_id': clientEventId,
        'type': type,
        if (entityType != null) 'entity_type': entityType,
        if (entityId != null) 'entity_id': entityId,
        if (payload != null) 'payload': payload,
        'occurred_at': occurredAt.toIso8601String(),
        ...metadata,
      };
}
