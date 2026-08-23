import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/model/call_data_model.dart';
import 'package:call_connect/presentation/screens/active_call_screen.dart';
import 'package:flutter/material.dart';

class ActiveCard extends StatelessWidget {
  const ActiveCard({super.key, required this.call});
  final CallDataModel call;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActiveCallScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.teal.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.phone_in_talk, color: AppColors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Active call',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate,
                      ),
                    ),
                    Text(
                      '${call.callerId} · ${call.state.label}',
                      style: const TextStyle(
                        color: AppColors.slateMid,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 18, color: AppColors.teal),
            ],
          ),
        ),
      ),
    );
  }
}
