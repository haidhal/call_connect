enum CallEventType {
  incomingCall,
  remoteCancel,
  remoteEnd,
  acceptAck,
  malformed,
}

class CallEvent {
  final CallEventType type;
  final String? callId;
  final String? callerId;
  final String? calleeId;
  final DateTime at;
  final Map<String, dynamic>? raw;

  CallEvent({
    required this.type,
    this.callId,
    this.callerId,
    this.calleeId,
    DateTime? at,
    this.raw,
  }) : at = at ?? DateTime.now();

  @override
  String toString() =>
      '${type.name}(callId=$callId, caller=$callerId, callee=$calleeId)';
}
