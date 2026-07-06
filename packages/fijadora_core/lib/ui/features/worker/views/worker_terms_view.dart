import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/utilities/responsive_helpers.dart';

class WorkerTermsView extends StatelessWidget {
  const WorkerTermsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.only(left: AppSpacing.lg),
            child: Icon(CupertinoIcons.chevron_left, size: 22, color: theme.colorScheme.onSurface),
          ),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 40),
        children: [
          Text(
            'Terms of Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated: June 2026',
            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          _section(theme,
            title: '1. Services Provided',
            body: 'Fijadora connects homeowners with qualified service professionals. As a worker, you agree to perform services listed on the platform with professional care and in compliance with all applicable laws and regulations.',
          ),
          const SizedBox(height: 20),
          _section(theme,
            title: '2. Worker Obligations',
            body: 'You agree to: (a) maintain valid licenses and insurance as required by law; (b) arrive at scheduled appointments on time; (c) perform work to a professional standard; (d) communicate professionally with customers; (e) not solicit customers outside the platform.',
          ),
          const SizedBox(height: 20),
          _section(theme,
            title: '3. Payments',
            body: 'Payments for completed jobs are processed through the platform. Standard payment terms are net-7 for approved jobs. Fijadora retains a service fee as disclosed in your agreement. Disputes must be reported within 48 hours of job completion.',
          ),
          const SizedBox(height: 20),
          _section(theme,
            title: '4. Conduct',
            body: 'Workers must maintain professional conduct at all times. Harassment, discrimination, theft, or damage to customer property will result in immediate deactivation. All work must be performed safely and in compliance with industry standards.',
          ),
          const SizedBox(height: 20),
          _section(theme,
            title: '5. Liability',
            body: 'Workers are responsible for their own work and carry appropriate liability insurance. Fijadora is not liable for damages arising from work performed. Workers indemnify Fijadora against claims arising from their services.',
          ),
          const SizedBox(height: 20),
          _section(theme,
            title: '6. Termination',
            body: 'Either party may terminate this agreement at any time. Fijadora reserves the right to deactivate workers for violating these terms. Upon termination, outstanding payments for completed work will be settled.',
          ),
        ],
      ),
    );
  }

  Widget _section(ThemeData theme, {required String title, required String body}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text(body, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
      ],
    );
  }
}
