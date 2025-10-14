import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/challenge.dart';
import '../providers/auth_provider.dart';
import '../providers/challenges_provider.dart';
import '../utils/constants.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser!.id!;
    return ChangeNotifierProvider(
      create: (_) => ChallengesProvider(userId: userId)..refresh(),
      builder: (context, _) {
        final provider = context.watch<ChallengesProvider>();
        return Scaffold(
          appBar: AppBar(title: const Text('Challenges')),
          backgroundColor: AppColors.accentBlue,
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.items.isEmpty
                  ? const _EmptyChallenges()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.items.length,
                      itemBuilder: (context, i) => _ChallengeCard(provider.items[i]),
                    ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_challenges',
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _createChallenge(context),
          ),
        );
      },
    );
  }

  Future<void> _createChallenge(BuildContext context) async {
    final name = TextEditingController();
    final amount = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target Amount')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final p = context.read<ChallengesProvider>();
              final now = DateTime.now().millisecondsSinceEpoch;
              final nm = name.text.trim();
              final tgt = double.tryParse(amount.text) ?? 0;
              if (nm.isEmpty || tgt <= 0) return;
              await p.add(Challenge(name: nm, targetAmount: tgt, savedAmount: 0, deadline: null, createdAt: now));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge c;
  const _ChallengeCard(this.c);

  @override
  Widget build(BuildContext context) {
    // Access provider when contributing; no local variable needed here.
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('₹${c.savedAmount.toStringAsFixed(0)} / ₹${c.targetAmount.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: c.progress, color: AppColors.primaryBlue, backgroundColor: AppColors.accentBlue),
            ]),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () => _contribute(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _contribute(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Contribute to ${c.name}'),
        content: TextField(controller: controller, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount <= 0) return;
              await context.read<ChallengesProvider>().contribute(c, amount);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _EmptyChallenges extends StatelessWidget {
  const _EmptyChallenges();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.emoji_events_outlined, size: 48, color: AppColors.subtleText),
            SizedBox(height: 8),
            Text('No challenges yet', style: TextStyle(color: AppColors.subtleText)),
          ],
        ),
      ),
    );
  }
}


