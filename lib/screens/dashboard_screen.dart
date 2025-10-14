import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/transactions_provider.dart';
import '../providers/budgets_provider.dart';
import '../providers/payments_provider.dart';
import '../providers/goals_provider.dart';
import '../utils/constants.dart';
// balance_card kept but replaced by _GlassBalanceCard in the dashboard
import '../widgets/weekly_spending_chart.dart';
import '../widgets/transaction_list_item.dart';
import 'transactions_screen.dart';
import 'add_transaction_sheet.dart';
import 'budgets_screen.dart';
import 'goals_screen.dart';
import '../utils/risk_analyzer.dart';
import '../utils/db_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Period _period = Period.today;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final userId = auth.currentUser!.id!;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionsProvider(userId: userId)..refresh()),
        ChangeNotifierProvider(create: (_) => BudgetsProvider()..refresh()),
        ChangeNotifierProvider(create: (_) => GoalsProvider()..refresh()),
        ChangeNotifierProvider(create: (_) => PaymentsProvider(userId: userId)..refresh()),
      ],
      builder: (context, _) {
        final txp = context.watch<TransactionsProvider>();
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          body: SafeArea(
            top: true,
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Column(
                            children: [
                              Text(
                                'Hi ${auth.currentUser?.username ?? ''} 👋',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 26, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSecondary),
                              ),
                              const SizedBox(height: 4),
                              Text('Welcome to FlexGuard', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.subtleText)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      _RiskBanner(userId: userId).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0),
                      const SizedBox(height: 12),
                      _GlassBalanceCard(userId: userId, balance: txp.balance, period: _period).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 12),
                      _SummaryChips(selected: _period, onChanged: (p) => setState(() => _period = p)).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 16),
                      _RecurringBanner().animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 20),
                      _SpendingChartSection(userId: userId, period: _period).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 20),
                      _SectionHeader(title: 'Categories', actionLabel: 'Manage', onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetsScreen()))),
                      _CategoriesGrid().animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 16),
                      _SectionHeader(title: 'Savings Goals', actionLabel: 'See all', onAction: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GoalsScreen()))),
                      _GoalsPreview().animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.06, end: 0),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium),
                          TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const TransactionsScreen())), child: const Text('See all')),
                        ],
                      ),
                      FutureBuilder(
                        future: txp.getRecent(),
                        builder: (context, snapshot) {
                          final items = snapshot.data ?? [];
                          return Column(children: [for (final tx in items) TransactionListItem(tx: tx)]).animate().fadeIn().slideY(begin: 0.06, end: 0);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )),
          floatingActionButton: FloatingActionButton(
            heroTag: 'fab_dashboard',
            onPressed: () => _openAddTransaction(context),
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          ).animate().scale(),
        );
      },
    );
  }

  Future<void> _openAddTransaction(BuildContext context, {bool? isExpense}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<TransactionsProvider>(),
        child: AddTransactionSheet(defaultExpense: isExpense),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        if (actionLabel != null && onAction != null) TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

// (Deprecated) budgets preview replaced by _CategoriesGrid to match new design.

class _CategoriesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BudgetsProvider>();
    if (bp.isLoading) return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
    if (bp.budgets.isEmpty) return const _EmptyCard(text: 'No categories yet');
    final items = bp.budgets.take(6).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.1),
      itemBuilder: (context, i) {
        final b = items[i];
        return _CategoryCard(budgetName: b.name, budgetId: b.id!, spentFuture: bp.spentFor(b.id!));
      },
    );
  }
}

// ======== New Modern Widgets ========

enum Period { today, week, month }

class _GlassBalanceCard extends StatelessWidget {
  final int userId;
  final double balance;
  final Period period;
  const _GlassBalanceCard({required this.userId, required this.balance, required this.period});
  @override
  Widget build(BuildContext context) {
    final range = _periodRange(period);
    return FutureBuilder<Map<String, double>>(
      future: DatabaseHelper.instance.getTotalsForRange(userId: userId, startMillis: range.$1, endMillis: range.$2),
      builder: (context, snap) {
        final income = snap.data?['income'] ?? 0;
        final expense = snap.data?['expense'] ?? 0;
        final cs = Theme.of(context).colorScheme;
        final onPrimary = cs.onPrimary;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: Radii.lg,
            boxShadow: [BoxShadow(color: cs.primary.withOpacity(0.25), blurRadius: 22, offset: const Offset(0, 12))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Current Balance', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: onPrimary.withOpacity(0.9), fontWeight: FontWeight.w600)),
              const Spacer(),
              Icon(Icons.wallet_rounded, color: onPrimary.withOpacity(0.9)),
            ]),
            const SizedBox(height: 8),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: balance),
              duration: AppDurations.slow,
              builder: (context, value, _) => Text('₹${value.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: onPrimary, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 12),
            Row(children: [
              _chipStat(icon: Icons.south_west_rounded, label: 'Income', value: income, color: AppColors.successGreen, textColor: onPrimary),
              const SizedBox(width: 8),
              _chipStat(icon: Icons.north_east_rounded, label: 'Expense', value: expense, color: AppColors.warningRed, textColor: onPrimary),
            ])
          ]),
        );
      },
    );
  }

  (int, int) _periodRange(Period p) {
    final now = DateTime.now();
    switch (p) {
      case Period.today:
        final start = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
        return (start, end);
      case Period.week:
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday % 7));
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day).millisecondsSinceEpoch;
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
        return (start, end);
      case Period.month:
        final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
        final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
        return (start, end);
    }
  }

  Widget _chipStat({required IconData icon, required String label, required double value, required Color color, required Color textColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: Radii.md),
        child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 8), Text('₹${value.toStringAsFixed(0)}', style: TextStyle(color: textColor, fontWeight: FontWeight.w700))]),
      ),
    );
  }
}

