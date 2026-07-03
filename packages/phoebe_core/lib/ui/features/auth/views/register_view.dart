import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../../domain/models/user_role.dart';
import '../view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  UserRole _selectedRole = UserRole.customer;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    debugPrint('REGISTER: _handleRegister called');
    if (!_formKey.currentState!.validate()) {
      debugPrint('REGISTER: form validation failed');
      return;
    }

    final viewModel = ref.read(authViewModelProvider.notifier);
    debugPrint('REGISTER: calling signUp with email=${_emailController.text.trim()} role=${_selectedRole.key}');
    try {
      await viewModel.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
      );
      debugPrint('REGISTER: signUp completed successfully');
      if (mounted) {
        final email = _emailController.text.trim();
        debugPrint('REGISTER: navigating to verify-email for $email');
        context.go('/verify-email?email=$email');
      } else {
        debugPrint('REGISTER: widget not mounted after signUp');
      }
    } catch (e) {
      debugPrint('REGISTER: signUp threw error: $e');
      if (mounted) {
        context.showSnackBar(
          e.toString().replaceAll('Exception: ', ''),
          type: SnackBarType.error,
        );
      }
    }
  }

  Widget _buildRoleCard(String title, String description, UserRole role, IconData icon, Color activeColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedRole == role;

    final surfaceColor = isDark
        ? (isSelected ? const Color(0xFF161616) : const Color(0xFF0F0F0F))
        : (isSelected ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF));
    
    final borderColor = isSelected
        ? activeColor
        : (isDark ? const Color(0xFF222222) : const Color(0xFFE5E5E5));

    return AnimatedTapScale(
      onTap: () {
        setState(() {
          _selectedRole = role;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: isDark ? 0.15 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF222222) : const Color(0xFFF5F5F5)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 15,
                    color: isSelected ? activeColor : Colors.grey,
                  ),
                ),
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: activeColor,
                    size: 16,
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : theme.colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 9.5,
                height: 1.2,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: AnimatedTapScale(
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(CupertinoIcons.back),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: context.pagePad),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 0),
                  child: Text(
                    'Join Phoebe Homes',
                    style: const TextStyle(fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6.0),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 50),
                  child: Text(
                    'Select your role and build your premium space.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 28.0),

                // Name
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Full Name',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          hintText: 'John Doe',
                          prefixIcon: Icon(CupertinoIcons.person, size: 20),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter name';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // Email
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: AppSpacing.sm),
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
                    ],
                  ),
                ),
                const SizedBox(height: 18.0),

                // Password
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Minimum 6 characters',
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
                    ],
                  ),
                ),
                const SizedBox(height: 28.0),

                // Role Selection Heading & Grid
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 250),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Select Your Role',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: context.gridCols,
                        childAspectRatio: 1.15,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildRoleCard(
                            'Customer',
                            'Request services & shop furniture.',
                            UserRole.customer,
                            CupertinoIcons.person_solid,
                            const Color(0xFF2F80ED),
                          ),
                          _buildRoleCard(
                            'Worker',
                            'Fulfill jobs & manage schedule.',
                            UserRole.worker,
                            CupertinoIcons.hammer_fill,
                            const Color(0xFFF2994A),
                          ),
                          _buildRoleCard(
                            'Admin',
                            'Manage users & view analytics.',
                            UserRole.admin,
                            CupertinoIcons.shield_fill,
                            const Color(0xFF9B51E0),
                          ),
                          _buildRoleCard(
                            'Manager',
                            'Oversee housing units & bookings.',
                            UserRole.manager,
                            CupertinoIcons.briefcase_fill,
                            const Color(0xFF27AE60),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36.0),

                // Register Button
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 300),
                  child: AnimatedTapScale(
                    onTap: viewModel.isLoading ? () {} : _handleRegister,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _handleRegister,
                        child: AnimatedSwitcher(
                          duration: AppDurations.fast,
                          switchInCurve: AppCurves.defaultCurve,
                          switchOutCurve: AppCurves.defaultCurve,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  key: ValueKey('register_loading'),
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Create Account', key: ValueKey('register_text')),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



