import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/job_status.dart';
import '../../services/view_models/jobs_view_model.dart';

class JobCompletionPage extends ConsumerStatefulWidget {
  const JobCompletionPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<JobCompletionPage> createState() => _JobCompletionPageState();
}

class _JobCompletionPageState extends ConsumerState<JobCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  bool _photoCaptured = false;
  bool _isCapturing = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_photoCaptured) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(jobsViewModelProvider).updateStatus(widget.jobId, JobStatus.waitingApproval);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing job: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _simulatePhotoCapture() async {
    setState(() => _isCapturing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _photoCaptured = true;
        _isCapturing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion proof photo captured successfully.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Job',
          style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF9F9F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF333333)
                        : const Color(0xFFE5E5E5),
                  ),
                ),
                child: Column(
                  children: [
                    if (_photoCaptured) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=300&auto=format&fit=crop&q=60',
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Proof of Work Attached',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ] else ...[
                      Icon(CupertinoIcons.camera_fill, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 8),
                      const Text(
                        'Completion Photo Proof Required',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Take a photo of completed work to submit.',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isCapturing ? null : _simulatePhotoCapture,
                      icon: _isCapturing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : Icon(_photoCaptured ? CupertinoIcons.refresh : CupertinoIcons.camera),
                      label: Text(_isCapturing
                          ? 'Opening camera...'
                          : _photoCaptured
                              ? 'Retake Photo'
                              : 'Capture Proof'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF333333)
                              : const Color(0xFFCCCCCC),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  hintText: 'Describe the repairs done, parts replaced, etc...',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide completion notes';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting || !_photoCaptured ? null : _submitCompletion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit for Client Approval'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
