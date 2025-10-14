import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/emotions_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/coach_provider.dart';
import '../utils/constants.dart';
import '../models/emotion.dart';
import '../models/upcoming_payment.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().currentUser!.id!;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => EmotionsProvider(userId: userId)..refresh()),
        ChangeNotifierProvider(create: (_) => PaymentsProvider(userId: userId)..refresh()),
        ChangeNotifierProvider(create: (_) => CoachProvider(userId: userId)..analyze()),
      ],
      child: const _InsightsBody(),
    );
  }
}

class _InsightsBody extends StatelessWidget {
  const _InsightsBody();
  @override
  Widget build(BuildContext context) {
    final emotions = context.watch<EmotionsProvider>();
    final payments = context.watch<PaymentsProvider>();
    final coach = context.watch<CoachProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      backgroundColor: AppColors.accentBlue,
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            emotions.refresh(),
            payments.refresh(),
            coach.analyze(),
          ]);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _HighlightsCard(),
            const SizedBox(height: 12),
            _QuickActionsRow(),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Recent Emotions'),
            _EmotionsPreview(),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Upcoming Payments'),
            _PaymentsPreview(),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Coach Tips'),
            _CoachPreview(),
          ],
        ),
      ),
    );
  }
}

class _HighlightsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final payments = context.watch<PaymentsProvider>();
    final coach = context.watch<CoachProvider>();
    final today = DateTime.now();
    final isLate = today.hour >= 22 || today.hour <= 6;
    final riskWindow = isLate ? 'Late night now' : (today.weekday == DateTime.saturday || today.weekday == DateTime.sunday ? 'Weekend' : '');
    final nextDue = payments.items.isEmpty
        ? 'No upcoming bills'
        : '₹${payments.items.first.amount.toStringAsFixed(0)} due on ${DateTime.fromMillisecondsSinceEpoch(payments.items.first.dueDate).toLocal().toString().split(' ').first}';
    final tipsCount = coach.tips.length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      child: Row(
        children: [
          Expanded(child: _HighlightTile(label: 'Next bill', value: nextDue)),
          const SizedBox(width: 12),
          Expanded(child: _HighlightTile(label: 'Tips', value: '$tipsCount available')),
          if (riskWindow.isNotEmpty) ...[
            const SizedBox(width: 12),
            Expanded(child: _HighlightTile(label: 'Risk window', value: riskWindow)),
          ]
        ],
      ),
    );
  }
}

class _HighlightTile extends StatelessWidget {
  final String label;
  final String value;
  const _HighlightTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentBlue,
        borderRadius: Radii.md,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: AppColors.subtleText)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkText)),
      ]),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
          onPressed: () => _openAddEmotionDialog(context),
          icon: const Icon(Icons.mood),
          label: const Text('Add Emotion'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _openAddPaymentDialog(context),
          icon: const Icon(Icons.event_note),
          label: const Text('Add Payment'),
        ),
      ),
    ]);
  }
}

class _EmotionsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<EmotionsProvider>();
    if (p.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    if (p.logs.isEmpty) return const _EmptyCard(text: 'No emotion logs yet');
    final preview = p.logs.take(3).toList();
    return Column(children: [
      for (final e in preview)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
          child: Row(
            children: [
              CircleAvatar(child: Text(e.emotion[0])),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e.emotion, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Intensity ${e.intensity}${e.trigger == null ? '' : ' • Trigger: ${e.trigger}'}${e.note == null ? '' : ' • ${e.note}'}',
                      style: const TextStyle(color: AppColors.subtleText)),
                ]),
              ),
            ],
          ),
        ),
    ]);
  }
}

class _PaymentsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<PaymentsProvider>();
    if (p.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    if (p.items.isEmpty) return const _EmptyCard(text: 'No upcoming payments');
    final preview = p.items.take(3).toList();
    return Column(children: [
      for (final it in preview)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
          child: Row(
            children: [
              const Icon(Icons.receipt_long, color: AppColors.primaryBlue),
              const SizedBox(width: 12),
              Expanded(child: Text(it.title)),
              Text('₹${it.amount.toStringAsFixed(0)}'),
            ],
          ),
        ),
    ]);
  }
}

class _CoachPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<CoachProvider>();
    if (p.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
    if (p.tips.isEmpty) return const _EmptyCard(text: 'No insights yet');
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tip in p.tips)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
            child: Text(tip),
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
      );
}

class _EmptyCard extends StatelessWidget {
  final String text;
  const _EmptyCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
        child: Text(text),
      );
}

Future<void> _openAddEmotionDialog(BuildContext context) async {
  final emotions = ['Bored', 'Stressed', 'Excited', 'Sad', 'Happy'];
  String selected = emotions.first;
  int intensity = 3;
  final note = TextEditingController();
  String? trigger;
  final auth = context.read<AuthProvider>();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Log Emotion'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(value: selected, isExpanded: true, onChanged: (v) => selected = v ?? selected, items: [for (final e in emotions) DropdownMenuItem(value: e, child: Text(e))]),
          const SizedBox(height: 8),
          Row(children: [const Text('Intensity'), Expanded(child: Slider(value: intensity.toDouble(), min: 1, max: 5, divisions: 4, label: intensity.toString(), onChanged: (v) => intensity = v.toInt()))]),
          const SizedBox(height: 8),
          DropdownButton<String>(
            value: trigger,
            hint: const Text('Trigger (optional)'),
            isExpanded: true,
            onChanged: (v) => trigger = v,
            items: const [
              DropdownMenuItem(value: 'Social media', child: Text('Social media')),
              DropdownMenuItem(value: 'Late night', child: Text('Late night')),
              DropdownMenuItem(value: 'With friends', child: Text('With friends')),
              DropdownMenuItem(value: 'Work stress', child: Text('Work stress')),
              DropdownMenuItem(value: 'Boredom', child: Text('Boredom')),
            ],
          ),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final p = context.read<EmotionsProvider>();
            await p.add(EmotionLog(userId: auth.currentUser!.id!, transactionId: null, emotion: selected, intensity: intensity, note: note.text.trim().isEmpty ? null : note.text.trim(), trigger: trigger, date: DateTime.now().millisecondsSinceEpoch));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        )
      ],
    ),
  );
}

Future<void> _openAddPaymentDialog(BuildContext context) async {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  DateTime due = DateTime.now().add(const Duration(days: 7));
  final auth = context.read<AuthProvider>();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Add Upcoming Payment'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount')),
          const SizedBox(height: 8),
          Row(children: [
            const Text('Due date'),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(context: context, initialDate: due, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (picked != null) due = picked;
              },
              child: Text(due.toLocal().toString().split(' ').first),
            )
          ])
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final p = context.read<PaymentsProvider>();
            await p.add(UpcomingPayment(userId: auth.currentUser!.id!, title: titleController.text.trim(), amount: double.tryParse(amountController.text) ?? 0, dueDate: DateTime(due.year, due.month, due.day).millisecondsSinceEpoch, category: null, recurring: null, createdAt: DateTime.now().millisecondsSinceEpoch));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

