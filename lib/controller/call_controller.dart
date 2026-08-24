import 'dart:async';
import 'dart:developer';

import 'package:call_connect/core/app_constants.dart';

import 'package:call_connect/data/call_repository.dart';
import 'package:call_connect/data/provider.dart';
import 'package:call_connect/model/call_data_model.dart';
import 'package:call_connect/model/call_event.dart';
import 'package:call_connect/model/call_session_state.dart';
import 'package:call_connect/model/call_state.dart';
import 'package:call_connect/services/call_event_service.dart';
import 'package:call_connect/services/call_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class CallController extends Notifier<CallSessionState> {
  late CallEventService events;
  late CallKitService callKit;
  late CallRepository repo;
  final uuid = const Uuid();
  Timer? _ticker;
  StreamSubscription<CallEvent>? eventSub;
  StreamSubscription<CallKitAction>? kitSub;
  final Set<String> _callKitPrompted = {};

  @override
  CallSessionState build() {
    repo = ref.watch(callRepositoryProvider);
    events = ref.watch(callEventServiceProvider);
    callKit = ref.watch(callKitServiceProvider);

    eventSub = events.events.listen(_onRemoteEvent);
    kitSub = callKit.actions.listen(_onCallKitAction);

    ref.onDispose(() {
      eventSub?.cancel();
      kitSub?.cancel();
      _ticker?.cancel();
    });

    Future.microtask(_loadInitialData);
    return const CallSessionState(isRecovering: true);
  }

  Future<void> _loadInitialData() async {
    try {
      final history = await repo.getHistory();
      final active = await repo.getActiveCall();

      state = state.copyWith(
        history: history,
        activeCall: active,
        isRecovering: false,
        isConnected: true,
      );
    } catch (e) {
      state = state.copyWith(
        isRecovering: false,
        lastMessage: 'Failed to load call history: $e',
      );
    }
  }

  //trigger incoming call
  Future<void> incomingCall() async {
    final callId = uuid.v4();

    log('INCOMING BUTTON PRESSED');
    log('Generated callId: $callId');

    events.simulateIncoming(
      callId: callId,
      callerId: AppUsers.localUser,
      calleeId: AppUsers.remoteUser,
    );
  }

  Future<void> _onRemoteEvent(CallEvent event) async {
    log('REMOTE EVENT RECEIVED: ${event.type}');
    log('CALL ID: ${event.callId}');
    log('CALLER: ${event.callerId}');
    log('CALLEE: ${event.calleeId}');
    try {
      switch (event.type) {
        case CallEventType.incomingCall:
          await _handleIncoming(event);
        case CallEventType.remoteCancel:
          await _handleRemoteCancel(event);
        case CallEventType.remoteEnd:
          await _handleRemoteEnd(event);
        case CallEventType.acceptAck:
          // Optional server ACK — already CONNECTED locally.
          break;
        case CallEventType.malformed:
          state = state.copyWith(
            lastMessage: 'Ignored malformed / dropped event: ${event.raw}',
          );
      }
    } catch (e) {
      state = state.copyWith(lastMessage: 'Event handling error: $e');
    }
  }

  Future<void> _handleIncoming(CallEvent event) async {
    log('========== HANDLE INCOMING ==========');
    log('callId: ${event.callId}');
    log('callerId: ${event.callerId}');
    log('calleeId: ${event.calleeId}');
    final callId = event.callId;
    final callerId = event.callerId;
    final calleeId = event.calleeId;

    if (callId == null ||
        callId.isEmpty ||
        callerId == null ||
        calleeId == null) {
      state = state.copyWith(lastMessage: 'Malformed incoming_call payload');
      return;
    }

    log('1. BEFORE getById');
    final existing = await repo.getById(callId);
    log('2. AFTER getById: $existing');
    if (existing != null) {
      state = state.copyWith(
        activeCall: existing.state.isActive ? existing : state.activeCall,
        lastMessage: 'Duplicate incoming_call ignored for $callId',
      );
      // Still ensure we do not show a second CallKit prompt.
      return;
    }

    log('3. BEFORE getActiveCall');
    final active = await repo.getActiveCall();
    log('4. AFTER getActiveCall: $active');
    if (active != null) {
      state = state.copyWith(
        lastMessage:
            'Busy — already in ${active.state.label} (${active.callId})',
      );
      return;
    }

    final now = DateTime.now();
    final call = CallDataModel(
      callId: callId,
      callerId: callerId,
      calleeId: calleeId,
      state: CallState.ringing,
      createdAt: now,
      updatedAt: now,
    );
    log('5. BEFORE insert');
    final inserted = await repo.insertIfAbsent(call);
    log('CALL INSERTED: $inserted');
    if (!inserted) {
      state = state.copyWith(lastMessage: 'Race: call $callId already stored');
      return;
    }

    if (!_callKitPrompted.contains(callId)) {
      _callKitPrompted.add(callId);
      await callKit.showIncomingCall(callId: callId, callerName: callerId);
    }

    await _reload(
      activeOverride: call,
      message: 'Incoming call from $callerId',
    );
    log('ACTIVE CALL: ${state.activeCall?.callId}');
    log('HISTORY COUNT: ${state.history.length}');
  }

  Future<void> _handleRemoteCancel(CallEvent event) async {
    final callId = event.callId;
    if (callId == null) {
      state = state.copyWith(lastMessage: 'Cancel missing call_id');
      return;
    }
    final call = await repo.getById(callId);
    if (call == null) {
      state = state.copyWith(lastMessage: 'Unknown call_id on cancel: $callId');
      return;
    }
    final updated = await _transition(
      callId,
      CallState.cancelled,
      endReason: 'remote_cancel',
      source: 'remote',
    );
    if (updated != null) {
      await callKit.endCall(callId);
    } else {
      state = state.copyWith(
        lastMessage: 'Cancel ignored — state was ${call.state.label}',
      );
    }
  }

  Future<void> _handleRemoteEnd(CallEvent event) async {
    final callId = event.callId;
    if (callId == null) return;
    await _end(callId, reason: 'remote_end', source: 'remote');
  }

  Future<void> _onCallKitAction(CallKitAction action) async {
    switch (action.type) {
      case CallKitActionType.accept:
        await _accept(action.callId, source: 'callkit');
      case CallKitActionType.decline:
      case CallKitActionType.timeout:
        await _transition(
          action.callId,
          CallState.rejected,
          endReason: action.type.name,
          source: 'callkit',
        );
      case CallKitActionType.ended:
        await _end(action.callId, reason: 'callkit_ended', source: 'callkit');
    }
  }

  Future<void> _accept(String callId, {required String source}) async {
    final call = await repo.getById(callId);
    if (call == null) {
      state = state.copyWith(lastMessage: 'Accept ignored — unknown $callId');
      return;
    }

    if (call.state == CallState.accepting ||
        call.state == CallState.connected) {
      state = state.copyWith(
        lastMessage:
            'Duplicate accept ignored ($source) — already ${call.state.label}',
      );
      return;
    }

    if (call.state.isTerminal) {
      state = state.copyWith(
        lastMessage: 'Accept failed safely — call already ${call.state.label}',
      );
      return;
    }

    final accepting = await _transition(
      callId,
      CallState.accepting,
      source: source,
    );
    if (accepting == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 350));
    final connected = await _transition(
      callId,
      CallState.connected,
      source: source,
    );
    if (connected != null) {
      _startTicker(connected.connectedAt ?? DateTime.now());
    }
  }

  Future<void> _end(
    String callId, {
    required String reason,
    required String source,
  }) async {
    final call = await repo.getById(callId);
    if (call == null) return;

    if (call.state == CallState.ended ||
        call.state == CallState.ending && reason == call.endReason) {
      state = state.copyWith(lastMessage: 'End already handled for $callId');
      return;
    }

    if (call.state.isTerminal) {
      state = state.copyWith(
        lastMessage: 'End no-op — already ${call.state.label}',
      );
      return;
    }

    if (call.state == CallState.ending) {
      await _transition(
        callId,
        CallState.ended,
        endReason: call.endReason ?? reason,
        source: source,
      );
      await callKit.endCall(callId);
      _stopTicker();
      return;
    }

    if (call.state == CallState.connected ||
        call.state == CallState.accepting) {
      final ending = await _transition(
        callId,
        call.state == CallState.connected
            ? CallState.ending
            : CallState.cancelled,
        endReason: reason,
        source: source,
      );
      if (ending == null) return;

      if (ending.state == CallState.ending) {
        await _transition(
          callId,
          CallState.ended,
          endReason: reason,
          source: source,
        );
      }
      await callKit.endCall(callId);
      _stopTicker();
      return;
    }

    // RINGING remote-end is treated as cancel.
    if (call.state == CallState.ringing) {
      await _transition(
        callId,
        CallState.cancelled,
        endReason: reason,
        source: source,
      );
      await callKit.endCall(callId);
    }
  }

  Future<CallDataModel?> _transition(
    String callId,
    CallState next, {
    String? endReason,
    required String source,
  }) async {
    try {
      final updated = await repo.updateState(
        callId,
        next,
        endReason: endReason,
      );
      if (updated == null) {
        final current = await repo.getById(callId);
        state = state.copyWith(
          lastMessage:
              'Invalid transition blocked ($source): ${current?.state.label} → ${next.label}',
        );
        return null;
      }

      final clear = updated.state.isTerminal;
      await _reload(
        activeOverride: clear ? null : updated,
        clearActive: clear,
        message:
            '${updated.state.label} via $source'
            '${endReason != null ? ' ($endReason)' : ''}',
      );
      return updated;
    } catch (e) {
      state = state.copyWith(lastMessage: 'SQLite update failed: $e');

      try {
        await repo.updateState(callId, CallState.failed, endReason: 'error:$e');
      } catch (_) {}
      return null;
    }
  }

  Future<void> _reload({
    CallDataModel? activeOverride,
    bool clearActive = false,
    String? message,
  }) async {
    final history = await repo.getHistory();
    final active = clearActive
        ? null
        : (activeOverride ?? await repo.getActiveCall());
    state = state.copyWith(
      activeCall: active,
      history: history,
      lastMessage: message,
      clearActive: clearActive || active == null,
      connectedDuration: active?.state == CallState.connected
          ? state.connectedDuration
          : Duration.zero,
    );
  }

  //ui actions
  Future<void> acceptCall() async {
    final call = state.activeCall;
    if (call == null) return;
    await _accept(call.callId, source: 'ui');
  }

  Future<void> rejectCall() async {
    final call = state.activeCall;
    if (call == null) return;
    await _transition(
      call.callId,
      CallState.rejected,
      endReason: 'local_reject',
      source: 'ui',
    );
    await callKit.endCall(call.callId);
  }

  Future<void> endCall() async {
    final call = state.activeCall;
    if (call == null) return;
    await _end(call.callId, reason: 'local_end', source: 'ui');
  }

  void _startTicker(DateTime connectedAt) {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(connectedAt);
      state = state.copyWith(connectedDuration: elapsed);
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }
}

final callControllerProvider =
    NotifierProvider<CallController, CallSessionState>(CallController.new);
