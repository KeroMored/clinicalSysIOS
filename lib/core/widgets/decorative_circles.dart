import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Widget to display decorative circles in the background
/// Used throughout the app for consistent modern design
class DecorativeCircles extends StatelessWidget {
  final bool showTopRight;
  final bool showBottomLeft;
  final Color? topRightColor;
  final Color? bottomLeftColor;

  const DecorativeCircles({
    super.key,
    this.showTopRight = true,
    this.showBottomLeft = true,
    this.topRightColor,
    this.bottomLeftColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom Left Circle
        if (showBottomLeft)
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (bottomLeftColor ?? AppTheme.primaryColor).withValues(alpha: 0.15),
                    (bottomLeftColor ?? AppTheme.primaryColor).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
        
        // Top Right Circle
        if (showTopRight)
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (topRightColor ?? AppTheme.secondaryColor).withValues(alpha: 0.12),
                    (topRightColor ?? AppTheme.secondaryColor).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Decorative circle positioned in specific corner
class DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  
  const DecorativeCircle({
    super.key,
    required this.size,
    required this.color,
    this.opacity = 0.1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}
