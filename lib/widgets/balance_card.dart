import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  const BalanceCard({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3730A3), Color(0xFF635BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: Radii.lg,
        boxShadow: [
          BoxShadow(color: const Color(0xFF3730A3).withOpacity(0.25), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Current Balance', style: theme.textTheme.labelLarge?.copyWith(color: Colors.white70)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: Radii.md),
                child: const Row(children: [Icon(Icons.visibility, color: Colors.white, size: 16), SizedBox(width: 6), Text('Show', style: TextStyle(color: Colors.white))]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: balance),
            duration: AppDurations.slow,
            builder: (context, value, _) => Text(
              '₹${value.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
         
          
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0, duration: AppDurations.normal);
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: Radii.md),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white))]),
      ),
    );
  }
}


