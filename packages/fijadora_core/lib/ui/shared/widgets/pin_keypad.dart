import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A UPI-style PIN entry screen with a numeric keypad.
///
/// [title] and [subtitle] describe the action. [length] is the expected PIN
/// length. [obscure] toggles dots vs raw digits. [onCompleted] fires with the
/// full PIN once [length] digits are entered. [onChanged] fires on every key.
class PinKeypadScreen extends StatefulWidget {
  const PinKeypadScreen({
    required this.title,
    this.subtitle,
    this.length = 4,
    this.obscure = true,
    this.showBiometric = false,
    this.onBiometric,
    this.onCompleted,
    this.onChanged,
    this.initialError,
    super.key,
  });

  final String title;
  final String? subtitle;
  final int length;
  final bool obscure;
  final bool showBiometric;
  final VoidCallback? onBiometric;
  final ValueChanged<String>? onCompleted;
  final ValueChanged<String>? onChanged;
  final String? initialError;

  @override
  State<PinKeypadScreen> createState() => _PinKeypadScreenState();
}

class _PinKeypadScreenState extends State<PinKeypadScreen> {
  late String _value;
  late String? _error;
  bool _justShook = false;

  @override
  void initState() {
    super.initState();
    _value = '';
    _error = widget.initialError;
  }

  void _press(String digit) {
    if (_error != null) {
      setState(() => _error = null);
    }
    if (_value.length >= widget.length) return;
    final next = _value + digit;
    setState(() => _value = next);
    widget.onChanged?.call(next);
    if (next.length == widget.length) {
      widget.onCompleted?.call(next);
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted && context.mounted) {
          Navigator.of(context).pop(next);
        }
      });
    }
  }

  void _backspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
    widget.onChanged?.call(_value);
  }

  void showError(String message) {
    setState(() {
      _error = message;
      _justShook = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _justShook = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dots = List.generate(widget.length, (i) {
      final filled = i < _value.length;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: filled ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: 1.5,
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            if (widget.subtitle != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                ),
              ),
            const SizedBox(height: 20),
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              transform: Matrix4.translationValues(_justShook ? 8.0 : 0, 0, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...dots.expand((d) => [d, const SizedBox(width: 16)]).toList()..removeLast(),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            if (widget.showBiometric)
              IconButton(
                icon: Icon(CupertinoIcons.lock_shield, size: 28, color: theme.colorScheme.primary),
                onPressed: widget.onBiometric,
              ),
            _Keypad(
              onDigit: _press,
              onBackspace: _backspace,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.7,
        ),
        itemBuilder: (context, i) {
          final key = _keys[i];
          if (key == '') return const SizedBox.shrink();
          if (key == 'del') {
            return _KeyButton(
              onTap: onBackspace,
              child: Icon(CupertinoIcons.delete_left, size: 26, color: theme.colorScheme.onSurface),
            );
          }
          return _KeyButton(
            onTap: () => onDigit(key),
            child: Text(key, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w500)),
          );
        },
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Center(child: child),
      ),
    );
  }
}

/// Opens a UPI-style PIN screen and returns the entered PIN (or null if cancelled).
Future<String?> showPinKeypad({
  required BuildContext context,
  required String title,
  String? subtitle,
  int length = 4,
  bool obscure = true,
  bool showBiometric = false,
  VoidCallback? onBiometric,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (ctx) => PinKeypadScreen(
        title: title,
        subtitle: subtitle,
        length: length,
        obscure: obscure,
        showBiometric: showBiometric,
        onBiometric: onBiometric,
      ),
    ),
  );
}
