import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../utils/tap_feedback.dart';
import 'glass.dart';

/// Compatibility shim. The original CRED-neumorphic decorations have been
/// replaced with glassmorphism surfaces that match the new design bundle.
/// Existing screens still call `NeumorphicDecoration.raised(...)` etc. — these
/// now return a glass-tinted BoxDecoration.
class NeumorphicDecoration {
  static BoxDecoration raised({
    double radius = 22,
    Color? color,
    double offset = 6,
    double blur = 14,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 0.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration pressed({
    double radius = 22,
    Color? color,
    double offset = 4,
    double blur = 8,
  }) {
    return BoxDecoration(
      color: color ?? AppColors.glassStrong,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 0.5),
    );
  }

  static BoxDecoration flat({double radius = 22, Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.glass,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder, width: 0.5),
    );
  }

  /// Brand-gradient tinted card — used for emphasis (scoring, hero cards).
  static BoxDecoration raisedGold({
    double radius = 22,
    double offset = 6,
    double blur = 14,
  }) {
    return BoxDecoration(
      gradient: AppColors.brandGradientSoft,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: AppColors.accentB.withValues(alpha: 0.30),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentB.withValues(alpha: 0.20),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -8,
        ),
      ],
    );
  }
}

/// Glass-backed card (was the CRED neumorphic card).
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double radius;
  final bool gold;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = EdgeInsets.zero,
    this.radius = 22,
    this.gold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Glass(
        radius: radius,
        gradient: gold,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Pressable button — now a gradient pill when `gold` is set, otherwise a
/// glass surface with a press-down feedback.
class NeumorphicButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool gold;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.child,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
    this.radius = 18,
    this.gold = false,
    this.color,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
      onTapCancel: disabled ? null : () => setState(() => _pressed = false),
      onTap: disabled
          ? null
          : () {
              widget.gold ? TapFeedback.medium() : TapFeedback.light();
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: widget.padding,
          decoration: widget.gold
              ? BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentB.withValues(alpha: 0.53),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                      spreadRadius: -8,
                    ),
                  ],
                )
              : BoxDecoration(
                  color: widget.color ?? AppColors.glass,
                  borderRadius: BorderRadius.circular(widget.radius),
                  border: Border.all(
                    color: AppColors.glassBorder,
                    width: 0.5,
                  ),
                ),
          child: Opacity(
            opacity: disabled ? 0.5 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Rounded icon badge — now the gradient-soft glass square from the design.
class NeumorphicIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const NeumorphicIconBadge({
    super.key,
    required this.icon,
    this.color = AppColors.accentB,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GlassIconBadge(
      icon: icon,
      size: size,
      iconSize: size * 0.42,
      color: color,
      radius: size * 0.28,
    );
  }
}
