import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import 'root_nav.dart';
import 'onboarding_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  final bool forceSignup;
  const AuthScreen({super.key, this.forceSignup = false});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  String _username = '';
  String _password = '';
  bool _obscure = true;
  bool _fakeLoading = false;

  @override
  Widget build(BuildContext context) {
    if (widget.forceSignup && _isLogin) {
      _isLogin = false;
    }
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.accentBlue,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: Radii.lg, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 24)]),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      // App logo
                      Image.asset('assets/images/FlexG.png', height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.savings, size: 48, color: AppColors.primaryBlue)),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                Text(_isLogin ? 'Welcome back' : 'Create account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.darkText, fontWeight: FontWeight.bold))
                    .animate()
                    .fadeIn()
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  onChanged: (v) => _username = v.trim(),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a username' : null,
                ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Password', suffixIcon: IconButton(onPressed: () => setState(() => _obscure = !_obscure), icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off))),
                  obscureText: _obscure,
                  onChanged: (v) => _password = v,
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.1, end: 0),
                if (auth.error != null) ...[
                  const SizedBox(height: 8),
                  Text(auth.error!, style: const TextStyle(color: AppColors.warningRed)),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: (auth.isLoading || _fakeLoading)
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          // If user is in sign up mode and not forced yet, collect setup first
                          if (!_isLogin && !widget.forceSignup) {
                            if (!mounted) return;
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OnboardingSetupScreen()));
                            return;
                          }
                          setState(() => _fakeLoading = true);
                          await Future.delayed(const Duration(seconds: 2));
                          final ok = _isLogin ? await auth.login(_username, _password) : await auth.signup(_username, _password);
                          if (ok && mounted) {
                            Navigator.of(context).pushAndRemoveUntil(fadeSlideRoute(builder: (_) => const RootNav()), (route) => false);
                          } else {
                            if (mounted) setState(() => _fakeLoading = false);
                          }
                        },
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: (auth.isLoading || _fakeLoading)
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : Text(_isLogin ? 'Login' : 'Create Account'),
                  ),
                ).animate().scale(duration: AppDurations.fast),
                TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? "Don't have an account? Sign up" : 'Have an account? Log in'),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.05, end: 0),
      ),
    );
  }
}


