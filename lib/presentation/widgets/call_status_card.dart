import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/model/call_state.dart';
import 'package:flutter/material.dart';

class CallStatusBadge extends StatelessWidget {
  const CallStatusBadge({super.key, required this.state});

  final CallState state;

  // Returns the color based on the current call state.
  Color getColor(CallState state) {
    switch (state) {
      case CallState.ringing:
        return AppColors.warning;

      case CallState.accepting:
        return AppColors.accent;

      case CallState.connected:
        return AppColors.success;

      case CallState.ending:
        return AppColors.slateMid;

      case CallState.ended:
        return AppColors.slate;

      case CallState.rejected:
      case CallState.cancelled:
      case CallState.failed:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the color for the current state.
    final color = getColor(state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
