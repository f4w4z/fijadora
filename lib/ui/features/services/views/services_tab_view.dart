import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/job_status.dart';
import '../view_models/jobs_view_model.dart';
import '../../../../data/services/gemini_service.dart';
import '../../../../ui/shared/widgets/shimmer_loading.dart';
import '../../../../ui/features/services/views/live_tracking_view.dart';
import '../../../../ui/features/services/views/voice_assistant_sheet.dart';
import '../../profile/views/home_detail_list_view.dart';
import '../../../../data/services/telemetry_service.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';

class ServicesTabView extends ConsumerStatefulWidget {
  const ServicesTabView({super.key});

  @override
  ConsumerState<ServicesTabView> createState() => _ServicesTabViewState();
}

class _ServicesTabViewState extends ConsumerState<ServicesTabView> {
  String _searchQuery = '';

  void _showQrScannerSim(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final innerTheme = Theme.of(context);
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: innerTheme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('QR Code Scanner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(CupertinoIcons.clear),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan any Phoebe Homes QR tag found on wall plates, appliances, or manuals to load history instantly.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: innerTheme.colorScheme.primary, width: 3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(CupertinoIcons.qrcode, color: Colors.white38, size: 80),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HomeDetailListView(type: 'appliances'),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR Code scanned: Loaded digital appliance record'),
                    ),
                  );
                },
                icon: const Icon(CupertinoIcons.barcode_viewfinder),
                label: const Text('Simulate Appliance Tag Scan', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: innerTheme.colorScheme.primary,
                  foregroundColor: innerTheme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jobsViewModel = ref.watch(jobsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance & Repair'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.qrcode_viewfinder),
            tooltip: 'Scan Room QR',
            onPressed: () {
              _showQrScannerSim(context);
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.mic_fill),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const VoiceAssistantSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: () {
              // Re-initializes VM to get latest jobs
              ref.invalidate(jobsViewModelProvider);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(context, jobsViewModel),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewRequestSheet(context),
        label: const Text('Request Service'),
        icon: const Icon(CupertinoIcons.add),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, JobsViewModel vm) {
    if (vm.isLoading && vm.jobs.isEmpty) {
      return const ShimmerListPlaceholder();
    }

    if (vm.errorMessage != null && vm.jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.exclamationmark_triangle, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                vm.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (vm.jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.wrench,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No maintenance requests',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Everything in your home is running smoothly. Need something repaired? Request a service below.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredJobs = vm.jobs.where((job) {
      return _searchQuery.isEmpty ||
          job.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.address.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          job.tradeType.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: CupertinoSearchTextField(
            placeholder: 'Search requests...',
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
        Expanded(
          child: _JobList(jobs: filteredJobs),
        ),
      ],
    );
  }

  void _showNewRequestSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NewRequestSheet(),
    );
  }
}

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});
  final List<MaintenanceJob> jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 88),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _JobCard(job: jobs[index]);
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final MaintenanceJob job;

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = job.status.color(context);

    return AnimatedTapScale(
      onTap: () => _showDetailsSheet(context),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(job.tradeType.icon, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        job.tradeType.displayName,
                        style: theme.textTheme.titleLarge?.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      job.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                job.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              if (job.status == JobStatus.completed) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.shield_fill, color: Colors.green, size: 14),
                      SizedBox(width: 8),
                      Text(
                        '30-Day Workmanship Guarantee Active',
                        style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(CupertinoIcons.calendar, size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(job.scheduleDateTime),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      job.tradeType.displayName,
                      style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: job.status.color(context).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        job.status.displayName,
                        style: TextStyle(
                          color: job.status.color(context),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(job.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Text(
                  'Address / Location',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(job.address, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(
                  'Scheduled Time',
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Text(_formatDate(job.scheduleDateTime), style: theme.textTheme.bodyMedium),
                if (job.status == JobStatus.waitingApproval) ...[
                  _CustomerReviewPanel(jobId: job.id),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(CupertinoIcons.videocam_fill, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '🎥 Body cam active. Footage stored 6 months. Under T&Cs, claims cannot be made after 6 months.',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (job.status == JobStatus.workerEnRoute || job.status == JobStatus.workerArrived) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveTrackingView(
                            jobId: job.id,
                            address: job.address,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(CupertinoIcons.map_pin_ellipse),
                    label: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NewRequestSheet extends ConsumerStatefulWidget {
  const _NewRequestSheet();

  @override
  ConsumerState<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends ConsumerState<_NewRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  TradeType _selectedTrade = TradeType.generalRepairs;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isAiDiagnosing = false;

  Future<void> _runAiDiagnosis() async {
    setState(() => _isAiDiagnosing = true);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final diagnosis = await gemini.diagnoseImage(
        imagePath: 'mock_photo.jpg',
        tradeType: _selectedTrade,
      );

      setState(() {
        _descriptionController.text =
            'Summary: ${diagnosis.problemSummary}\n\n'
            'Required Tools: ${diagnosis.requiredTools.join(", ")}\n'
            'Suggested Parts: ${diagnosis.suggestedParts.join(", ")}\n'
            'Priority: ${diagnosis.priority}\n'
            'Est. Duration: ${diagnosis.estimatedDuration}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI diagnosis applied successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('AI diagnosis failed: $e')),
        );
      }
    } finally {
      setState(() => _isAiDiagnosing = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduledHour = _selectedTime.hour;
    if (scheduledHour < 13 || scheduledHour >= 22) {
      final proceed = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: const Text("We're Closed"),
            content: const Text(
              "Operating hours are 1 PM to 10 PM. Since your request is outside operations, we're closed and will handle it in the morning.",
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text("Proceed"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          );
        },
      );
      if (proceed != true) return;
    }

    final schedule = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    try {
      await ref.read(jobsViewModelProvider).raiseJob(
        description: _descriptionController.text.trim(),
        tradeType: _selectedTrade,
        schedule: schedule,
        address: _addressController.text.trim(),
        images: const [],
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error raising request: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreating = ref.watch(jobsViewModelProvider).isCreating;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Request a Service',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<TradeType>(
                  initialValue: _selectedTrade,
                  decoration: const InputDecoration(
                    labelText: 'Trade Type',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: TradeType.values.map((trade) {
                    return DropdownMenuItem(
                      value: trade,
                      child: Row(
                        children: [
                          Icon(trade.icon, size: 18),
                          const SizedBox(width: 8),
                          Text(trade.displayName),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedTrade = val);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Diagnosis Assistant',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isAiDiagnosing ? null : _runAiDiagnosis,
                      icon: _isAiDiagnosing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 1.5),
                            )
                          : const Icon(CupertinoIcons.sparkles, size: 14),
                      label: Text(_isAiDiagnosing ? 'Diagnosing...' : 'Scan Photo'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Problem Description',
                    hintText: 'Describe what needs fixing, or scan a photo above...',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please describe the problem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Service Address',
                    hintText: 'Where should the technician go?',
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Date'),
                          child: Text(_formatDate(_selectedDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Time'),
                          child: Text(_selectedTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isCreating ? null : _submit,
                    child: isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Submit Request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerReviewPanel extends ConsumerStatefulWidget {
  const _CustomerReviewPanel({required this.jobId});
  final String jobId;

  @override
  ConsumerState<_CustomerReviewPanel> createState() => _CustomerReviewPanelState();
}

class _CustomerReviewPanelState extends ConsumerState<_CustomerReviewPanel> {
  final _commentController = TextEditingController();
  final _signatureController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submitReview(JobStatus targetStatus) async {
    if (targetStatus == JobStatus.completed && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(jobsViewModelProvider).updateStatus(widget.jobId, targetStatus);
      
      ref.read(telemetryServiceProvider).logEvent('worker_rating', {
        'job_id': widget.jobId,
        'rating': _rating,
        'status': targetStatus.name,
        'comment': _commentController.text.trim(),
      });

      if (mounted) {
        Navigator.pop(context); // Close details sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(targetStatus == JobStatus.completed
                ? 'Job approved and signed off successfully!'
                : 'Job status: Complaint submitted.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting review: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Review Completed Work',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Technician has completed repairs. Rate their service and sign off.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starVal = index + 1;
              return IconButton(
                icon: Icon(
                  starVal <= _rating ? CupertinoIcons.star_fill : CupertinoIcons.star,
                  color: Colors.amber,
                  size: 28,
                ),
                onPressed: () {
                  setState(() => _rating = starVal.toDouble());
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Feedback / Comments',
              hintText: 'Share any notes about the service...',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _signatureController,
            decoration: const InputDecoration(
              labelText: 'Digital Signature (Type Full Name)',
              hintText: 'Your name is required to sign off',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please sign to approve the work';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          if (_isSubmitting)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => _submitReview(JobStatus.rejected),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Reject & Complain'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _submitReview(JobStatus.completed),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Approve & Sign Off'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
