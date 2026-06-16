import 'dart:ui';
import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final double opacity;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = 16.0,
    this.blur = 10.0,
    this.color,
    this.opacity = 0.15,
    this.borderOpacity = 0.25,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: (color ?? Colors.white).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            child: InkWell(
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: onTap,
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.white.withValues(alpha: 0.08),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: (color ?? Colors.white).withValues(alpha: borderOpacity),
                    width: 1.2,
                  ),
                ),
                padding: padding,
                child: Center(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
