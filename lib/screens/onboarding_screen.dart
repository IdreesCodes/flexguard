import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/db_helper.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnbPage> _pages = const [
    _OnbPage(
      icon: Icons.savings,
      title: 'Smarter budgeting',
      text: 'Create budgets by category, log expenses in seconds, and stay in control.',
    ),
    _OnbPage(
      icon: Icons.auto_graph,
      title: 'Clarity at a glance',
      text: 'Animated charts reveal your weekly spending and patterns instantly.',
    ),
    _OnbPage(
      icon: Icons.local_florist,
      title: 'Grow your goals',
      text: 'Set savings targets and watch your Growth Garden flourish.',
    ),
  ];

  Future<void> _complete() async {
    await DatabaseHelper.instance.setPreference('onboarding_seen', '1');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeSlideRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.accentBlue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: AppDurations.fast,
                  margin: const EdgeInsets.all(4),
                  height: 8,
                  width: _index == i ? 24 : 8,
                  decoration: BoxDecoration(
                    color: _index == i ? AppColors.primaryBlue : AppColors.primaryBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _complete,
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
                      onPressed: () {
                        if (_index < _pages.length - 1) {
                          _controller.nextPage(duration: AppDurations.normal, curve: Curves.easeOutCubic);
                        } else {
                          _complete();
                        }
                      },
                      child: Text(_index < _pages.length - 1 ? 'Next' : 'Get Started'),
                    ).animate().fadeIn().slideX(begin: 0.1, end: 0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnbPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _OnbPage({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(icon, size: 120, color: AppColors.primaryBlue).animate().fadeIn(duration: AppDurations.normal).scale(),
          const SizedBox(height: 24),
          Text(title, style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.darkText, fontWeight: FontWeight.bold)).animate().fadeIn().slideY(),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.subtleText)).animate().fadeIn(duration: AppDurations.slow),
        ],
      ),
    );
  }
}


