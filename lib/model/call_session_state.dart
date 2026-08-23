import 'package:call_connect/model/call_data_model.dart';

class CallSessionState {
  final CallDataModel? activeCall;
  final List<CallDataModel> history;
  final bool isRecovering;
  final bool isConnected;
  final String? lastMessage;
  final Duration connectedDuration;

  const CallSessionState({
    this.activeCall,
    this.history = const [],
    this.isRecovering = false,
    this.isConnected = true,
    this.lastMessage,
    this.connectedDuration = Duration.zero,
  });
  CallSessionState copyWith({
    CallDataModel? activeCall,
    List<CallDataModel>? history,
    bool? isRecovering,
    bool? isConnected,
    String? lastMessage,
    Duration? connectedDuration,
    bool clearActive = false,
  }) {
    return CallSessionState(
      activeCall: clearActive ? null : (activeCall ?? this.activeCall),
      history: history ?? this.history,
      isRecovering: isRecovering ?? this.isRecovering,
      isConnected: isConnected ?? this.isConnected,
      lastMessage: lastMessage ?? this.lastMessage,
      connectedDuration: connectedDuration ?? this.connectedDuration,
    );
  }
}