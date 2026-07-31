import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app_config.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../view_models/auth_view_model.dart';

enum _SignupStep { welcome, name, email, password, confirm, otp }

class RegisterView extends ConsumerStatefulWidget {
  const RegisterView({super.key});

  @override
  ConsumerState<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends ConsumerState<RegisterView> with SingleTickerProviderStateMixin {
  _SignupStep _currentStep = _SignupStep.welcome;
  late final AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  int _passwordStrength = 0;

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero, end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  void _goToStep(_SignupStep step) {
    final forward = _SignupStep.values.indexOf(step) > _SignupStep.values.indexOf(_currentStep);
    final begin = forward ? const Offset(0.3, 0.0) : const Offset(-0.3, 0.0);
    _slideAnimation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward(from: 0.0);
    setState(() => _currentStep = step);
    _autoFocus(step);
  }

  void _autoFocus(_SignupStep step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (step) {
        case _SignupStep.name: _nameFocus.requestFocus();
        case _SignupStep.email: _emailFocus.requestFocus();
        case _SignupStep.password: _passwordFocus.requestFocus();
        case _SignupStep.confirm: _confirmFocus.requestFocus();
        default: break;
      }
    });
  }

  void _nextStep() {
    switch (_currentStep) {
      case _SignupStep.welcome: _goToStep(_SignupStep.name);
      case _SignupStep.name:
        if (_nameController.text.trim().isEmpty) return;
        _goToStep(_SignupStep.email);
      case _SignupStep.email:
        if (!_isValidEmail(_emailController.text.trim())) return;
        _goToStep(_SignupStep.password);
      case _SignupStep.password:
        if (_passwordStrength < 3) return;
        _goToStep(_SignupStep.confirm);
      case _SignupStep.confirm:
        if (_confirmPasswordController.text != _passwordController.text) return;
        _handleRegister();
      default: break;
    }
  }

  void _prevStep() {
    final steps = _SignupStep.values;
    final idx = steps.indexOf(_currentStep);
    if (idx > 0) _goToStep(steps[idx - 1]);
  }

  void _updatePasswordStrength(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(value)) score++;
    if (RegExp(r'[a-z]').hasMatch(value)) score++;
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) score++;
    setState(() => _passwordStrength = score);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  int get _stepIndex => _SignupStep.values.indexOf(_currentStep);
  int get _totalSteps => _SignupStep.values.length - 1;
  double get _progressValue => _currentStep == _SignupStep.otp ? 1.0 : (_stepIndex / (_totalSteps - 1)).clamp(0.0, 1.0);

  Future<void> _handleRegister() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    final appConfig = ref.read(appConfigProvider);
    try {
      await viewModel.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: appConfig.signUpRole,
      );
      if (mounted) _goToStep(_SignupStep.otp);
    } catch (e) {
      if (mounted) {
        final msg = e is RateLimitExceeded
            ? 'Please wait ${e.secondsRemaining}s before trying again.'
            : 'Could not create account. Please try again.';
        context.showSnackBar(msg, type: SnackBarType.error);
      }
    }
  }

  Future<void> _handleResend() async {
    final viewModel = ref.read(authViewModelProvider.notifier);
    try {
      await viewModel.resendVerification(email: _emailController.text.trim());
      if (mounted) context.showSnackBar('Verification code sent!', type: SnackBarType.success);
    } catch (e) {
      if (mounted) {
        final message = e is RateLimitExceeded
            ? 'Please wait ${e.secondsRemaining}s before resending.'
            : 'Failed to resend. Please try again.';
        context.showSnackBar(message, type: SnackBarType.error);
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      context.showSnackBar('Please enter the full 6-digit code.', type: SnackBarType.error);
      return;
    }
    final viewModel = ref.read(authViewModelProvider.notifier);
    try {
      await viewModel.verifyOtp(email: _emailController.text.trim(), token: code);
    } catch (e) {
      if (mounted) {
        final msg = e is RateLimitExceeded
            ? 'Please wait ${e.secondsRemaining}s before trying again.'
            : 'Invalid or expired code. Please try again.';
        context.showSnackBar(msg, type: SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, 16, context.pagePad, 0),
              child: Row(
                children: [
                  if (_currentStep != _SignupStep.welcome && _currentStep != _SignupStep.otp)
                    AnimatedTapScale(
                      onTap: _prevStep,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(CupertinoIcons.chevron_left, size: 20, color: theme.colorScheme.onSurface),
                      ),
                    )
                  else if (_currentStep == _SignupStep.welcome)
                    AnimatedTapScale(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(CupertinoIcons.xmark, size: 20, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  const Spacer(),
                ],
              ),
            ),

            // Progress bar
            if (_currentStep != _SignupStep.welcome && _currentStep != _SignupStep.otp)
              Padding(
                padding: EdgeInsets.fromLTRB(context.pagePad, 12, context.pagePad, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: _progressValue),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 3,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                ),
              ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24),
                child: AnimatedBuilder(
                  animation: _slideController,
                  builder: (context, _) {
                    return SlideTransition(
                      position: _slideAnimation,
                      child: _buildCurrentStep(theme, viewModel),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(ThemeData theme, AuthViewModel viewModel) {
    switch (_currentStep) {
      case _SignupStep.welcome: return _buildWelcome(theme);
      case _SignupStep.name: return _buildNameStep(theme);
      case _SignupStep.email: return _buildEmailStep(theme);
      case _SignupStep.password: return _buildPasswordStep(theme);
      case _SignupStep.confirm: return _buildConfirmStep(theme, viewModel);
      case _SignupStep.otp: return _buildOtpStep(theme, viewModel);
    }
  }

  // ── Welcome ─────────────────────────────────────────────────────────────────
  Widget _buildWelcome(ThemeData theme) {
    return Container(
      padding: EdgeInsets.fromLTRB(context.pagePad, 16, context.pagePad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: const Icon(CupertinoIcons.house_fill, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 48),
          const Text(
            'Welcome to\nFijadora',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, height: 1.15, letterSpacing: -0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Set up your account — quick and painless, one step at a time.',
            style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => _goToStep(_SignupStep.name),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Get Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Already have an account? ', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              AnimatedTapScale(
                onTap: () => context.pop(),
                child: Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Name Step ───────────────────────────────────────────────────────────────
  Widget _buildNameStep(ThemeData theme) {
    return _FormStep(
      icon: CupertinoIcons.person_fill,
      title: 'What should we call you?',
      subtitle: 'This is how your name will appear across the app.',
      child: TextField(
        controller: _nameController,
        focusNode: _nameFocus,
        keyboardType: TextInputType.name,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _nextStep(),
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Full name',
          prefixIcon: const Icon(CupertinoIcons.person, size: 20),
          suffixIcon: _nameController.text.trim().isNotEmpty
              ? const Icon(CupertinoIcons.check_mark_circled_solid, size: 20, color: Colors.green)
              : null,
        ),
      ),
      button: _NextButton(
        enabled: _nameController.text.trim().isNotEmpty,
        label: 'Continue',
        onTap: _nextStep,
      ),
    );
  }

  // ── Email Step ──────────────────────────────────────────────────────────────
  Widget _buildEmailStep(ThemeData theme) {
    final email = _emailController.text.trim();
    final isValid = email.isNotEmpty && _isValidEmail(email);

    return _FormStep(
      icon: CupertinoIcons.mail_solid,
      title: 'Your email address',
      subtitle: 'We\'ll send a verification code to this email.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { if (isValid) _nextStep(); },
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'name@example.com',
              prefixIcon: const Icon(CupertinoIcons.mail, size: 20),
              suffixIcon: email.isNotEmpty
                  ? Icon(
                      isValid ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
                      size: 20, color: isValid ? Colors.green : Colors.red,
                    )
                  : null,
            ),
          ),
          if (email.isNotEmpty && !isValid)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text('Enter a valid email address', style: TextStyle(fontSize: 12, color: Colors.red.shade400)),
            ),
        ],
      ),
      button: _NextButton(
        enabled: isValid,
        label: 'Continue',
        onTap: _nextStep,
      ),
    );
  }

  // ── Password Step ───────────────────────────────────────────────────────────
  Widget _buildPasswordStep(ThemeData theme) {
    final bars = [false, false, false, false, false];
    for (var i = 0; i < _passwordStrength; i++) bars[i] = true;

    final colors = [Colors.red.shade400, Colors.orange, Colors.amber, Colors.green.shade400, Colors.green.shade700];
    final labels = ['Weak', 'Fair', 'Good', 'Strong', 'Very Strong'];

    return _FormStep(
      icon: CupertinoIcons.lock_fill,
      title: 'Create a password',
      subtitle: 'Mix letters, numbers, and symbols for a strong one.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: !_showPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { if (_passwordStrength >= 3) _nextStep(); },
            onChanged: (v) { _updatePasswordStrength(v); setState(() {}); },
            decoration: InputDecoration(
              hintText: 'At least 8 characters',
              prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_showPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 20),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
          if (_passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: List.generate(5, (i) => Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: bars[i] ? colors[i] : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              )),
            ),
            const SizedBox(height: 8),
            Text(
              _passwordStrength > 0 ? labels[_passwordStrength - 1] : '',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _passwordStrength > 0 ? colors[_passwordStrength - 1] : null),
            ),
            const SizedBox(height: 12),
            _RequirementRow(met: _passwordController.text.length >= 8, text: 'At least 8 characters'),
            _RequirementRow(met: RegExp(r'[A-Z]').hasMatch(_passwordController.text), text: 'One uppercase letter'),
            _RequirementRow(met: RegExp(r'[a-z]').hasMatch(_passwordController.text), text: 'One lowercase letter'),
            _RequirementRow(met: RegExp(r'[0-9]').hasMatch(_passwordController.text), text: 'One number'),
            _RequirementRow(met: RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(_passwordController.text), text: 'One special character'),
          ],
        ],
      ),
      button: _NextButton(
        enabled: _passwordStrength >= 3,
        label: 'Continue',
        onTap: _nextStep,
      ),
    );
  }

  // ── Confirm Password Step ──────────────────────────────────────────────────
  Widget _buildConfirmStep(ThemeData theme, AuthViewModel viewModel) {
    final match = _confirmPasswordController.text == _passwordController.text &&
        _confirmPasswordController.text.isNotEmpty;

    return _FormStep(
      icon: match ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.lock_fill,
      iconColor: match ? Colors.green : null,
      title: 'One more time',
      subtitle: 'Confirm your password to make sure it\'s right.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _confirmPasswordController,
            focusNode: _confirmFocus,
            obscureText: !_showConfirmPassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) { if (match) _nextStep(); },
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Re-enter your password',
              prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
              suffixIcon: IconButton(
                icon: Icon(_showConfirmPassword ? CupertinoIcons.eye_slash : CupertinoIcons.eye, size: 20),
                onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
              ),
            ),
          ),
          if (_confirmPasswordController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(
                    match ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.xmark_circle_fill,
                    size: 16, color: match ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    match ? 'Passwords match' : 'Passwords do not match',
                    style: TextStyle(fontSize: 13, color: match ? Colors.green : Colors.red.shade400),
                  ),
                ],
              ),
            ),
        ],
      ),
      button: _NextButton(
        enabled: match,
        label: 'Create Account',
        isLoading: viewModel.isLoading,
        onTap: _nextStep,
      ),
    );
  }

  // ── OTP Step ────────────────────────────────────────────────────────────────
  Widget _buildOtpStep(ThemeData theme, AuthViewModel viewModel) {
    final canResend = viewModel.cooldownSeconds == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(context.pagePad, 0, context.pagePad, 24),
      height: MediaQuery.of(context).size.height * 0.55,
      child: Column(
        children: [
          const Spacer(flex: 1),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.6)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(CupertinoIcons.mail, size: 32, color: Colors.white),
          ),
          const SizedBox(height: 32),
          const Text('Check your inbox', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          const SizedBox(height: 12),
          Text(
            'We sent a 6-digit code to\n${_emailController.text.trim()}',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = 4.0;
              final boxSize = ((constraints.maxWidth - gap * 5) / 6).clamp(40.0, 52.0);
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = _otpControllers[i].text.isNotEmpty;
                  return Container(
                    width: boxSize, height: boxSize + 10,
                    margin: EdgeInsets.only(right: i < 5 ? gap : 0),
                    decoration: BoxDecoration(
                      color: filled ? theme.colorScheme.primary.withValues(alpha: 0.06) : null,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: filled ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                        width: filled ? 2 : 1.5,
                      ),
                    ),
                    child: TextField(
                      controller: _otpControllers[i],
                      focusNode: _otpFocusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: TextStyle(fontSize: boxSize * 0.45, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {});
                        if (value.length == 1 && i < 5) {
                          _otpFocusNodes[i + 1].requestFocus();
                        } else if (value.isEmpty && i > 0) {
                          _otpFocusNodes[i - 1].requestFocus();
                        }
                        if (_otpControllers.every((c) => c.text.length == 1)) {
                          _handleVerifyOtp();
                        }
                      },
                    ),
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity, height: 56,
            child: ElevatedButton(
              onPressed: viewModel.isLoading ? null : _handleVerifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: viewModel.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Verify Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 56,
            child: OutlinedButton(
              onPressed: canResend ? _handleResend : null,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                canResend ? 'Resend Code' : 'Resend in ${viewModel.cooldownSeconds}s',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: canResend ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedTapScale(
            onTap: () {
              ref.read(authViewModelProvider.notifier).resetVerification();
              _goToStep(_SignupStep.email);
            },
            child: Text('Wrong email? Go back', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

// ── Form Step Wrapper ──────────────────────────────────────────────────────────
class _FormStep extends StatelessWidget {
  const _FormStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.button,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget button;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = context.pagePad;

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 24, pad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: (iconColor ?? theme.colorScheme.primary).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 28, color: iconColor ?? theme.colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: -0.3)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 28),
          child,
          const SizedBox(height: 32),
          button,
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
        ],
      ),
    );
  }
}

// ── Next Button ────────────────────────────────────────────────────────────────
class _NextButton extends StatelessWidget {
  const _NextButton({required this.enabled, required this.label, this.isLoading = false, required this.onTap});
  final bool enabled;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: enabled && !isLoading ? onTap : () {},
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity, height: 56,
        decoration: BoxDecoration(
          color: enabled ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600,
                      color: enabled ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                    )),
                    const SizedBox(width: 8),
                    Icon(CupertinoIcons.chevron_right, size: 18,
                      color: enabled ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Requirement Row ────────────────────────────────────────────────────────────
class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.met, required this.text});
  final bool met;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18, height: 18,
            decoration: BoxDecoration(
              color: met ? Colors.green : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: met ? Colors.green : Colors.grey.shade400, width: 1.5),
            ),
            child: met
                ? const Icon(CupertinoIcons.check_mark, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(fontSize: 13, color: met ? Colors.green.shade700 : Colors.grey.shade500)),
        ],
      ),
    );
  }
}
