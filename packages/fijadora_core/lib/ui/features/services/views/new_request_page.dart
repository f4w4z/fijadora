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
  late final ScrollController _tradeScrollController;

  late TradeType _selectedTrade;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 13, minute: 0); // Default to operating hour (1 PM)
  bool _isAiDiagnosing = false;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  AiDiagnosis? _aiDiagnosis;

  static const Map<TradeType, List<Color>> _serviceGradients = {
    TradeType.interiorDesign: [Color(0xFF8E44AD), Color(0xFFBB8FCE)],
    TradeType.electrical: [Color(0xFF7D3C98), Color(0xFFA569BD)],
    TradeType.plumbing: [Color(0xFF1A5276), Color(0xFF2980B9)],
    TradeType.masonry: [Color(0xFF935116), Color(0xFFCA6F1E)],
    TradeType.tiling: [Color(0xFF0E6251), Color(0xFF148F77)],
    TradeType.designConsultation: [Color(0xFFC0392B), Color(0xFFE74C3C)],
    TradeType.acEngineering: [Color(0xFF1B4F72), Color(0xFF2E86C1)],
    TradeType.kitchenDesigns: [Color(0xFF4A235A), Color(0xFF76448A)],
    TradeType.cleaning: [Color(0xFF1A5276), Color(0xFF2980B9)],
    TradeType.gardening: [Color(0xFF0E6251), Color(0xFF148F77)],
  };

  static const Map<TradeType, String> _serviceTaglines = {
    TradeType.interiorDesign: 'Styling & space planning',
    TradeType.electrical: 'Wiring & smart home fixes',
    TradeType.plumbing: 'Leaks, drains & fixtures',
    TradeType.masonry: 'Stone & concrete repairs',
    TradeType.tiling: 'Floor & wall grout repair',
    TradeType.designConsultation: 'Expert layout advice',
    TradeType.acEngineering: 'AC install & servicing',
    TradeType.kitchenDesigns: 'Custom cabinets & layout',
    TradeType.cleaning: 'Deep & routine cleanups',
    TradeType.gardening: 'Lawn, pruning & yard care',
  };

  static const Map<TradeType, String> _startingPrices = {
    TradeType.interiorDesign: r'From $150',
    TradeType.electrical: r'From $75',
    TradeType.plumbing: r'From $85',
    TradeType.masonry: r'From $120',
    TradeType.tiling: r'From $95',
    TradeType.designConsultation: r'From $80',
    TradeType.acEngineering: r'From $110',
    TradeType.kitchenDesigns: r'From $200',
    TradeType.cleaning: r'From $65',
    TradeType.gardening: r'From $90',
  };

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _selectedTrade = widget.initialTrade ?? TradeType.plumbing;
    _tradeScrollController = ScrollController();

    // Auto scroll to pre-selected trade
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final index = TradeType.values.indexOf(_selectedTrade);
      if (index > 0 && _tradeScrollController.hasClients) {
        _tradeScrollController.animateTo(
          index * 152.0 - 16.0, // width (140) + padding (12)
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
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
          _selectedImageBytes = bytes;
          _aiDiagnosis = null; // Reset previous diagnosis on new image selection
        });
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error selecting image: $e', type: SnackBarType.error);
      }
    }
  }

  Future<void> _runAiDiagnosis() async {
    setState(() => _isAiDiagnosing = true);
    try {
      final gemini = ref.read(geminiServiceProvider);
      final diagnosis = await gemini.diagnoseImage(
        imageBytes: _selectedImageBytes,
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
              "Operating hours are 1 PM to 10 PM. Since your request is outside operations, we're closed and will handle it in the morning.",
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
      if (_selectedImageBytes != null) {
        setState(() => _isAiDiagnosing = true);
        try {
          final fileName = 'job_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final url = await ref.read(jobsViewModelProvider).uploadJobImage(fileName, _selectedImageBytes!);
          imageUrls.add(url);
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
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error raising request: $e', type: SnackBarType.error);
      }
    }
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

  Widget _buildAiMagicBox() {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.cardColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
          width: 1,
        ),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header of Magic Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.sparkles,
                    color: theme.colorScheme.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fijadora AI™ Smart Diagnosis',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Instant severity & duration estimates from photos',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.5)),

          if (_isAiDiagnosing) ...[
            // Loading state
            Padding(
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
            ),
          ] else if (_aiDiagnosis != null) ...[
            // Results State
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedImageBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
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
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_aiDiagnosis!.requiredTools.isNotEmpty) ...[
                    Text(
                      'Required Tools',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _aiDiagnosis!.requiredTools.map((t) => _buildChip(t, Colors.blue)).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_aiDiagnosis!.suggestedParts.isNotEmpty) ...[
                    Text(
                      'Suggested Parts',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _aiDiagnosis!.suggestedParts.map((p) => _buildChip(p, Colors.teal)).toList(),
                    ),
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
                          label: const Text('Apply to Problem Description', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _aiDiagnosis = null;
                            _selectedImageBytes = null;
                          });
                        },
                        icon: const Icon(CupertinoIcons.refresh, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            // Normal picker state
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedImageBytes != null) ...[
                    // Photo selected but not diagnosed
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            _selectedImageBytes!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photo selected',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Run diagnosis to auto-estimate tools & parts.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedImageBytes = null;
                            });
                          },
                          icon: const Icon(CupertinoIcons.xmark_circle_fill, size: 20),
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // No photo selected
                    Text(
                      'Let Fijadora AI scan a photo to estimate severity, parts, and duration instantly.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(CupertinoIcons.camera, size: 14),
                            label: const Text('Take Photo', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(CupertinoIcons.photo, size: 14),
                            label: const Text('Add Photo', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDatePickerSection() {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.cardColor;
    final scheduledHour = _selectedTime.hour;
    final isOffHours = scheduledHour < 13 || scheduledHour >= 22;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Schedule Service',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
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
                        child: Icon(
                          CupertinoIcons.calendar,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedDate.formattedDateOnly,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
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
                            Text(
                              'Time',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedTime.format(context),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
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
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(CupertinoIcons.info_circle_fill, size: 14, color: Colors.amber[800]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fijadora operates between 1 PM and 10 PM. Requests placed outside working hours will be reviewed next morning.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.amber[900] ?? Colors.amber,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreating = ref.watch(jobsViewModelProvider).isCreating;
    final cardColor = theme.cardTheme.color ?? theme.cardColor;

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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: context.pagePad, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Trade Selection Carousel Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'Select Service Type',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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
                              final colors = _serviceGradients[trade] ?? [theme.colorScheme.primary, theme.colorScheme.primary];
                              final tagline = _serviceTaglines[trade] ?? '';
                              final price = _startingPrices[trade] ?? '';

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
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // AI Smart Diagnosis
                    _buildAiMagicBox(),
                    const SizedBox(height: AppSpacing.lg),

                    // Problem Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Problem Description',
                        hintText: 'Describe what needs fixing...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 56),
                          child: Icon(
                            CupertinoIcons.text_alignleft,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please describe the problem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Service Address
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Service Address',
                        hintText: 'Where should the specialist go?',
                        prefixIcon: Icon(
                          CupertinoIcons.location_solid,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Date & Time Custom Cards
                    _buildDatePickerSection(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),

            // Floating Bottom Button Container
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
                        : const Text(
                            'Submit Request',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
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
