import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/model/call_state.dart';
import 'package:flutter/material.dart';

class StatusRow extends StatelessWidget {
  const StatusRow({super.key, required this.current});

  final CallState? current;

  @override
  Widget build(BuildContext context) {
    final states = [
      CallState.ringing,
      CallState.accepting,
      CallState.connected,
      CallState.ended,
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final state in states)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: current == state
                  ? AppColors.teal.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: current == state
                    ? AppColors.teal
                    : AppColors.slate.withValues(alpha: 0.15),
                width: current == state ? 1.5 : 1,
              ),
            ),
            child: Text(
              state.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: current == state
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: current == state
                    ? AppColors.tealDark
                    : AppColors.slateMid,
              ),
            ),
          ),
      ],
    );
  }
}
