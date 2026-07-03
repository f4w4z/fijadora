import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../domain/models/job_status.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';

class JobCompletionPage extends ConsumerStatefulWidget {
  const JobCompletionPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<JobCompletionPage> createState() => _JobCompletionPageState();
}

class _JobCompletionPageState extends ConsumerState<JobCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _partsController = TextEditingController();
  bool _isSubmitting = false;
  bool _photoCaptured = false;
  bool _isCapturing = false;

  @override
  void dispose() {
    _notesController.dispose();
    _partsController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_photoCaptured) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(jobsViewModelProvider)
          .updateStatus(widget.jobId, JobStatus.waitingApproval);
      if (mounted) {
        Navigator.pop(context);
        context.showSnackBar('Job submitted for approval',
            type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _capturePhoto() async {
    setState(() => _isCapturing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _photoCaptured = true;
        _isCapturing = false;
      });
      context.showSnackBar('Photo captured successfully',
          type: SnackBarType.success);
    }
  }

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
          'Complete Job',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo section
              Text(
                'Proof of Work',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    if (_photoCaptured) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl:
                              'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=400&h=300&fit=crop&q=60',
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.checkmark_circle_fill,
                              size: 16, color: const Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Text(
                            'Proof of Work Attached',
                            style: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Icon(CupertinoIcons.camera_fill,
                          size: 40,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text(
                        'Take a photo of the completed work',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is required for customer approval',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isCapturing ? null : _capturePhoto,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isCapturing
                              ? const SizedBox(
                                  key: ValueKey('capturing_icon'),
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _photoCaptured ? CupertinoIcons.refresh : CupertinoIcons.camera,
                                  key: const ValueKey('normal_icon'),
                                ),
                        ),
                        label: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _isCapturing
                                ? 'Opening camera...'
                                : _photoCaptured
                                    ? 'Retake Photo'
                                    : 'Capture Photo',
                            key: ValueKey<bool>(_isCapturing),
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notes section
              Text(
                'Resolution Notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe repairs done, parts replaced, etc...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please describe the work completed';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Parts used section
              Text(
                'Parts Used (optional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _partsController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'List any parts or materials used...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              AnimatedTapScale(
                onTap: _isSubmitting || !_photoCaptured
                    ? () {}
                    : () { _submitCompletion(); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isSubmitting || !_photoCaptured
                        ? theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.3)
                        : theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _isSubmitting
                          ? const SizedBox(
                              key: ValueKey('submitting_spinner'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Submit for Approval',
                              key: const ValueKey('submit_text'),
                              style: TextStyle(
                                color: theme.colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              if (!_photoCaptured) ...[
                const SizedBox(height: 8),
                Text(
                  'Capture a photo first to enable submission',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
