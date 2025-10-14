import 'dart:convert';
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/db_helper.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'analyzing_screen.dart';
import 'root_nav.dart';

class OnboardingSetupScreen extends StatefulWidget {
  const OnboardingSetupScreen({super.key});

  @override
  State<OnboardingSetupScreen> createState() => _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends State<OnboardingSetupScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  double _monthlyIncome = 0;
  final Map<String, double> _budgets = {};
  String _goalName = '';
  double _goalTarget = 0;

  final _incomeController = TextEditingController();
  final Map<String, TextEditingController> _budgetControllers = {};
  final _goalNameController = TextEditingController();
  final _goalTargetController = TextEditingController();

  final List<String> _defaultCategories = const ['Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Health'];
  final Set<String> _selectedCategories = {};

  @override
  void dispose() {
    _incomeController.dispose();
    for (final c in _budgetControllers.values) c.dispose();
    _goalNameController.dispose();
    _goalTargetController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final data = {
      'monthlyIncome': _monthlyIncome,
      'budgets': _budgets,
      'goal': {'name': _goalName, 'target': _goalTarget}
    };
    await DatabaseHelper.instance.setPreference('onboarding_data', jsonEncode(data));
    if (!mounted) return;
    // Attempt auto-signup using preset username/password if available
    final preset = await DatabaseHelper.instance.getPreference('signup_preset');
    if (preset != null && preset.isNotEmpty) {
      try {
        final m = jsonDecode(preset) as Map<String, dynamic>;
        final u = (m['u'] as String?)?.trim() ?? '';
        final p = (m['p'] as String?) ?? '';
        if (u.isNotEmpty && p.isNotEmpty) {
          await context.read<AuthProvider>().signup(u, p);
        }
      } catch (_) {}
      await DatabaseHelper.instance.setPreference('signup_preset', '');
    }
    final proceed = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AnalyzingScreen())) ?? true;
    if (proceed && mounted) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const RootNav()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your plan')),
      backgroundColor: AppColors.accentBlue,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(children: [
            Text('Step ${_index + 1} of 3', style: const TextStyle(color: AppColors.subtleText)),
            const Spacer(),
            TextButton(onPressed: _finish, child: const Text('Skip')),
          ]),
        ),
        Expanded(
          child: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              _IncomeStep(controller: _incomeController, onChanged: (v) => _monthlyIncome = v),
              _BudgetsStep(
                categories: _defaultCategories,
                selected: _selectedCategories,
                controllerFor: (k) => _budgetControllers.putIfAbsent(k, () => TextEditingController()),
                onChanged: (map) => _budgets
                  ..clear()
                  ..addAll(map),
              ),
              _GoalStep(nameController: _goalNameController, targetController: _goalTargetController, onChanged: (n, t) {
                _goalName = n;
                _goalTarget = t;
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  if (_index > 0) {
                    _controller.previousPage(duration: AppDurations.normal, curve: Curves.easeOutCubic);
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(_index == 0 ? 'Back' : 'Previous'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (_index < 2) {
                    _controller.nextPage(duration: AppDurations.normal, curve: Curves.easeOutCubic);
                  } else {
                    await _finish();
                  }
                },
                child: Text(_index < 2 ? 'Next' : 'Finish'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _IncomeStep extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<double> onChanged;
  const _IncomeStep({required this.controller, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 12),
        const Text('Your monthly income', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(hintText: 'e.g., 50000'),
          onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
        ),
        const SizedBox(height: 16),
        const Text('We’ll tailor your budgets around this.', style: TextStyle(color: AppColors.subtleText)),
        const Spacer(),
        const Icon(Icons.auto_graph, size: 100, color: AppColors.primaryBlue),
        const SizedBox(height: 12),
      ]),
    );
  }
}

class _BudgetsStep extends StatefulWidget {
  final List<String> categories;
  final Set<String> selected;
  final TextEditingController Function(String key) controllerFor;
  final ValueChanged<Map<String, double>> onChanged;
  const _BudgetsStep({required this.categories, required this.selected, required this.controllerFor, required this.onChanged});
  @override
  State<_BudgetsStep> createState() => _BudgetsStepState();
}

class _BudgetsStepState extends State<_BudgetsStep> {
  Map<String, double> _values = {};
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Pick your budget categories', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in widget.categories)
            FilterChip(
              label: Text(c),
              selected: widget.selected.contains(c),
              onSelected: (sel) {
                setState(() {
                  if (sel) {
                    widget.selected.add(c);
                  } else {
                    widget.selected.remove(c);
                    _values.remove(c);
                  }
                  widget.onChanged(_values);
                });
              },
            ),
        ]),
        const SizedBox(height: 12),
        for (final c in widget.selected.toList())
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: Radii.md),
            child: Row(children: [
              Expanded(child: Text('$c budget')),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: widget.controllerFor(c),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'Amount'),
                  onChanged: (v) {
                    final d = double.tryParse(v) ?? 0;
                    setState(() {
                      _values[c] = d;
                    });
                    widget.onChanged(_values);
                  },
                ),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        const Text('You can edit these anytime in Budgets.', style: TextStyle(color: AppColors.subtleText)),
      ]),
    );
  }
}

class _GoalStep extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController targetController;
  final void Function(String, double) onChanged;
  const _GoalStep({required this.nameController, required this.targetController, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Your first savings goal', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText)),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'e.g., New phone'),
          onChanged: (v) => onChanged(v, double.tryParse(targetController.text) ?? 0),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: targetController,
          decoration: const InputDecoration(hintText: 'Target amount'),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) => onChanged(nameController.text, double.tryParse(v) ?? 0),
        ),
        const Spacer(),
        const Icon(Icons.local_florist, size: 100, color: AppColors.successGreen),
        const SizedBox(height: 12),
      ]),
    );
  }
}


