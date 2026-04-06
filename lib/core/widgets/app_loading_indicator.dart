import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AppLoadingIndicator extends StatelessWidget {
  final Color? color;
  final Animation<Color?>? valueColor;
  final double strokeWidth;
  final double? value;
  final Color? backgroundColor;
  final String? semanticsLabel;
  final String? semanticsValue;
  final double? minHeight;
  final double? size;

  const AppLoadingIndicator({
    super.key,
    this.color,
    this.valueColor,
    this.strokeWidth = 4.0,
    this.value,
    this.backgroundColor,
    this.semanticsLabel,
    this.semanticsValue,
    this.minHeight,
    this.size,
  });

  Color _resolvedColor() {
    if (color != null) {
      return color!;
    }

    if (valueColor is AlwaysStoppedAnimation<Color?>) {
      final fixed = (valueColor as AlwaysStoppedAnimation<Color?>).value;
      if (fixed != null) {
        return fixed;
      }
    }

    return const Color(0xFF0B8293);
  }

  double _resolvedSize() {
    if (size != null) {
      return size!.clamp(18.0, 64.0);
    }

    if (minHeight != null) {
      return minHeight! <= 2 ? 20 : 24;
    }

    if (strokeWidth <= 2.5) {
      return 24;
    }

    return 32;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      value: semanticsValue,
      child: SpinKitPulsingGrid(color: _resolvedColor(), size: _resolvedSize()),
    );
  }
}
