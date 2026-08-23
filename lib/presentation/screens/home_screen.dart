import 'package:call_connect/controller/call_controller.dart';
import 'package:call_connect/core/app_colors.dart';
import 'package:call_connect/core/app_constants.dart';
import 'package:call_connect/presentation/screens/active_call_screen.dart';
import 'package:call_connect/presentation/screens/call_history_screen.dart';
import 'package:call_connect/presentation/widgets/active_card.dart';
import 'package:call_connect/presentation/widgets/history_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  void startIncomingCall() async {
    final controller = ref.read(callControllerProvider.notifier);
    await controller.incomingCall();

    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ActiveCallScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(callControllerProvider);
    final active = controller.activeCall;
    final history = controller.history;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.slate,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.call, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: const Text(
                'Call Connect',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate,
                  letterSpacing: -0.6,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'Hai👋,   ${AppUsers.localUser}',
                style: const TextStyle(
                  color: AppColors.slateMid,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 20),
              if (active != null) ...[
                ActiveCard(call: active),
                const SizedBox(height: 16),
              ],
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: active == null ? 1.0 : 0.4,
                child: GestureDetector(
                  onTap: () {
                    if (active == null) {
                      startIncomingCall();
                    }
                  },
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: AppColors.teal,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ring_volume, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          'Incoming call',
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CallHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              SizedBox(height: 20),
              if (history.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No calls yet. Start an incoming call to begin.',
                      style: TextStyle(
                        color: AppColors.slateMid,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemBuilder: (context, index) {
                      final call = history[index];

                      return HistoryTile(call: call);
                    },
                    separatorBuilder: (context, index) => SizedBox(height: 10),
                    itemCount: history.length > 5 ? 5 : history.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
