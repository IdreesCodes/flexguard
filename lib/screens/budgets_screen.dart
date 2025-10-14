import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/budget.dart';
import '../providers/budgets_provider.dart';
import '../utils/constants.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BudgetsProvider()..refresh(),
      builder: (context, _) {
        final bp = context.watch<BudgetsProvider>();
        return Scaffold(
          appBar: AppBar(title: const Text('Budgets')),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bp.budgets.length,
            itemBuilder: (context, i) {
              final b = bp.budgets[i];
              return _BudgetCard(budget: b).animate().fadeIn().slideY(begin: 0.1, end: 0);
            },
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_budgets',
            onPressed: () => _openAddBudget(context),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _openAddBudget(BuildContext context) async {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'General');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Budget'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 8),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category (used to auto-link transactions)')),
            const SizedBox(height: 8),
            TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () async {
              final bp = context.read<BudgetsProvider>();
              final budget = Budget(name: nameController.text.trim(), category: categoryController.text.trim(), amount: double.tryParse(amountController.text) ?? 0, icon: null, createdAt: DateTime.now().millisecondsSinceEpoch);
              await bp.add(budget);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  const _BudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final bp = context.read<BudgetsProvider>();
    return FutureBuilder<double>(
      future: bp.spentFor(budget.id!),
      builder: (context, snapshot) {
        final spent = snapshot.data ?? 0;
        final progress = (spent / budget.amount).clamp(0.0, 1.0).toDouble();
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: Radii.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              children: [
                CircleAvatar(backgroundColor: AppColors.primaryBlue.withOpacity(0.1), child: const Icon(Icons.category, color: AppColors.primaryBlue)),
                const SizedBox(width: 12),
                Expanded(child: Text(budget.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('₹${spent.toStringAsFixed(0)} / ₹${budget.amount.toStringAsFixed(0)}'),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: progress),
              duration: AppDurations.slow,
              builder: (context, value, _) => LinearProgressIndicator(value: value, color: AppColors.primaryBlue, backgroundColor: AppColors.accentBlue),
            ),
          ]),
        );
      },
    );
  }
}


