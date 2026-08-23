import 'package:call_connect/controller/call_controller.dart';
import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/model/call_state.dart';
import 'package:call_connect/presentation/widgets/call_status_card.dart';
import 'package:call_connect/presentation/widgets/status_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);
    final call = session.activeCall;

    if (call == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Active call')),
        body: const Center(child: Text('No active call')),
      );
    }
    final ringing = call.state == CallState.ringing;
    final connected = call.state == CallState.connected;
    final inProgress = call.state.isActive;
    return Scaffold(
      backgroundColor: AppColors.slate,
      appBar: AppBar(
        title: const Text('Active call', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsetsGeometry.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.teal,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Icon(Icons.person, size: 52, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                call.callerId,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              CallStatusBadge(state: call.state),
              SizedBox(height: 20),
              Text(
                connected
                    ? _formatDuration(session.connectedDuration)
                    : '00:00',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              SizedBox(height: 12),
              Text(
                call.callId,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                ),
              ),
              SizedBox(height: 30),
              StatusRow(current: call.state),

              const Spacer(),
              if (ringing)
                Row(
                  children: [
                    Expanded(
                      child: roundAction(
                        color: AppColors.danger,
                        icon: Icons.call_end,
                        label: 'Reject',
                        onTap: controller.rejectCall,
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: roundAction(
                        color: AppColors.success,
                        icon: Icons.call,
                        label: 'Accept',
                        onTap: controller.acceptCall,
                      ),
                    ),
                  ],
                )
              else if (inProgress &&
                  (connected ||
                      call.state == CallState.accepting ||
                      call.state == CallState.ending))
                roundAction(
                  color: AppColors.danger,
                  icon: Icons.call_end,
                  label: 'End call',
                  onTap: controller.endCall,
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to home'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  Widget roundAction({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
