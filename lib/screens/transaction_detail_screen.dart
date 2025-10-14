import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../models/emotion.dart';
import '../utils/db_helper.dart';
import 'package:provider/provider.dart';

class TransactionDetailScreen extends StatelessWidget {
  final AppTransaction tx;
  const TransactionDetailScreen({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final color = switch (tx.type) {
      TransactionType.income => AppColors.successGreen,
      TransactionType.expense => AppColors.warningRed,
      TransactionType.savings => AppColors.primaryBlue,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Hero(
            tag: 'tx-${tx.id}-amount',
            child: Material(color: Colors.transparent, child: Text('₹${tx.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: color, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(height: 16),
          Text('Type: ${tx.type.name}'),
          if (tx.category != null) Text('Category: ${tx.category}'),
          if (tx.note != null && tx.note!.isNotEmpty) Text('Note: ${tx.note}'),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () => _logEmotion(context),
            child: const Text('Log Emotion'),
          )
        ]),
      ),
    );
  }
}

Future<void> _logEmotion(BuildContext context) async {
  final emotions = ['Bored', 'Stressed', 'Excited', 'Sad', 'Happy'];
  String selected = emotions.first;
  int intensity = 3;
  final note = TextEditingController();
  final auth = context.read<AuthProvider>();
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('How did you feel?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButton<String>(value: selected, isExpanded: true, onChanged: (v) => selected = v ?? selected, items: [for (final e in emotions) DropdownMenuItem(value: e, child: Text(e))]),
          const SizedBox(height: 8),
          Row(children: [const Text('Intensity'), Expanded(child: Slider(value: intensity.toDouble(), min: 1, max: 5, divisions: 4, label: intensity.toString(), onChanged: (v) => intensity = v.toInt()))]),
          TextField(controller: note, decoration: const InputDecoration(labelText: 'Note (optional)')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final log = EmotionLog(
              userId: auth.currentUser!.id!,
              transactionId: null,
              emotion: selected,
              intensity: intensity,
              note: note.text.trim().isEmpty ? null : note.text.trim(),
              date: DateTime.now().millisecondsSinceEpoch,
            );
            final db = await DatabaseHelper.instance.database;
            await db.insert('emotions', log.toMap());
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Save'),
        )
      ],
    ),
  );
}


