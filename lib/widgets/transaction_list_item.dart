import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';

class TransactionListItem extends StatelessWidget {
  final AppTransaction tx;
  final VoidCallback? onTap;
  const TransactionListItem({super.key, required this.tx, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = switch (tx.type) {
      TransactionType.income => AppColors.successGreen,
      TransactionType.expense => AppColors.warningRed,
      TransactionType.savings => AppColors.primaryBlue,
    };
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(Icons.monetization_on, color: color)),
      title: Text(tx.category ?? (tx.type.name[0].toUpperCase() + tx.type.name.substring(1))),
      subtitle: Text(tx.note ?? ''),
      trailing: Hero(
        tag: 'tx-amount-${tx.id ?? 'n'}-${tx.date}',
        child: Material(
          color: Colors.transparent,
          child: Text(
            (tx.type == TransactionType.income ? '+' : '-') + '₹${tx.amount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0);
  }
}


