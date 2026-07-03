import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';

class VerifyEmailView extends ConsumerStatefulWidget {
  const VerifyEmailView({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends ConsumerState<VerifyEmailView> {
  @override
  void initState() {
    super.initState();
    _checkVerified();
  }

  void _checkVerified() {
    final viewModel = ref.read(authViewModelProvider);
    if (viewModel.user?.emailConfirmedAt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(authViewModelProvider);

    if (viewModel.user?.emailConfirmedAt != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.check_mark_circled_solid, size: 72, color: Colors.green),
              const SizedBox(height: AppSpacing.lg),
              const Text('Email verified!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () {
              viewModel.signOut();
              context.go('/login');
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CupertinoIcons.mail, size: 72, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.xxl),
              Text('Verify your email', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'We sent a verification email to ${widget.email}.\nClick the link in the email to activate your account.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: viewModel.isLoading
                      ? null
                      : () => ref.read(authViewModelProvider).resendVerification(),
                  child: viewModel.isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Resend Email'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    viewModel.signOut();
                    context.go('/login');
                  },
                  child: const Text('Back to Login'),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
