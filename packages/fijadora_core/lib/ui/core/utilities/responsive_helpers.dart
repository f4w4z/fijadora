import 'package:flutter/material.dart';

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      width(context) < mobile;
  static bool isTablet(BuildContext context) =>
      width(context) >= mobile && width(context) < tablet;
  static bool isDesktop(BuildContext context) =>
      width(context) >= desktop;

  static double width(BuildContext context) =>
      MediaQuery.of(context).size.width;
  static double height(BuildContext context) =>
      MediaQuery.of(context).size.height;
  static double viewInsetsBottom(BuildContext context) =>
      MediaQuery.of(context).viewInsets.bottom;

  static double safeTop(BuildContext context) =>
      MediaQuery.of(context).padding.top;
  static double safeBottom(BuildContext context) =>
      MediaQuery.of(context).padding.bottom;

  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 48;

  static double page(BuildContext context) =>
      AppBreakpoints.value(context, mobile: 24, tablet: 32, desktop: 48);

  static EdgeInsets all(double value) => EdgeInsets.all(value);
  static EdgeInsets symmetric({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h, vertical: v);
  static EdgeInsets only({
    double l = 0,
    double t = 0,
    double r = 0,
    double b = 0,
  }) =>
      EdgeInsets.only(left: l, top: t, right: r, bottom: b);
}

class AppSizing {
  AppSizing._();

  static double widthFraction(BuildContext context, double fraction) =>
      MediaQuery.of(context).size.width * fraction;

  static double heightFraction(BuildContext context, double fraction) =>
      MediaQuery.of(context).size.height * fraction;

  static double iconSize(BuildContext context) =>
      AppBreakpoints.value(context, mobile: 24, tablet: 28, desktop: 32);
}

class AppGrid {
  AppGrid._();

  static int columns(BuildContext context) =>
      AppBreakpoints.value(context, mobile: 2, tablet: 3, desktop: 4);

  static double spacing(BuildContext context) =>
      AppBreakpoints.value(context, mobile: 12, tablet: 16, desktop: 20);

  static double aspectRatio(BuildContext context) =>
      AppBreakpoints.value(context, mobile: 0.68, tablet: 0.75, desktop: 0.8);
}

extension ResponsiveContext on BuildContext {
  double get sw => MediaQuery.of(this).size.width;
  double get sh => MediaQuery.of(this).size.height;
  double get sTop => MediaQuery.of(this).padding.top;
  double get sBottom => MediaQuery.of(this).padding.bottom;
  bool get isMobile => AppBreakpoints.isMobile(this);
  bool get isTablet => AppBreakpoints.isTablet(this);
  bool get isDesktop => AppBreakpoints.isDesktop(this);
  double get pagePad => AppSpacing.page(this);
  int get gridCols => AppGrid.columns(this);
}

extension ResponsiveNum on num {
  double w(BuildContext context) => context.sw * (this / 100);
  double h(BuildContext context) => context.sh * (this / 100);
}
