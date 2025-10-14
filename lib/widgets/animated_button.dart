import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/constants.dart';

class AnimatedPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const AnimatedPrimaryButton({super.key, required this.label, this.onPressed, this.loading = false, this.icon});

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: Radii.md,
        boxShadow: [
          BoxShadow(color: AppColors.primaryBlue.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          AnimatedSwitcher(
            duration: AppDurations.fast,
            child: widget.loading
                ? SizedBox(
                    key: const ValueKey('spinner'),
                    height: 18,
                    width: 18,
                    child: const CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : Text(widget.label, key: const ValueKey('label'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onPressed,
      child: child
          .animate(target: _pressed ? 1 : 0)
          .scale(begin: const Offset(1, 1), end: const Offset(0.98, 0.98), duration: AppDurations.fast)
          .then()
          .animate()
          .fadeIn(duration: AppDurations.normal)
          .slideY(begin: 0.1, end: 0, duration: AppDurations.normal),
    );
  }
}


