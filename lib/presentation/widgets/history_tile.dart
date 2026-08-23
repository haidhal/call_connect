import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/model/call_data_model.dart';
import 'package:call_connect/model/call_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.call});
  final CallDataModel call;
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d · HH:mm');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.slate.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: stateClr(call.state),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${call.callerId} → ${call.calleeId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate,
                  ),
                ),
                Text(
                  fmt.format(call.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.slateMid,
                  ),
                ),
              ],
            ),
          ),
          Text(
            call.state.label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              color: stateClr(call.state),
            ),
          ),
        ],
      ),
    );
  }

  Color stateClr(CallState state) {
    if (state == CallState.connected || state == CallState.ended) {
      return AppColors.success;
    }
    if (state == CallState.ringing || state == CallState.accepting) {
      return AppColors.warning;
    }
    return AppColors.danger;
  }
}
