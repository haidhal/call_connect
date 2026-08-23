import 'package:call_connect/controller/call_controller.dart';
import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/presentation/widgets/history_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CallHistoryScreen extends ConsumerStatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  ConsumerState<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends ConsumerState<CallHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(callControllerProvider).history;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.teal,
        leading: Icon(Icons.arrow_back, color: Colors.white),
        title: const Text(
          'Call history',
          style: TextStyle(color: Colors.white),
        ),
        surfaceTintColor: Colors.black,
      ),
      body: history.isEmpty
          ? const Center(child: Text('No calls stored in SQLite yet'))
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: history.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return HistoryTile(call: history[index]);
                    },
                  ),
                ),
                SizedBox(height: 30),
              ],
            ),
    );
  }
}
