import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/db_helper.dart';

class AwardsScreen extends StatelessWidget {
  const AwardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser!.id!;
    return Scaffold(
      appBar: AppBar(title: const Text('Awards')),
      backgroundColor: AppColors.accentBlue,
      body: FutureBuilder<_AwardsMetrics>(
        future: _loadMetrics(userId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final m = snap.data!;
          final awards = _buildAwards(m);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: awards.length,
            itemBuilder: (context, i) => _AwardTile(award: awards[i]),
          );
        },
      ),
    );
  }

  Future<_AwardsMetrics> _loadMetrics(int userId) async {
    final db = await DatabaseHelper.instance.database;
    // Total savings via savings transactions
    final sumRows = await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) as total FROM transactions WHERE user_id = ? AND type = 'savings'",
      [userId],
    );
    final totalSavings = (sumRows.first['total'] as num).toDouble();
    // Goals completed count
    final goals = await DatabaseHelper.instance.getGoals();
    int completed = 0;
    for (final g in goals) {
      final target = (g['target_amount'] as num).toDouble();
      final saved = (g['saved_amount'] as num).toDouble();
      if (target > 0 && saved >= target) completed++;
    }
    return _AwardsMetrics(totalSavings: totalSavings, goalsCompleted: completed);
  }

  List<_Award> _buildAwards(_AwardsMetrics m) {
    return [
      _Award(
        name: 'First Bloom',
        emoji: '🏆',
        description: 'Complete 1 goal',
        progress: _ratio(m.goalsCompleted.toDouble(), 1),
      ),
      _Award(
        name: 'Garden Hero',
        emoji: '🌟',
        description: 'Complete 3 goals',
        progress: _ratio(m.goalsCompleted.toDouble(), 3),
      ),
      _Award(
        name: 'Seed Saver',
        emoji: '🌱',
        description: 'Save ₹1,000',
        progress: _ratio(m.totalSavings, 1000),
      ),
      _Award(
        name: 'Sapling Saver',
        emoji: '🌿',
        description: 'Save ₹5,000',
        progress: _ratio(m.totalSavings, 5000),
      ),
      _Award(
        name: 'Oak Saver',
        emoji: '🌳',
        description: 'Save ₹10,000',
        progress: _ratio(m.totalSavings, 10000),
      ),
      _Award(
        name: 'Steady Hands',
        emoji: '⏳',
        description: 'Keep saving steadily',
        progress: _ratio(m.totalSavings, 15000),
      ),
    ];
  }
}

double _ratio(double current, double target) {
  if (target <= 0) return 0;
  final r = current / target;
  if (r < 0) return 0;
  if (r > 1) return 1;
  return r;
}

class _Award {
  final String name;
  final String emoji;
  final String description;
  final double progress; // 0..1
  const _Award({required this.name, required this.emoji, required this.description, required this.progress});
  bool get completed => progress >= 1.0;
}

class _AwardTile extends StatelessWidget {
  final _Award award;
  const _AwardTile({required this.award});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final completed = award.completed;
    final baseBg = cs.surface;
    final baseText = cs.onSurface;
    return Container(
      decoration: BoxDecoration(
        color: baseBg,
        borderRadius: Radii.md,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 14, offset: const Offset(0, 8))],
        border: Border.all(color: cs.primary.withOpacity(0.15)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Center(
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: award.progress,
                  strokeWidth: 6,
                  color: cs.primary,
                  backgroundColor: AppColors.accentBlue,
                ),
              ),
              Text(award.emoji, style: const TextStyle(fontSize: 28)),
              if (!completed)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Icon(Icons.lock_outline, size: 16, color: baseText.withOpacity(0.5)),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          award.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.w700, color: baseText),
        ),
        const SizedBox(height: 4),
        Text(
          award.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: baseText.withOpacity(0.7)),
        ),
      ]),
    );
  }
}

class _AwardsMetrics {
  final double totalSavings;
  final int goalsCompleted;
  const _AwardsMetrics({required this.totalSavings, required this.goalsCompleted});
}


