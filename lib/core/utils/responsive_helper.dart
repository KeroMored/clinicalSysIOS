import 'package:flutter/material.dart';

/// 📱 Responsive Helper - نظام شامل لدعم جميع أحجام الشاشات
///
/// يدعم:
/// - 📱 Mobile (< 600px)
/// - 📱 Tablet (600px - 900px)
/// - 💻 Desktop (> 900px)
/// - 🖥️ Large Desktop (> 1200px)

class ResponsiveHelper {
  /// الحصول على نوع الجهاز
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      return DeviceType.mobile;
    } else if (width < 900) {
      return DeviceType.tablet;
    } else if (width < 1200) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// هل الجهاز موبايل؟
  static bool isMobile(BuildContext context) {
    return getDeviceType(context) == DeviceType.mobile;
  }

  /// هل الجهاز تابلت؟
  static bool isTablet(BuildContext context) {
    return getDeviceType(context) == DeviceType.tablet;
  }

  /// هل الجهاز ديسكتوب؟
  static bool isDesktop(BuildContext context) {
    final type = getDeviceType(context);
    return type == DeviceType.desktop || type == DeviceType.largeDesktop;
  }

  /// الحصول على عرض الشاشة
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// الحصول على طول الشاشة
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// الحصول على النسبة المئوية من عرض الشاشة
  static double wp(BuildContext context, double percentage) {
    return screenWidth(context) * (percentage / 100);
  }

  /// الحصول على النسبة المئوية من طول الشاشة
  static double hp(BuildContext context, double percentage) {
    return screenHeight(context) * (percentage / 100);
  }

  /// حجم الخط المتجاوب
  static double sp(BuildContext context, double size) {
    final width = screenWidth(context);

    if (width < 600) {
      return size;
    } else if (width < 900) {
      return size * 1.2;
    } else if (width < 1200) {
      return size * 1.4;
    } else {
      return size * 1.6;
    }
  }

  /// Padding متجاوب
  static double padding(
    BuildContext context, {
    double mobile = 16,
    double? tablet,
    double? desktop,
  }) {
    final type = getDeviceType(context);

    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.5;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile * 2;
    }
  }

  /// عدد الأعمدة المتجاوب (للـ GridView)
  static int gridColumns(
    BuildContext context, {
    int mobile = 2,
    int? tablet,
    int? desktop,
  }) {
    final type = getDeviceType(context);

    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile + 1;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile + 2;
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile + 3;
    }
  }

  /// حجم الأيقونة المتجاوب
  static double iconSize(
    BuildContext context, {
    double mobile = 24,
    double? tablet,
    double? desktop,
  }) {
    final type = getDeviceType(context);

    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile * 1.3;
      case DeviceType.desktop:
      case DeviceType.largeDesktop:
        return desktop ?? tablet ?? mobile * 1.5;
    }
  }

  /// عرض البطاقة المتجاوب
  static double cardWidth(BuildContext context) {
    final width = screenWidth(context);

    if (width < 600) {
      return width * 0.9; // 90% من العرض
    } else if (width < 900) {
      return width * 0.7; // 70% من العرض
    } else if (width < 1200) {
      return width * 0.5; // 50% من العرض
    } else {
      return 500; // عرض ثابت للشاشات الكبيرة
    }
  }

  /// الحصول على القيمة المناسبة حسب نوع الجهاز
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final type = getDeviceType(context);

    switch (type) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// التحقق من الاتجاه
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// الحصول على Safe Area
  static EdgeInsets safeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// الحصول على ارتفاع Keyboard
  static double keyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }
}

/// أنواع الأجهزة
enum DeviceType {
  mobile, // < 600px
  tablet, // 600px - 900px
  desktop, // 900px - 1200px
  largeDesktop, // > 1200px
}

/// Widget للـ Responsive Layout Builder
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceType(context);
        return builder(context, deviceType);
      },
    );
  }
}

/// Widget للـ Responsive Layout مع widgets مختلفة
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? largeDesktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.largeDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deviceType = ResponsiveHelper.getDeviceType(context);

        switch (deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
          case DeviceType.largeDesktop:
            return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Widget للـ Responsive Grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveHelper.gridColumns(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: spacing,
      mainAxisSpacing: runSpacing,
      children: children,
    );
  }
}

/// Extension على BuildContext
extension ResponsiveExtension on BuildContext {
  /// سريع للوصول لـ ResponsiveHelper
  ResponsiveHelper get responsive => ResponsiveHelper();

  /// نوع الجهاز
  DeviceType get deviceType => ResponsiveHelper.getDeviceType(this);

  /// هل موبايل؟
  bool get isMobile => ResponsiveHelper.isMobile(this);

  /// هل تابلت؟
  bool get isTablet => ResponsiveHelper.isTablet(this);

  /// هل ديسكتوب؟
  bool get isDesktop => ResponsiveHelper.isDesktop(this);

  /// عرض الشاشة
  double get screenWidth => ResponsiveHelper.screenWidth(this);

  /// طول الشاشة
  double get screenHeight => ResponsiveHelper.screenHeight(this);

  /// Width Percentage
  double wp(double percentage) => ResponsiveHelper.wp(this, percentage);

  /// Height Percentage
  double hp(double percentage) => ResponsiveHelper.hp(this, percentage);

  /// Scaled Pixel (Font Size)
  double sp(double size) => ResponsiveHelper.sp(this, size);

  /// Responsive Padding
  double padding({double mobile = 16, double? tablet, double? desktop}) =>
      ResponsiveHelper.padding(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

  /// Responsive Icon Size
  double iconSize({double mobile = 24, double? tablet, double? desktop}) =>
      ResponsiveHelper.iconSize(
        this,
        mobile: mobile,
        tablet: tablet,
        desktop: desktop,
      );

  /// Responsive Value
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) => ResponsiveHelper.value<T>(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );
}
