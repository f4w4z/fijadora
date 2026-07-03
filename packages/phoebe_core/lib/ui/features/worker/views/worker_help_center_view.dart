import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';

class WorkerHelpCenterView extends StatefulWidget {
  const WorkerHelpCenterView({super.key});

  @override
  State<WorkerHelpCenterView> createState() => _WorkerHelpCenterViewState();
}

class _WorkerHelpCenterViewState extends State<WorkerHelpCenterView> {
  int? _expandedFaq;

  final _faqs = [
    ('How do I grab a job?', 'Tap the "Grab" button on any available job card in the dashboard. The job will be assigned to you immediately.'),
    ('How do I update job status?', 'Open a job from your dashboard or schedule, then tap the action button at the bottom (En Route, Arrived, Start Job, Complete Job).'),
    ('What happens when I complete a job?', 'You\'ll be taken to the completion page where you can add a photo of the completed work, write resolution notes, and list any parts used. Submit for customer approval.'),
    ('How does payment work?', 'Payments are processed weekly. You can view your earnings and payment history in your profile settings.'),
    ('Can I set my availability?', 'Yes. Go to Profile > Availability to set your working hours and toggle whether you\'re accepting new jobs.'),
    ('Who do I contact for support?', 'Use the "Contact Support" button below to reach our team. We typically respond within 2 hours during business hours.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appVersion = '1.0.0';

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
          'Help Center',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 40),
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          ...List.generate(_faqs.length, (i) {
            final isExpanded = _expandedFaq == i;
            return Padding(
              padding: EdgeInsets.only(bottom: i < _faqs.length - 1 ? 8 : 0),
              child: _FaqTile(
                question: _faqs[i].$1,
                answer: _faqs[i].$2,
                isExpanded: isExpanded,
                onTap: () => setState(() => _expandedFaq = isExpanded ? null : i),
                theme: theme,
              ),
            );
          }),
          const SizedBox(height: 32),
          Text(
            'Still need help?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _SupportButton(theme: theme),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'App Version $appVersion',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;
  final ThemeData theme;

  const _FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                  ),
                ),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(CupertinoIcons.chevron_down, size: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  answer,
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant, height: 1.4),
                ),
              ),
              crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportButton extends StatelessWidget {
  final ThemeData theme;
  const _SupportButton({required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.showSnackBar('Opening support chat...');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.chat_bubble_text_fill, size: 18, color: theme.colorScheme.onPrimary),
            const SizedBox(width: 10),
            Text(
              'Contact Support',
              style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
