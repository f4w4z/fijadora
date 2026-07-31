import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/auth_view_model.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _controller = PageController();
  int _page = 0;

  @override
  void initState() {
    super.initState();
    ref.listen(authViewModelProvider, (_, auth) {
      if (!auth.showOnboarding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/');
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _done() {
    ref.read(authViewModelProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  const Spacer(),
                  if (_page < 2)
                    GestureDetector(
                      onTap: _done,
                      child: Text('Skip', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildPage(
                    theme: theme,
                    icon: CupertinoIcons.house_fill,
                    gradientColors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6)],
                    title: 'Your Home, One Tap Away',
                    description: 'From plumbing to electrical work, find the right professional for any job around your home. No calls, no back-and-forth.',
                  ),
                  _buildPage(
                    theme: theme,
                    icon: CupertinoIcons.car,
                    gradientColors: [const Color(0xFF2E7D32), const Color(0xFF66BB6A)],
                    title: 'Track in Real Time',
                    description: 'Watch your technician\'s progress live — know exactly when they\'ll arrive and follow every step of the job.',
                  ),
                  _buildPage(
                    theme: theme,
                    icon: CupertinoIcons.checkmark_seal_fill,
                    gradientColors: [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
                    title: 'Everything Covered',
                    description: 'All work comes with a satisfaction guarantee. Rate your experience and help us keep quality high.',
                  ),
                ],
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _page < 2
                          ? () => _controller.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                            )
                          : _done,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _page < 2 ? 'Next' : 'Get Started',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required ThemeData theme,
    required IconData icon,
    required List<Color> gradientColors,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(color: gradientColors[0].withValues(alpha: 0.3), blurRadius: 40, offset: const Offset(0, 12)),
              ],
            ),
            child: Icon(icon, size: 60, color: Colors.white),
          ),
          const Spacer(flex: 1),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.3, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
