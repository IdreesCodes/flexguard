import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/goal.dart';
import '../providers/auth_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/constants.dart';
import 'awards_screen.dart';
Future<Widget?> _loadAwardsModule() async {
  // Module already local; return widget directly. Async kept for symmetry if later loading is needed.
  return const AwardsScreen();
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GoalsProvider()..refresh(),
      builder: (context, _) {
        final gp = context.watch<GoalsProvider>();
        final auth = context.watch<AuthProvider>();
        return Scaffold(
          appBar: AppBar(
            title: const Text('Growth Garden'),
            actions: [
              IconButton(
                icon: const Icon(Icons.emoji_events),
                onPressed: () async {
                  final module = await _loadAwardsModule();
                  if (module != null && context.mounted) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => module));
                  }
                },
                tooltip: 'Awards',
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gp.goals.length,
            itemBuilder: (context, i) => _GoalCard(goal: gp.goals[i], onAddFunds: (amount) => gp.addFunds(userId: auth.currentUser!.id!, goal: gp.goals[i], amount: amount)),
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_goals',
            onPressed: () => _openAddGoal(context),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _openAddGoal(BuildContext context) async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: targetController, decoration: const InputDecoration(labelText: 'Target Amount'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final gp = context.read<GoalsProvider>();
              final now = DateTime.now().millisecondsSinceEpoch;
              await gp.add(Goal(name: nameController.text.trim(), targetAmount: double.tryParse(targetController.text) ?? 0, savedAmount: 0, createdAt: now, updatedAt: now));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final Future<void> Function(double amount) onAddFunds;
  const _GoalCard({required this.goal, required this.onAddFunds});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: Radii.md),
      child: Row(
        children: [
          Stack(alignment: Alignment.center, children: [
            SizedBox(
              width: 64,
              height: 64,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: progress),
                duration: AppDurations.slow,
                builder: (context, value, _) => CircularProgressIndicator(value: value, color: AppColors.primaryBlue, backgroundColor: AppColors.accentBlue),
              ),
            ),
            Text(_emojiForGoalName(goal.name), style: const TextStyle(fontSize: 30)).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('₹${goal.savedAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}'),
            ]),
          ),
          TextButton(
            onPressed: () => _openAddFunds(context),
            child: const Text('Add Funds'),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Future<void> _openAddFunds(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Add to ${goal.name}'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              await onAddFunds(amount);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

String _emojiForGoalName(String name) {
  final n = name.toLowerCase();
  if (n.contains('car')) return '🚗';
  if (n.contains('bike') || n.contains('bicycle') || n.contains('cycle')) return '🏍️';
  if (n.contains('mobile') || n.contains('phone') || n.contains('iphone')) return '📱';
  if (n.contains('laptop') || n.contains('computer') || n.contains('mac')) return '💻';
  if (n.contains('house') || n.contains('home') || n.contains('rent')) return '🏠';
  if (n.contains('travel') || n.contains('trip') || n.contains('vacation')) return '✈️';
  if (n.contains('wedding') || n.contains('marriage') || n.contains('ring')) return '💍';
  if (n.contains('education') || n.contains('college') || n.contains('tuition') || n.contains('course')) return '🎓';
  if (n.contains('emergency') || n.contains('medical') || n.contains('health')) return '🩺';
  if (n.contains('gift') || n.contains('present')) return '🎁';
  if (n.contains('furniture') || n.contains('sofa') || n.contains('bed')) return '🛋️';
  if (n.contains('gaming') || n.contains('console') || n.contains('ps') || n.contains('xbox')) return '🎮';
  if (n.contains('baby') || n.contains('kid')) return '🍼';
  if (n.contains('phone')) return '📱';
  return '🌱';
}


