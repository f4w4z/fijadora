import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/models/trade_type.dart';
import '../view_models/jobs_view_model.dart';
import '../../../../data/services/gemini_service.dart';
import '../../../core/theme.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/date_extensions.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../home/view_models/home_view_model.dart';
import '../service_constants.dart';

class NewRequestPage extends ConsumerStatefulWidget {
  final TradeType? initialTrade;
  final String? initialDescription;
  const NewRequestPage({super.key, this.initialTrade, this.initialDescription});

  @override
  ConsumerState<NewRequestPage> createState() => _NewRequestPageState();
}

class _NewRequestPageState extends ConsumerState<NewRequestPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accessController = TextEditingController();
  late final ScrollController _tradeScrollController;

  late TradeType _selectedTrade;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: operatingHoursStart, minute: 0);
  bool _isAiDiagnosing = false;
  bool _useSavedProperty = false;

  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _selectedImages = [];
  AiDiagnosis? _aiDiagnosis;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _selectedTrade = widget.initialTrade ?? TradeType.plumbing;
    _tradeScrollController = ScrollController();



    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = TradeType.values.indexOf(_selectedTrade);
      if (index > 0 && _tradeScrollController.hasClients) {
        _tradeScrollController.animateTo(
          index * 152.0 - 16.0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });

    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final property = await ref.read(homePropertyProvider.future);
    if (property != null && property.address.isNotEmpty && mounted) {
      setState(() => _useSavedProperty = true);
      _addressController.text = '${property.name}, ${property.address}';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _accessController.dispose();
    _tradeScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImages.add(bytes);
          _aiDiagnosis = null;
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error selecting image: $e', type: SnackBarType.error);
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _aiDiagnosis = null;
    });
  }

  Future<void> _showImageSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add Photo', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SourceButton(
                    icon: CupertinoIcons.camera_fill,
                    label: 'Camera',
                    onTap: () => Navigator.pop(ctx, ImageSource.camera),
                  ),
                  _SourceButton(
                    icon: CupertinoIcons.photo_fill,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _pickImage(source);
  }

  Future<void> _runAiDiagnosis() async {
    setState(() => _isAiDiagnosing = true);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final diagnosis = await gemini.diagnoseImage(
        imageBytes: _selectedImages.first,
        tradeType: _selectedTrade,
      );

      setState(() {
        _aiDiagnosis = diagnosis;
      });

      if (mounted) {
        context.showSnackBar('AI diagnosis complete!', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('AI diagnosis failed: $e', type: SnackBarType.error);
      }
    } finally {
      setState(() => _isAiDiagnosing = false);
    }
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
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final theme = Theme.of(context);
          return AlertDialog(
            icon: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                CupertinoIcons.clock_fill,
                color: theme.colorScheme.error,
                size: 40,
              ),
            ),
            title: const Text("We're Closed"),
            content: const Text(
              afterHoursMessage,
              textAlign: TextAlign.center,
            ),
            actionsAlignment: MainAxisAlignment.spaceEvenly,
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text(
                  'Proceed',
                  style: TextStyle(
                    color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        setState(() => _isAiDiagnosing = true);
        try {
          for (final bytes in _selectedImages) {
            final fileName = 'job_${DateTime.now().millisecondsSinceEpoch}_${_selectedImages.indexOf(bytes)}.jpg';
            final url = await ref.read(jobsViewModelProvider).uploadJobImage(fileName, bytes);
            imageUrls.add(url);
          }
        } finally {
          if (mounted) setState(() => _isAiDiagnosing = false);
        }
      }

      await ref.read(jobsViewModelProvider).raiseJob(
        description: _descriptionController.text.trim(),
        tradeType: _selectedTrade,
        schedule: schedule,
        address: _addressController.text.trim(),
        images: imageUrls,
        contactPhone: _phoneController.text.trim(),
        accessNotes: _accessController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error raising request: $e', type: SnackBarType.error);
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color bg = Colors.grey.withValues(alpha: 0.1);
    Color fg = Colors.grey;
    IconData icon = CupertinoIcons.flag_fill;

    switch (priority.toLowerCase()) {
      case 'critical':
        bg = Colors.red.withValues(alpha: 0.1);
        fg = Colors.red;
        icon = CupertinoIcons.exclamationmark_octagon_fill;
        break;
      case 'high':
        bg = Colors.orange.withValues(alpha: 0.1);
        fg = Colors.orange;
        icon = CupertinoIcons.exclamationmark_circle_fill;
        break;
      case 'medium':
        bg = Colors.amber.withValues(alpha: 0.1);
        fg = Colors.amber[800] ?? Colors.amber;
        icon = CupertinoIcons.info_circle_fill;
        break;
      case 'low':
        bg = Colors.blue.withValues(alpha: 0.1);
        fg = Colors.blue;
        icon = CupertinoIcons.arrow_down_circle_fill;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationBadge(String duration) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.clock, size: 12, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            duration,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayColor = isDark
        ? Color.lerp(color, Colors.white, 0.3) ?? color
        : Color.lerp(color, Colors.black, 0.2) ?? color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: displayColor,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildServiceTypeSection() {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('What service do you need?', CupertinoIcons.hammer_fill),
        SizedBox(
          height: 110,
          child: ListView.builder(
            controller: _tradeScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: TradeType.values.length,
            itemBuilder: (context, index) {
              final trade = TradeType.values[index];
              final isSelected = trade == _selectedTrade;
              final colors = serviceGradients[trade] ?? [theme.colorScheme.primary, theme.colorScheme.primary];
              final tagline = serviceTaglines[trade] ?? '';
              final price = serviceStartingPrices[trade] ?? '';

              return Padding(
                padding: const EdgeInsets.only(right: 12, bottom: 8, top: 2),
                child: AnimatedTapScale(
                  onTap: () {
                    setState(() {
                      _selectedTrade = trade;
                    });
                  },
                  child: Container(
                    width: 140,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.06)
                          : cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.4),
                        width: isSelected ? 1.8 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                trade.icon,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                CupertinoIcons.checkmark_circle_fill,
                                size: 14,
                                color: theme.colorScheme.primary,
                              )
                            else
                              Text(
                                price,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trade.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              tagline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 9,
                                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Add Photos', CupertinoIcons.photo_fill),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _selectedImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == _selectedImages.length) {
                    return _AddPhotoTile(onTap: _showImageSourceSheet);
                  }
                  return _PhotoTile(
                    bytes: _selectedImages[index],
                    onDelete: () => _removeImage(index),
                  );
                },
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showImageSourceSheet,
                    icon: const Icon(CupertinoIcons.camera, size: 14),
                    label: const Text('Add Photo', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // AI Diagnosis
        if (_selectedImages.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
                width: 1,
              ),
              color: theme.cardTheme.color ?? theme.cardColor,
            ),
            clipBehavior: Clip.antiAlias,
            child: _isAiDiagnosing
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        const CustomMagicLoader(),
                        const SizedBox(height: 16),
                        Text(
                          'Fijadora AI is analyzing your image...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Detecting required tools, suggested parts & urgency.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : _aiDiagnosis != null
                    ? _buildDiagnosisResults()
                    : _buildDiagnosisPrompt(),
          ),
        ],
      ],
    );
  }

  Widget _buildDiagnosisPrompt() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(CupertinoIcons.sparkles, color: theme.colorScheme.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fijadora AI™ Smart Diagnosis',
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      'Instant severity & duration estimates from photos',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AnimatedTapScale(
            onTap: _runAiDiagnosis,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.sparkles, color: Colors.white, size: 15),
                  SizedBox(width: 8),
                  Text(
                    'Diagnose with AI',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisResults() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedImages.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _selectedImages.first,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildPriorityBadge(_aiDiagnosis!.priority),
                        const SizedBox(width: 8),
                        _buildDurationBadge(_aiDiagnosis!.estimatedDuration),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _aiDiagnosis!.problemSummary,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_aiDiagnosis!.requiredTools.isNotEmpty) ...[
            Text('Required Tools', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _aiDiagnosis!.requiredTools.map((t) => _buildChip(t, Colors.blue)).toList()),
            const SizedBox(height: 12),
          ],
          if (_aiDiagnosis!.suggestedParts.isNotEmpty) ...[
            Text('Suggested Parts', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: _aiDiagnosis!.suggestedParts.map((p) => _buildChip(p, Colors.teal)).toList()),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _descriptionController.text = _aiDiagnosis!.problemSummary;
                      if (_aiDiagnosis!.requiredTools.isNotEmpty || _aiDiagnosis!.suggestedParts.isNotEmpty) {
                        _descriptionController.text += '\n\n🔧 Required Tools: ${_aiDiagnosis!.requiredTools.join(", ")}'
                            '\n📦 Suggested Parts: ${_aiDiagnosis!.suggestedParts.join(", ")}'
                            '\n⏳ Estimated Time: ${_aiDiagnosis!.estimatedDuration}';
                      }
                    });
                    context.showSnackBar('AI details applied to description!', type: SnackBarType.success);
                  },
                  icon: const Icon(CupertinoIcons.doc_append, size: 14),
                  label: const Text('Apply to Description', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  setState(() {
                    _aiDiagnosis = null;
                    _selectedImages.clear();
                  });
                },
                icon: const Icon(CupertinoIcons.refresh, size: 16),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Describe the Issue', CupertinoIcons.text_alignleft),
        TextFormField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Problem Description',
            hintText: 'Describe what needs fixing...',
            alignLabelWithHint: true,
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please describe the problem';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Contact Info', CupertinoIcons.person_fill),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Best number to reach you',
            prefixIcon: Icon(CupertinoIcons.phone, size: 18),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please provide a contact number';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _accessController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Access Instructions (optional)',
            hintText: 'Gate code, security info, special instructions...',
            prefixIcon: Icon(CupertinoIcons.lock_fill, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Location', CupertinoIcons.location_fill),
        if (_useSavedProperty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.house_fill, size: 14, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Using saved property address',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _useSavedProperty = false;
                      _addressController.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Change', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Service Address',
            hintText: 'Where should the specialist go?',
            prefixIcon: Icon(CupertinoIcons.location_solid, size: 18),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter an address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildScheduleSection() {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.cardColor;
    final scheduledHour = _selectedTime.hour;
    final isOffHours = scheduledHour < 13 || scheduledHour >= 22;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Schedule Service', CupertinoIcons.clock_fill),
        Row(
          children: [
            Expanded(
              child: AnimatedTapScale(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(CupertinoIcons.calendar, size: 16, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDate.formattedDateOnly,
                              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedTapScale(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(
                      color: isOffHours
                          ? Colors.amber.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isOffHours
                              ? Colors.amber.withValues(alpha: 0.1)
                              : theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          CupertinoIcons.clock,
                          size: 16,
                          color: isOffHours ? Colors.amber[800] : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTime.format(context),
                              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isOffHours) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill, size: 14, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    operatingHoursMessage,
                    style: TextStyle(fontSize: 10, color: Colors.amber[900] ?? Colors.amber, fontWeight: FontWeight.w500, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummarySection() {
    final theme = Theme.of(context);
    final price = serviceStartingPrices[_selectedTrade] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Review & Submit', CupertinoIcons.doc_checkmark_fill),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              _SummaryRow(icon: _selectedTrade.icon, label: 'Service', value: _selectedTrade.displayName),
              const SizedBox(height: 10),
              _SummaryRow(
                icon: CupertinoIcons.photo_fill,
                label: 'Photos',
                value: '${_selectedImages.length} photo${_selectedImages.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: 10),
              _SummaryRow(icon: CupertinoIcons.calendar, label: 'Date', value: _selectedDate.formattedDateOnly),
              const SizedBox(height: 10),
              _SummaryRow(icon: CupertinoIcons.clock, label: 'Time', value: _selectedTime.format(context)),
              const SizedBox(height: 10),
              _SummaryRow(icon: CupertinoIcons.location_solid, label: 'Address', value: _addressController.text.isNotEmpty ? _addressController.text : 'Not set'),
              if (price.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(CupertinoIcons.money_dollar_circle_fill, size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Starting from ', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                    Text(price, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                    const Spacer(),
                    Text('Price quoted after review', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreating = ref.watch(jobsViewModelProvider).isCreating;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Book a Service',
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.xmark),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Step indicator
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StepDot(label: 'Details'),
                    _StepLine(),
                    _StepDot(label: 'Photos'),
                    _StepLine(),
                    _StepDot(label: 'Contact'),
                    _StepLine(),
                    _StepDot(label: 'Review'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildServiceTypeSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPhotosSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildDescriptionSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContactSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLocationSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildScheduleSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSummarySection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AnimatedTapScale(
                  onTap: isCreating ? () {} : _submit,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: isCreating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Submit Request',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  const _StepDot({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF155B60),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 24,
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: theme.colorScheme.outline.withValues(alpha: 0.2),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.plus, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text('Add', style: TextStyle(fontSize: 9, color: theme.colorScheme.primary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onDelete;
  const _PhotoTile({required this.bytes, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
        height: 80,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(bytes, fit: BoxFit.cover),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.xmark, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedTapScale(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _SummaryRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class SpinningSparkles extends StatefulWidget {
  const SpinningSparkles({super.key});

  @override
  State<SpinningSparkles> createState() => _SpinningSparklesState();
}

class _SpinningSparklesState extends State<SpinningSparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: const Icon(CupertinoIcons.sparkles, size: 14),
    );
  }
}

class CustomMagicLoader extends StatelessWidget {
  const CustomMagicLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 32,
      width: 32,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
