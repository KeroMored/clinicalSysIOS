import 'package:flutter/material.dart';

/// Smooth page transitions to eliminate lag during navigation
class SmoothNavigation {
  /// Navigate to a new screen with smooth fade transition
  static Future<T?> push<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Smooth fade transition
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Navigate and replace current screen with smooth transition
  static Future<T?> pushReplacement<T, TO>(BuildContext context, Widget page) {
    return Navigator.pushReplacement<T, TO>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Navigate with slide transition (from right to left)
  static Future<T?> pushSlide<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  /// Navigate with scale transition
  static Future<T?> pushScale<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(
      context,
      PageRouteBuilder<T>(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOutCubic;

          var scaleTween = Tween(
            begin: 0.9,
            end: 1.0,
          ).chain(CurveTween(curve: curve));
          var fadeTween = Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: curve));

          return ScaleTransition(
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
