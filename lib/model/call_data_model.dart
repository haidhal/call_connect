import 'call_state.dart';

class CallDataModel {
  final String callId;
  final String callerId;
  final String calleeId;
  final CallState state;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? connectedAt;
  final DateTime? endedAt;
  final String? endReason;

  const CallDataModel({
    required this.callId,
    required this.callerId,
    required this.calleeId,
    required this.state,
    required this.createdAt,
    required this.updatedAt,
    this.connectedAt,
    this.endedAt,
    this.endReason,
  });

  CallDataModel copyWith({
    CallState? state,
    DateTime? updatedAt,
    DateTime? connectedAt,
    DateTime? endedAt,
    String? endReason,
  }) {
    return CallDataModel(
      callId: callId,
      callerId: callerId,
      calleeId: calleeId,
      state: state ?? this.state,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      connectedAt: connectedAt ?? this.connectedAt,
      endedAt: endedAt ?? this.endedAt,
      endReason: endReason ?? this.endReason,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'call_id': callId,
      'caller_id': callerId,
      'callee_id': calleeId,
      'state': state.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'connected_at': connectedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'end_reason': endReason,
    };
  }

  factory CallDataModel.fromMap(Map<String, Object?> map) {
    return CallDataModel(
      callId: map['call_id'] as String,
      callerId: map['caller_id'] as String,
      calleeId: map['callee_id'] as String,
      state: CallState.values.byName(map['state'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      connectedAt: map['connected_at'] != null
          ? DateTime.parse(map['connected_at'] as String)
          : null,
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      endReason: map['end_reason'] as String?,
    );
  }
}