class _SummaryChips extends StatelessWidget {
  final Period selected;
  final ValueChanged<Period> onChanged;
  const _SummaryChips({required this.selected, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    Widget chip(Period p, String label) {
      final isSelected = selected == p;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(p),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: Radii.md,
              color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
              boxShadow: [if (isSelected) BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 8))],
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.28)),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      chip(Period.today, 'Today'),
      const SizedBox(width: 8),
      chip(Period.week, 'This Week'),
      const SizedBox(width: 8),
      chip(Period.month, 'This Month'),
    ]);
  }
}

class _SpendingChartSection extends StatelessWidget {
  final int userId;
  final Period period;
  const _SpendingChartSection({required this.userId, required this.period});
  @override
  Widget build(BuildContext context) {
    final txp = context.watch<TransactionsProvider>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('Spending', style: Theme.of(context).textTheme.titleMedium),
        ]),
        const SizedBox(height: 8),
        FutureBuilder<Map<DateTime, double>>(
          future: txp.last7DaysSpending(),
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox(height: 180);
            final data = snap.data!;
            return WeeklySpendingChart(data: data);
          },
        ),
      ]),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String budgetName;
  final int budgetId;
  final Future<double> spentFuture;
  const _CategoryCard({required this.budgetName, required this.budgetId, required this.spentFuture});
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: AppDurations.fast,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: Radii.md,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            const Icon(Icons.category, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(child: Text(widget.budgetName, maxLines: 1, overflow: TextOverflow.ellipsis)),
            FutureBuilder<double>(
              future: widget.spentFuture,
              builder: (context, snapshot) => Text('₹${(snapshot.data ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _NeonFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _NeonFab({required this.onPressed});
  @override
  State<_NeonFab> createState() => _NeonFabState();
}

class _NeonFabState extends State<_NeonFab> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, _) {
        return GestureDetector(
          onTap: widget.onPressed,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: const [Color(0xFF00f2fe), Color(0xFF4facfe), Color(0xFF8E2DE2), Color(0xFF00f2fe)], stops: const [0.0, 0.33, 0.66, 1.0], transform: GradientRotation(_ac.value * 6.28318)),
              boxShadow: [BoxShadow(color: const Color(0xFF8E2DE2).withOpacity(0.4), blurRadius: 24, spreadRadius: 2)],
            ),
            child: const Center(
              child: Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }
}

class _GoalsPreview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gp = context.watch<GoalsProvider>();
    if (gp.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()));
    }
    final items = gp.goals.take(3).toList();
    if (items.isEmpty) return const _EmptyCard(text: 'No goals yet');
    return Row(
      children: [
        for (final g in items)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
              child: Column(children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: g.progress),
                    duration: AppDurations.slow,
                    builder: (context, value, _) => CircularProgressIndicator(value: value, color: AppColors.primaryBlue, backgroundColor: AppColors.accentBlue),
                  ),
                ),
                const SizedBox(height: 8),
                Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('₹${g.savedAmount.toStringAsFixed(0)} / ₹${g.targetAmount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.subtleText)),
              ]),
            ),
          ),
      ],
    );
  }
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

class _RiskBanner extends StatelessWidget {
  final int userId;
  const _RiskBanner({required this.userId});
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: RiskAnalyzer().analyze(userId: userId),
      builder: (context, snapshot) {
        final List<String> tips = [];
        if (snapshot.hasData) {
          final signals = snapshot.data as List<RiskSignal>;
          for (final s in signals) {
            tips.add('${s.label}: ${s.message}');
          }
        }
        // Ensure multiple tips are always shown by adding helpful defaults
        final fallback = <String>[
          'Set a daily spend limit and track against it',
          'Review subscriptions for unused services',
          'Try a 24-hour pause before non-essential buys',
          'Move spare cash to a goal mid-week',
        ];
        for (final f in fallback) {
          if (tips.length >= 3) break;
          tips.add(f);
        }
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: const Offset(0, 4))]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.info_outline, color: AppColors.warningRed),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Heads up', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
              const SizedBox(height: 6),
              for (final t in tips) Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $t', style: const TextStyle(color: AppColors.subtleText))),
            ])),
          ]),
        );
      },
    );
  }
}

// _ActivityCard removed as the weekly chart is shown inline

