import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../utils/tap_feedback.dart';

/// Glassmorphism surface — backdrop blur + tint + hairline highlight.
///
/// Mirrors the `<Glass>` component from the design bundle (theme.jsx).
/// Uses BackdropFilter so the ambient blobs painted behind show through.
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool strong;
  final bool gradient;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;

  const Glass({
    super.key,
    required this.child,
    this.radius = 22,
    this.padding,
    this.strong = false,
    this.gradient = false,
    this.borderColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final bg = gradient
        ? null
        : (strong ? AppColors.glassStrong : AppColors.glass);
    final bgGradient = gradient ? AppColors.brandGradientSoft : null;

    final card = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: bg,
                gradient: bgGradient,
                borderRadius: borderRadius,
                border: Border.all(
                  color: borderColor ?? AppColors.glassBorder,
                  width: 0.5,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: child,
              ),
            ),
            // Top sheen — subtle light leak along the top edge.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: radius,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(radius),
                      topRight: Radius.circular(radius),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.glassHi.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}

/// Gradient pill — the brand call-to-action.
class GradButton extends StatelessWidget {
  final Widget child;
  final bool full;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GradButton({
    super.key,
    required this.child,
    this.full = false,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    this.radius = 9999,
  });

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentB.withValues(alpha: 0.53),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        child: child,
      ),
    );

    final sized = full
        ? SizedBox(width: double.infinity, child: button)
        : button;

    if (onTap == null) return sized;
    return GestureDetector(onTap: onTap, child: sized);
  }
}

/// Small pill chip with optional accent color.
class GlassChip extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const GlassChip({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: c != null
            ? c.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: c != null
              ? c.withValues(alpha: 0.27)
              : AppColors.glassBorder,
          width: 0.5,
        ),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          color: c ?? AppColors.textSoft,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        child: child,
      ),
    );
  }
}

/// Small square icon badge using the soft brand gradient.
class GlassIconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? color;
  final double radius;

  const GlassIconBadge({
    super.key,
    required this.icon,
    this.size = 36,
    this.iconSize = 16,
    this.color,
    this.radius = 11,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accentB;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradientSoft,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: c.withValues(alpha: 0.27),
          width: 0.5,
        ),
      ),
      child: Icon(icon, size: iconSize, color: c),
    );
  }
}

/// Ambient blurred color blobs — used as the phone-frame background.
/// Render *behind* the screen content to achieve the "floating glass" look.
class AmbientBlobs extends StatelessWidget {
  final double opacity;
  const AmbientBlobs({super.key, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _blob(
            top: -80,
            right: -60,
            size: 320,
            color: AppColors.accentA,
            alpha: 0.28 * opacity,
          ),
          _blob(
            top: 100,
            left: -100,
            size: 280,
            color: AppColors.accentB,
            alpha: 0.22 * opacity,
          ),
          _blob(
            bottom: -60,
            right: -40,
            size: 300,
            color: AppColors.accentC,
            alpha: 0.20 * opacity,
          ),
        ],
      ),
    );
  }

  Widget _blob({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
    required Color color,
    required double alpha,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: alpha),
          ),
        ),
      ),
    );
  }
}

/// Gradient text — applies the brand gradient as a ShaderMask.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          (gradient ?? AppColors.brandGradient).createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}

/// Round header icon button, glass-styled.
class HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback? onTap;

  const HeaderIconBtn({
    super.key,
    required this.icon,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Glass(
            radius: 12,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Icon(icon, size: 17, color: AppColors.text),
            ),
          ),
          if (badge != null)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text(
                  badge!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (onTap == null) return btn;
    return GestureDetector(
      onTap: () {
        TapFeedback.light();
        onTap!();
      },
      child: btn,
    );
  }
}
