import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme_provider.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/widgets/animated_tap_scale.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 40),
        children: [
          _section(context, 'General'),
          _SettingsRow(
            icon: CupertinoIcons.bell_fill,
            title: 'Notifications',
            subtitle: 'Alert preferences',
            onTap: () => _showComingSoon(context, 'Notifications'),
          ),
          const Divider(height: 1, indent: 44),
          const _AppearanceRow(),
          const Divider(height: 1, indent: 44),
          _SettingsRow(
            icon: CupertinoIcons.creditcard,
            title: 'Payment Methods',
            subtitle: 'Cards & billing',
            onTap: () => _showComingSoon(context, 'Payment Methods'),
          ),
          const SizedBox(height: 28),
          _section(context, 'About'),
          _SettingsRow(
            icon: CupertinoIcons.doc_text,
            title: 'Terms & Conditions',
            subtitle: 'Platform terms',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _StaticContentPage(
                title: 'Terms & Conditions',
                body: _termsContent,
              )),
            ),
          ),
          const Divider(height: 1, indent: 44),
          _SettingsRow(
            icon: CupertinoIcons.shield,
            title: 'Privacy Policy',
            subtitle: 'Data handling',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _StaticContentPage(
                title: 'Privacy Policy',
                body: _privacyContent,
              )),
            ),
          ),
          const Divider(height: 1, indent: 44),
          _SettingsRow(
            icon: CupertinoIcons.question_circle,
            title: 'Help & Support',
            subtitle: 'Get help',
            onTap: () => _showHelp(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(feature),
        content: Text('$feature settings are coming soon. Stay tuned!'),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _showHelp(BuildContext context) async {
    final email = Uri(scheme: 'mailto', path: 'support@fijadora.com', queryParameters: {'subject': 'Help Request'});
    if (await canLaunchUrl(email)) {
      await launchUrl(email);
    } else {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Help & Support'),
            content: const Text('Email us at support@fijadora.com or reach out through the app.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Widget _section(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

const _termsContent = '''
Terms & Conditions

Welcome to Fijadora. By using our service, you agree to the following terms:

1. Services: Fijadora connects customers with vetted service professionals for property maintenance and home improvement.

2. Orders: All orders placed through the platform are subject to acceptance by Fijadora. Delivery fees are provided as quotes and must be accepted before order processing begins.

3. Payments: Payments are processed securely through Paystack. Your payment information is never stored on our servers.

4. Cancellations: Orders may be cancelled before they enter the preparing stage. Contact support for cancellation requests.

5. Liability: Fijadora acts as a marketplace platform and is not directly liable for services rendered by third-party professionals.

6. Privacy: Your data is handled in accordance with our Privacy Policy.

For full terms, please contact support@fijadora.com.
''';

const _privacyContent = '''
Privacy Policy

Your privacy matters to us. Here's how Fijadora handles your data:

1. Data Collection: We collect your name, email, address, and payment information necessary to process orders and provide services.

2. Data Usage: Your data is used to fulfill orders, communicate delivery updates, and improve our services.

3. Data Storage: Your data is stored securely on encrypted servers. We use industry-standard security measures.

4. Third Parties: We share necessary data with payment processors (Paystack) and delivery partners solely for order fulfillment.

5. Your Rights: You may request access to, correction of, or deletion of your personal data by contacting support@fijadora.com.

6. Cookies: Our platform uses essential cookies for functionality.
''';

class _StaticContentPage extends StatelessWidget {
  const _StaticContentPage({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          body,
          style: TextStyle(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: onTap,
      scaleFactor: 0.98,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
            ),
            if (subtitle != null)
              Text(subtitle!, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(width: 8),
            Icon(CupertinoIcons.chevron_right, size: 14, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _AppearanceRow extends ConsumerWidget {
  const _AppearanceRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return SizedBox(
      height: 50,
      child: Row(
        children: [
          Icon(CupertinoIcons.moon_fill, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Text('Appearance', style: TextStyle(fontSize: 15, color: theme.colorScheme.onSurface)),
          ),
          Text(isDark ? 'Dark mode' : 'Light mode', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: isDark,
            activeTrackColor: theme.colorScheme.primary,
            onChanged: (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
    );
  }
}