class _RecurringBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PaymentsProvider>();
    if (pp.isLoading || pp.items.isEmpty) return const SizedBox.shrink();
    final recurring = pp.items.where((p) => (p.recurring ?? '').isNotEmpty).toList();
    if (recurring.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.autorenew, color: AppColors.primaryBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('You have ${recurring.length} recurring charges', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
            const SizedBox(height: 6),
            Text('Next due: ${recurring.first.title} • ₹${recurring.first.amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.subtleText)),
          ]),
        ),
        const Icon(Icons.chevron_right, color: AppColors.subtleText)
      ]),
    );
  }
}

/*
class _KpiRow extends StatelessWidget {
  final int userId;
  const _KpiRow({required this.userId});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startToday = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endToday = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final startMonth = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final endMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59).millisecondsSinceEpoch;
    return FutureBuilder<Map<String, double>>(
      future: DatabaseHelper.instance.getTotalsForRange(userId: userId, startMillis: startToday, endMillis: endToday),
      builder: (context, todaySnap) {
        return FutureBuilder<Map<String, double>>(
          future: DatabaseHelper.instance.getTotalsForRange(userId: userId, startMillis: startMonth, endMillis: endMonth),
          builder: (context, monthSnap) {
            final todayIncome = todaySnap.data?['income'] ?? 0;
            final todayExpense = todaySnap.data?['expense'] ?? 0;
            final monthIncome = monthSnap.data?['income'] ?? 0;
            final monthExpense = monthSnap.data?['expense'] ?? 0;
            return Row(children: [
              Expanded(child: _KpiTile(title: 'Today', income: todayIncome, expense: todayExpense)),
              const SizedBox(width: 12),
              Expanded(child: _KpiTile(title: 'Month', income: monthIncome, expense: monthExpense)),
            ]);
          },
        );
      },
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String title;
  final double income;
  final double expense;
  const _KpiTile({required this.title, required this.income, required this.expense});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: AppColors.subtleText)),
        const SizedBox(height: 6),
        Row(children: [
          const Icon(Icons.south_west_rounded, color: AppColors.successGreen, size: 18),
          const SizedBox(width: 6),
          Text('₹${income.toStringAsFixed(0)}'),
          const SizedBox(width: 12),
          const Icon(Icons.north_east_rounded, color: AppColors.warningRed, size: 18),
          const SizedBox(width: 6),
          Text('₹${expense.toStringAsFixed(0)}'),
        ])
      ]),
    );
  }
}

class _CardsShowcase extends StatelessWidget {
  const _CardsShowcase();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 170,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: const [
          _MiniCard(color1: Color(0xFFFFE5B4), color2: Color(0xFFFFC58F), textColor: Color(0xFF7C3A00)),
          SizedBox(width: 12),
          _MiniCard(color1: Color(0xFFCFFAFE), color2: Color(0xFFA5F3FC), textColor: Color(0xFF164E63)),
          SizedBox(width: 12),
          _MiniCard(color1: Color(0xFFE9D5FF), color2: Color(0xFFD8B4FE), textColor: Color(0xFF4C1D95)),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final Color color1;
  final Color color2;
  final Color textColor;
  const _MiniCard({required this.color1, required this.color2, required this.textColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        borderRadius: Radii.lg,
        gradient: LinearGradient(colors: [color1, color2]),
        boxShadow: [BoxShadow(color: color2.withOpacity(0.3), blurRadius: 18, offset: const Offset(0, 10))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.contactless, color: Colors.white),
        const Spacer(),
        Text('VISA', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text('9038 4061 **** ****', style: TextStyle(color: Colors.white.withOpacity(0.9), fontFeatures: const [FontFeature.tabularFigures()])),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('Imran Khan', style: TextStyle(color: Colors.white.withOpacity(0.9)))),
          Text('02/02', style: TextStyle(color: Colors.white.withOpacity(0.9)))
        ])
      ]),
    );
  }
}
// Legacy quick actions removed

// Removed decorative stacked cards to streamline the header focus

class _TotalsChipRow extends StatelessWidget {
  final int userId;
  const _TotalsChipRow({required this.userId});
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).millisecondsSinceEpoch;
    final end = DateTime(now.year, now.month + 1, 0).millisecondsSinceEpoch;
    return FutureBuilder<Map<String, double>>(
      future: DatabaseHelper.instance.getTotalsForRange(userId: userId, startMillis: start, endMillis: end),
      builder: (context, snap) {
        final income = snap.data?['income'] ?? 0;
        final expense = snap.data?['expense'] ?? 0;
        return Row(children: [
          Expanded(child: _TotalChip(color: AppColors.successGreen, label: 'Income', value: income)),
          const SizedBox(width: 8),
          Expanded(child: _TotalChip(color: AppColors.warningRed, label: 'Expense', value: expense)),
        ]);
      },
    );
  }
}

class _TotalChip extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  const _TotalChip({required this.color, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
      child: Row(children: [
        Icon(Icons.arrow_upward, color: color, size: 18),
        const SizedBox(width: 8),
        Text(label),
        const Spacer(),
        Text('₹${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)),
      ]),
    ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0);
  }
}
*/


