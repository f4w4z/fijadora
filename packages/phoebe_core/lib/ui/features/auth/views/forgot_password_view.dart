import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/app_animations.dart';

class ForgotPasswordView extends ConsumerStatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  ConsumerState<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends ConsumerState<ForgotPasswordView> {
  final _emailController = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    try {
      await ref.read(authViewModelProvider).forgotPassword(email: email);
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to send reset link: $e', type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reset Password', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.sm),
              AnimatedCrossFade(
                firstChild: Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                secondChild: Text(
                  'Check your email for a password reset link. It may take a few minutes to arrive.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                crossFadeState: _sent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: AppDurations.normal,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              AnimatedCrossFade(
                firstChild: Column(
                  key: const ValueKey('form_child'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleSend(),
                      decoration: const InputDecoration(
                        hintText: 'your@email.com',
                        prefixIcon: Icon(CupertinoIcons.mail, size: 20),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: viewModel.isLoading ? null : _handleSend,
                        child: AnimatedSwitcher(
                          duration: AppDurations.fast,
                          child: viewModel.isLoading
                              ? const SizedBox(
                                  key: ValueKey('loading'),
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : const Text('Send Reset Link', key: ValueKey('text')),
                        ),
                      ),
                    ),
                  ],
                ),
                secondChild: Column(
                  key: const ValueKey('success_child'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Icon(CupertinoIcons.check_mark_circled_solid, size: 72, color: Colors.green),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to Login'),
                      ),
                    ),
                  ],
                ),
                crossFadeState: _sent ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: AppDurations.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
