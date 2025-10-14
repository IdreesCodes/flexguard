import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';
import '../utils/routes.dart';
import '../utils/db_helper.dart';
import 'onboarding_setup_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  // Captured in setup flow; kept for future validation if needed
  String _username = '';
  String _password = '';
  bool _obscure = true;
  bool _fakeLoading = false;

  @override
  Widget build(BuildContext context) {
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
                Center(child: Image.asset('assets/images/FlexG.png', height: 64, errorBuilder: (_, __, ___) => const Icon(Icons.local_florist, size: 48, color: AppColors.primaryBlue))),
                const SizedBox(height: 12),
                Text('Create your account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.darkText, fontWeight: FontWeight.bold))
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
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: _fakeLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          // Stash creds and open setup; signup will be finalized after setup
                          await DatabaseHelper.instance.setPreference('signup_preset', _username.isEmpty || _password.isEmpty ? '' : '{"u":"$_username","p":"$_password"}');
                          Navigator.of(context).push(fadeSlideRoute(builder: (_) => const OnboardingSetupScreen()));
                        },
                  child: AnimatedSwitcher(
                    duration: AppDurations.fast,
                    child: _fakeLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Text('Continue'),
                  ),
                ).animate().scale(duration: AppDurations.fast),
              ],
            ),
          ),
        ).animate().fadeIn(duration: AppDurations.normal).slideY(begin: 0.05, end: 0),
      ),
    );
  }
}


