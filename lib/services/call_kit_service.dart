import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart' as ck;
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

abstract class CallKitService {
  Stream<CallKitAction> get actions;

  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
  });

  Future<void> endCall(String callId);
}

enum CallKitActionType { accept, decline, timeout, ended }

class CallKitAction {
  final CallKitActionType type;
  final String callId;

  const CallKitAction({required this.type, required this.callId});
}

class MockCallKitService implements CallKitService {
  final _controller = StreamController<CallKitAction>.broadcast();
  final List<String> shownCallIds = [];
  final List<String> endedCallIds = [];

  @override
  Stream<CallKitAction> get actions => _controller.stream;

  @override
  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
  }) async {
    if (shownCallIds.contains(callId)) return;
    shownCallIds.add(callId);
    debugPrint('[MockCallKit] showIncomingCall $callId from $callerName');
  }

  @override
  Future<void> endCall(String callId) async {
    endedCallIds.add(callId);
    debugPrint('[MockCallKit] endCall $callId');
  }

  void simulateAccept(String callId) {
    _controller.add(
      CallKitAction(type: CallKitActionType.accept, callId: callId),
    );
  }

  void simulateDecline(String callId) {
    _controller.add(
      CallKitAction(type: CallKitActionType.decline, callId: callId),
    );
  }

  void dispose() {
    _controller.close();
  }
}

class MobileCallKitService implements CallKitService {
  final _controller = StreamController<CallKitAction>.broadcast();
  final Set<String> _shown = {};
  StreamSubscription<ck.CallEvent?>? _sub;

  MobileCallKitService() {
    _sub = FlutterCallkitIncoming.onEvent.listen(_onEvent);
  }

  void _onEvent(ck.CallEvent? event) {
    switch (event) {
      case ck.CallEventActionCallAccept(:final callKitParams):
        _controller.add(
          CallKitAction(
            type: CallKitActionType.accept,
            callId: callKitParams.id,
          ),
        );
      case ck.CallEventActionCallDecline(:final callKitParams):
        _controller.add(
          CallKitAction(
            type: CallKitActionType.decline,
            callId: callKitParams.id,
          ),
        );
      case ck.CallEventActionCallTimeout(:final id):
        _controller.add(
          CallKitAction(type: CallKitActionType.timeout, callId: id),
        );
      case ck.CallEventActionCallEnded(:final callKitParams):
        _controller.add(
          CallKitAction(
            type: CallKitActionType.ended,
            callId: callKitParams.id,
          ),
        );
      default:
        break;
    }
  }

  @override
  Stream<CallKitAction> get actions => _controller.stream;

  @override
  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
  }) async {
    if (_shown.contains(callId)) return;
    _shown.add(callId);

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Call App',
      type: 0,
      duration: 45000,
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed call',
      ),
      extra: <String, dynamic>{'userId': callerName},
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#1B2838',
        actionColor: '#0D7377',
        textColor: '#ffffff',
      ),
      ios: const IOSParams(
        handleType: 'generic',
        supportsVideo: false,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  @override
  Future<void> endCall(String callId) async {
    _shown.remove(callId);
    await FlutterCallkitIncoming.endCall(callId);
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}

CallKitService createCallKitService() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      if (kIsWeb) return MockCallKitService();
      return MobileCallKitService();
    default:
      return MockCallKitService();
  }
}
