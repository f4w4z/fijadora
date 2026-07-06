import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../services/view_models/jobs_view_model.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';

class _RepaintBoundaryProvider extends StatelessWidget {
  const _RepaintBoundaryProvider({required this.repaintKey, required this.child});
  final GlobalKey repaintKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintKey,
      child: child,
    );
  }
}



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
  final ImagePicker _picker = ImagePicker();
  final List<Uint8List> _imageBytesList = [];
  bool _isSubmitting = false;
  bool _isCapturing = false;

  final GlobalKey _repaintKey = GlobalKey();
  final List<Offset?> _sigPoints = [];

  @override
  void dispose() {
    _notesController.dispose();
    _partsController.dispose();
    super.dispose();
  }

  Future<ui.Image?> _captureBoundaryToImage() async {
    try {
      final RenderRepaintBoundary? boundary =
          _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(pixelRatio: 2.0);
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _captureSignature() async {
    final image = await _captureBoundaryToImage();
    if (image == null) return null;
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _submitCompletion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageBytesList.isEmpty) {
      context.showSnackBar('Please attach at least one proof of work photo', type: SnackBarType.warning);
      return;
    }
    if (_sigPoints.isEmpty) {
      context.showSnackBar('Please obtain the customer signature to complete the job', type: SnackBarType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final sigBytes = await _captureSignature();
      if (sigBytes == null) {
        context.showSnackBar('Failed to capture signature. Please draw again.', type: SnackBarType.error);
        setState(() => _isSubmitting = false);
        return;
      }

      final sigFileName = 'job_signature_${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}_signature.png';
      final sigUrl = await ref.read(jobsViewModelProvider).uploadJobImage(sigFileName, sigBytes);

      final imageUrls = await Future.wait(_imageBytesList.map((bytes) async {
        final idx = _imageBytesList.indexOf(bytes);
        final fileName = 'job_completion_${widget.jobId}_${DateTime.now().millisecondsSinceEpoch}_$idx.jpg';
        return await ref.read(jobsViewModelProvider).uploadJobImage(fileName, bytes);
      }));

      final allImages = [...imageUrls, sigUrl];

      await ref
          .read(jobsViewModelProvider)
          .completeJob(widget.jobId, _notesController.text.trim(), allImages);


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

  Future<void> _addPhoto(ImageSource source) async {
    setState(() => _isCapturing = true);
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytesList.add(bytes);
        });
        if (mounted) {
          context.showSnackBar('Photo added successfully', type: SnackBarType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Error picking photo: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(CupertinoIcons.camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.photo_on_rectangle),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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
                    if (_imageBytesList.isNotEmpty) ...[
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageBytesList.length,
                          itemBuilder: (context, idx) {
                            final bytes = _imageBytesList[idx];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      bytes,
                                      height: 120,
                                      width: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _imageBytesList.removeAt(idx);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.xmark,
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.checkmark_circle_fill,
                              size: 16, color: Color(0xFF2E7D32)),
                          const SizedBox(width: 8),
                          Text(
                            '${_imageBytesList.length} Photo${_imageBytesList.length > 1 ? 's' : ''} Attached (Compressed)',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
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
                        'Take photos of the completed work',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Multiple photos are allowed and auto-compressed',
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
                        onPressed: _isCapturing ? null : _showImageSourceActionSheet,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isCapturing
                              ? const SizedBox(
                                  key: ValueKey('capturing_icon'),
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(
                                  CupertinoIcons.camera,
                                  key: ValueKey('normal_icon'),
                                ),
                        ),
                        label: Text(
                          _isCapturing
                              ? 'Opening camera...'
                              : 'Add Proof Photo',
                          style: const TextStyle(fontWeight: FontWeight.w600),
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
              const SizedBox(height: 24),

              // Customer Signature section
              Text(
                'Customer Verification Signature',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              _RepaintBoundaryProvider(
                repaintKey: _repaintKey,
                child: SignaturePad(
                  points: _sigPoints,
                  onChanged: () => setState(() {}),
                ),
              ),
              const SizedBox(height: 32),

              // Submit button
              AnimatedTapScale(
                onTap: _isSubmitting
                    ? () {}
                    : () { _submitCompletion(); },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _isSubmitting || _imageBytesList.isEmpty || _sigPoints.isEmpty
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
              if (_imageBytesList.isEmpty || _sigPoints.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _imageBytesList.isEmpty
                      ? 'Add at least one photo to enable submission'
                      : 'Please obtain customer signature to enable submission',
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

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.points,
    required this.onChanged,
  });

  final List<Offset?> points;
  final VoidCallback onChanged;

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE0E0E0),
        ),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onPanUpdate: (details) {
              final RenderBox renderBox = context.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.globalPosition);
              if (localPos.dx >= 0 &&
                  localPos.dx <= renderBox.size.width &&
                  localPos.dy >= 0 &&
                  localPos.dy <= renderBox.size.height) {
                widget.points.add(localPos);
                widget.onChanged();
              }
            },
            onPanEnd: (_) {
              widget.points.add(null);
              widget.onChanged();
            },
            child: CustomPaint(
              painter: _SignaturePainter(
                points: widget.points,
                color: theme.colorScheme.onSurface,
              ),
              size: Size.infinite,
            ),
          ),
          if (widget.points.isEmpty)
            IgnorePointer(
              child: Center(
                child: Text(
                  'Customer Signature Required',
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 8,
            right: 8,
            child: TextButton.icon(
              icon: const Icon(CupertinoIcons.refresh, size: 12),
              label: const Text('Clear', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              onPressed: () {
                widget.points.clear();
                widget.onChanged();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.points, required this.color});

  final List<Offset?> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

