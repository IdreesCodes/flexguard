import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction.dart';
import '../providers/auth_provider.dart';
import '../providers/transactions_provider.dart';
import '../utils/constants.dart';
import '../utils/db_helper.dart';
import '../utils/risk_analyzer.dart';
import 'package:provider/provider.dart';

class AddTransactionSheet extends StatefulWidget {
  final bool? defaultExpense;
  const AddTransactionSheet({super.key, this.defaultExpense});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  TransactionType _type = TransactionType.expense;
  String _category = '';
  String _note = '';
  double _amount = 0;
  bool _guardEnabled = true; // pre-purchase guard toggle

  @override
  void initState() {
    super.initState();
    if (widget.defaultExpense != null) {
      _type = widget.defaultExpense! ? TransactionType.expense : TransactionType.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return AnimatedPadding(
      duration: AppDurations.normal,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(height: 4, width: 48, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))).animate().fadeIn(),
                    const SizedBox(height: 12),
                    SegmentedButton<TransactionType>(
                      segments: const [
                        ButtonSegment(value: TransactionType.expense, label: Text('Expense'), icon: Icon(Icons.remove_circle_outline)),
                        ButtonSegment(value: TransactionType.income, label: Text('Income'), icon: Icon(Icons.add_circle_outline)),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Category'),
                      onChanged: (v) => _category = v.trim(),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a category' : null,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      value: _guardEnabled,
                      onChanged: (v) => setState(() => _guardEnabled = v),
                      title: const Text('Pre-purchase guard (confirm before spending)'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Amount'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => _amount = double.tryParse(v) ?? 0,
                      validator: (v) => ((double.tryParse(v ?? '') ?? 0) <= 0) ? 'Enter amount' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                      onChanged: (v) => _note = v,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          // Heuristic risk analysis for expenses
                          if (_type == TransactionType.expense) {
                            final auth = context.read<AuthProvider>();
                            final signals = await RiskAnalyzer().analyze(userId: auth.currentUser!.id!);
                            if (signals.isNotEmpty) {
                              final proceed = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Heads up'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [for (final s in signals) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('• ${s.label}: ${s.message}'))],
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Proceed')),
                                  ],
                                ),
                              );
                              if (proceed != true) return;
                            }
                          }
                          if (_guardEnabled && _type == TransactionType.expense) {
                            final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirm purchase'),
                                    content: Text('Are you sure you want to spend ₹${_amount.toStringAsFixed(2)} on $_category?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
                                    ],
                                  ),
                                ) ??
                                false;
                            if (!ok) return;
                          }
                          final auth = context.read<AuthProvider>();
                          AppTransaction tx = AppTransaction(
                            userId: auth.currentUser!.id!,
                            type: _type,
                            amount: _amount,
                            category: _category,
                            note: _note,
                            date: DateTime.now().millisecondsSinceEpoch,
                          );
                          try {
                            final txp = context.read<TransactionsProvider>();
                            await txp.add(tx);
                          } catch (_) {
                            // Fallback if provider scope is missing
                            await DatabaseHelper.instance.insertTransaction(tx.toMap());
                          }
                          if (mounted) Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


