import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? color;
  final double opacity;
  final double? width;
  final double? height;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.blur = 12.0,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.gradient,
    this.borderColor,
    this.color,
    this.opacity = 0.5,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = color ?? (isDark ? const Color(0xFF1E293B) : Colors.white);
    final finalBorderColor = borderColor ?? (isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2));

    return Container(
      margin: margin,
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: gradient == null ? defaultColor.withOpacity(opacity) : null,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: finalBorderColor, width: 1),
              gradient: gradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
