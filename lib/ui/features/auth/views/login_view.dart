import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../view_models/auth_view_model.dart';

class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = ref.read(authViewModelProvider.notifier);
    try {
      await viewModel.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _useCredentials(String email) {
    _emailController.text = email;
    _passwordController.text = 'password123';
    _handleLogin();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 3),

                        // Custom Geometric Premium Logo Component
                        const _PremiumLogo(),
                        const SizedBox(height: 12.0),
                        
                        Text(
                          'Zero-stress property management & marketplace',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 3),

                        // Email Input Section
                        Row(
                          children: [
                            Text(
                              'Email Address',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            hintText: 'name@example.com',
                            prefixIcon: Icon(CupertinoIcons.mail, size: 20),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20.0),

                        // Password Input Section
                        Row(
                          children: [
                            Text(
                              'Password',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 32.0),

                        // Primary Sign In Button
                        AnimatedTapScale(
                          onTap: viewModel.isLoading ? () {} : _handleLogin,
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: viewModel.isLoading ? null : _handleLogin,
                              child: viewModel.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Sign In'),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28.0),

                        // Demo Accounts Section Redesign
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? theme.colorScheme.primary.withValues(alpha: 0.08)
                                : theme.colorScheme.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark
                                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                                  : theme.colorScheme.primary.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'QUICK DEMO ACCESS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _DemoAccountCard(
                                          roleName: 'Client',
                                          email: 'customer@phoebe.com',
                                          icon: CupertinoIcons.person_solid,
                                          themeColor: const Color(0xFF2F80ED),
                                          onTap: () => _useCredentials('customer@phoebe.com'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _DemoAccountCard(
                                          roleName: 'Service Worker',
                                          email: 'alex.worker@phoebe.com',
                                          icon: CupertinoIcons.hammer_fill,
                                          themeColor: const Color(0xFFF2994A),
                                          onTap: () => _useCredentials('alex.worker@phoebe.com'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _DemoAccountCard(
                                          roleName: 'Operations Admin',
                                          email: 'phoebe.admin@phoebe.com',
                                          icon: CupertinoIcons.shield_fill,
                                          themeColor: const Color(0xFF9B51E0),
                                          onTap: () => _useCredentials('phoebe.admin@phoebe.com'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _DemoAccountCard(
                                          roleName: 'Property Manager',
                                          email: 'manager@phoebe.com',
                                          icon: CupertinoIcons.briefcase_fill,
                                          themeColor: const Color(0xFF27AE60),
                                          onTap: () => _useCredentials('manager@phoebe.com'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28.0),

                        // Sign Up Link Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            AnimatedTapScale(
                              onTap: () => context.push('/register'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                                child: Text(
                                  'Sign Up',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(flex: 4),

                        // Premium Footer Branding
                        Text(
                          'Phoebe Homes • Premium Living',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16.0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumLogo extends StatelessWidget {
  const _PremiumLogo();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(28, 28),
                painter: _LogoPainter(color: color),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Phoebe Homes',
            style: TextStyle(fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final Color color;
  _LogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    
    // Abstract property outline shape
    path.moveTo(size.width * 0.15, size.height * 0.85);
    path.lineTo(size.width * 0.15, size.height * 0.35);
    path.lineTo(size.width * 0.5, size.height * 0.1);
    path.lineTo(size.width * 0.85, size.height * 0.35);
    path.lineTo(size.width * 0.85, size.height * 0.85);
    path.close();

    // Internal separator (representing architecture/marketplace structure)
    path.moveTo(size.width * 0.15, size.height * 0.55);
    path.lineTo(size.width * 0.85, size.height * 0.55);

    // Vertical structural line
    path.moveTo(size.width * 0.5, size.height * 0.55);
    path.lineTo(size.width * 0.5, size.height * 0.85);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DemoAccountCard extends StatelessWidget {
  final String roleName;
  final String email;
  final IconData icon;
  final Color themeColor;
  final VoidCallback onTap;

  const _DemoAccountCard({
    required this.roleName,
    required this.email,
    required this.icon,
    required this.themeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final borderColor = theme.colorScheme.surfaceContainerHighest;
    final onSurface = theme.colorScheme.onSurface;

    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: themeColor,
                size: 15,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    roleName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

