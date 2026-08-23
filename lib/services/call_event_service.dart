import 'dart:async';

import 'package:call_connect/model/call_event.dart';

class CallEventService {
  final controller = StreamController<CallEvent>.broadcast();
  bool isConnected = true;
  final List<CallEvent> history = [];

  Stream<CallEvent> get events => controller.stream;
  void emit(CallEvent event) {
    if (!isConnected && event.type != CallEventType.malformed) {
      history.add(
        CallEvent(
          type: CallEventType.malformed,
          callId: event.callId,
          raw: {'error': 'not_connected', 'dropped': event.type.name},
        ),
      );
      return;
    }
    history.add(event);
    if (history.length > 20) {
      history.removeAt(0);
    }
    controller.add(event);
  }

  void simulateIncoming({
    required String callId,
    required String callerId,
    required String calleeId,
  }) {
    emit(
      CallEvent(
        type: CallEventType.incomingCall,
        callId: callId,
        callerId: callerId,
        calleeId: calleeId,
      ),
    );
  }

  void dispose() {
    controller.close();
  }
}
