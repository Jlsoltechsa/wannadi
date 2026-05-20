/// One entry of the server's response to a `/ingest` call.
///
/// The server is expected to reply with a JSON body of shape
/// `{ "results": [ {client_event_id, status, detail?}, ... ] }`.
class ColaEventResult {
  const ColaEventResult({
    required this.clientEventId,
    required this.status,
    this.detail,
  });

  /// Mirrors the id the client sent.
  final String clientEventId;

  /// Server's verdict. The framework treats every status listed in
  /// [Cola.terminalStatuses] as "the row may be dropped from the local
  /// outbox"; everything else is retried.
  final String status;

  /// Optional human-readable detail for non-terminal statuses.
  final String? detail;

  factory ColaEventResult.fromJson(Map<String, dynamic> json) =>
      ColaEventResult(
        clientEventId: json['client_event_id'] as String,
        status: json['status'] as String,
        detail: json['detail']?.toString(),
      );
}
