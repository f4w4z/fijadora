import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

// ─── Standardised animation tokens ─────────────────────────────────────────────
/// Centralised durations so every screen feels cohesive.
abstract final class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration page = Duration(milliseconds: 400);
  static const Duration stagger = Duration(milliseconds: 50);
  static const Duration entrance = Duration(milliseconds: 600);
}

/// Centralised easing curves for a consistent motion language.
abstract final class AppCurves {
  static const Curve defaultCurve = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeInOutCubic;
  static const Curve page = Curves.easeOutQuart;
  static const Curve spring = Curves.elasticOut;
  static const Curve decelerate = Curves.decelerate;
}

// ─── Reusable fade + slide entrance ────────────────────────────────────────────
/// Animates a child from transparent + offset to fully visible.
/// Perfect for staggered list entrances and screen reveals.
class FadeSlideTransition extends StatefulWidget {
  const FadeSlideTransition({
    super.key,
    required this.child,
    this.offset = const Offset(0, 24),
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Duration delay;
  final Curve curve;

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: widget.curve);
    _position = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: _position.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ─── Staggered list item wrapper ───────────────────────────────────────────────
/// Wraps a list item with a delay-based fade + slide entrance.
/// Use `index` to calculate the stagger delay automatically.
class StaggeredListItem extends StatelessWidget {
  const StaggeredListItem({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = Duration.zero,
    this.staggerDelay = const Duration(milliseconds: 50),
    this.maxIndex = 10,
  });

  final int index;
  final Widget child;
  final Duration baseDelay;
  final Duration staggerDelay;
  final int maxIndex;

  @override
  Widget build(BuildContext context) {
    // Cap the stagger so items beyond maxIndex animate instantly
    final effectiveIndex = index.clamp(0, maxIndex);
    return FadeSlideTransition(
      delay: baseDelay + (staggerDelay * effectiveIndex),
      offset: const Offset(0, 16),
      duration: AppDurations.slow,
      child: child,
    );
  }
}

// ─── Animated state switcher ───────────────────────────────────────────────────
/// Semantic wrapper around AnimatedSwitcher with consistent defaults.
class AnimatedStateSwitcher extends StatelessWidget {
  const AnimatedStateSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppCurves.defaultCurve,
      switchOutCurve: AppCurves.defaultCurve,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: child,
    );
  }
}

// ─── Animated appearance (for empty/error states) ──────────────────────────────
/// Plays a fade + gentle scale-in when the widget first mounts.
class AnimatedAppearance extends StatefulWidget {
  const AnimatedAppearance({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.beginScale = 0.92,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double beginScale;

  @override
  State<AnimatedAppearance> createState() => _AnimatedAppearanceState();
}

class _AnimatedAppearanceState extends State<AnimatedAppearance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curved =
        CurvedAnimation(parent: _controller, curve: AppCurves.defaultCurve);
    _opacity = curved;
    _scale = Tween<double>(begin: widget.beginScale, end: 1.0).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ─── Custom page route with iOS-style slide + fade ─────────────────────────────
/// Custom transition page route for Android, web, and other non-iOS platforms.
class CustomAppPageRoute<T> extends PageRouteBuilder<T> {
  CustomAppPageRoute({
    required WidgetBuilder builder,
    super.settings,
    super.fullscreenDialog = false,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: AppDurations.page,
          reverseTransitionDuration: AppDurations.slow,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: AppCurves.page,
              reverseCurve: Curves.easeInCubic,
            );

            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: AppCurves.page,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0)
                    .animate(curvedAnimation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset.zero,
                    end: const Offset(-0.3, 0.0),
                  ).animate(secondaryCurved),
                  child: child,
                ),
              ),
            );
          },
        );
}

// ignore: non_constant_identifier_names
Route<T> AppPageRoute<T>({
  required WidgetBuilder builder,
  RouteSettings? settings,
  bool fullscreenDialog = false,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    return CupertinoPageRoute<T>(
      builder: builder,
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
  return CustomAppPageRoute<T>(
    builder: builder,
    settings: settings,
    fullscreenDialog: fullscreenDialog,
  );
}

/// Fade-only page route for auth screens and modal-style transitions.
class AppFadeRoute<T> extends PageRouteBuilder<T> {
  AppFadeRoute({
    required WidgetBuilder builder,
    super.settings,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: AppDurations.slow,
          reverseTransitionDuration: AppDurations.normal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: AppCurves.defaultCurve,
              ),
              child: child,
            );
          },
        );
}

// ─── State-preserving cross-fade indexed stack ─────────────────────────────────
/// Keeps all tabs alive in bottom navigation and cross-fades them smoothly.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.index != oldWidget.index) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
