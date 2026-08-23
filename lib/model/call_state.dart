/// RINGING - ACCEPTING - CONNECTED - ENDING - ENDED
/// REJECTED, CANCELLED, or FAILED.
enum CallState {
  ringing,
  accepting,
  connected,
  ending,
  ended,
  rejected,
  cancelled,
  failed;

  String get label => name.toUpperCase();

  bool get isTerminal {
    return this == CallState.ended ||
        this == CallState.rejected ||
        this == CallState.cancelled ||
        this == CallState.failed;
  }

  bool get isActive {
    return !isTerminal;
  }

  static const List<CallState> mainFlow = [
    CallState.ringing,
    CallState.accepting,
    CallState.connected,
    CallState.ending,
    CallState.ended,
  ];
}

class CallStateMachine {
  CallStateMachine._();

  static const Map<CallState, Set<CallState>> allowedTransitions = {
    CallState.ringing: {
      CallState.accepting,
      CallState.rejected,
      CallState.cancelled,
      CallState.failed,
    },

    CallState.accepting: {
      CallState.connected,
      CallState.cancelled,
      CallState.failed,
    },

    CallState.connected: {CallState.ending, CallState.failed},

    CallState.ending: {CallState.ended, CallState.failed},

    CallState.ended: {},
    CallState.rejected: {},
    CallState.cancelled: {},
    CallState.failed: {},
  };

  static bool canTransition(CallState currentState, CallState nextState) {
    return allowedTransitions[currentState]?.contains(nextState) ?? false;
  }

  static CallState? tryTransition(CallState currentState, CallState nextState) {
    if (currentState == nextState) {
      return currentState;
    }

    if (canTransition(currentState, nextState)) {
      return nextState;
    }

    return null;
  }
}
