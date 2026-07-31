import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/models/collection.dart';
import '../../../../domain/models/collection_item.dart';
import '../../../../domain/models/product.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/app_animations.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../shop/view_models/products_provider.dart';
import '../../staff/view_models/admin_collections_view_model.dart';
import '../../services/service_constants.dart';

class CollectionFormPage extends ConsumerStatefulWidget {
  const CollectionFormPage({super.key, this.collection});

  final Collection? collection;

  @override
  ConsumerState<CollectionFormPage> createState() => _CollectionFormPageState();
}

class _CollectionFormPageState extends ConsumerState<CollectionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late CollectionCategory _selectedCategory;

  bool get _isEdit => widget.collection != null;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  final ImagePicker _picker = ImagePicker();

  final List<LookItemEntry> _items = [];
  int? _expandedItemIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.collection;
    _titleController = TextEditingController(text: c?.title ?? '');
    _descriptionController = TextEditingController(text: c?.description ?? '');
    _selectedCategory = c?.category ?? CollectionCategory.trending;

    if (c != null) {
      for (final item in c.items) {
        _items.add(LookItemEntry(
          label: item.label,
          subtitle: item.subtitle ?? '',
          imageUrl: item.imageUrl ?? '',
          referenceId: item.referenceId ?? '',
          itemType: item.itemType,
        ));
      }
    }

    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImageBytes = bytes;
        _pickedImageName = file.name;
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to select image: $e', type: SnackBarType.error);
      }
    }
  }

  void _addItem() {
    setState(() {
      _items.add(LookItemEntry(
        label: '',
        subtitle: '',
        imageUrl: '',
        referenceId: '',
        itemType: CollectionItemType.product,
      ));
      _expandedItemIndex = _items.length - 1;
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      if (_expandedItemIndex == index) {
        _expandedItemIndex = _items.isNotEmpty ? _items.length - 1 : null;
      } else if (_expandedItemIndex != null && _expandedItemIndex! > index) {
        _expandedItemIndex = _expandedItemIndex! - 1;
      }
    });
  }

  IconData _categoryIcon(CollectionCategory category) {
    switch (category) {
      case CollectionCategory.trending:
        return CupertinoIcons.flame_fill;
      case CollectionCategory.kitchen:
        return Icons.kitchen;
      case CollectionCategory.diy:
        return CupertinoIcons.hammer_fill;
      case CollectionCategory.seasonal:
        return CupertinoIcons.snow;
      case CollectionCategory.renovation:
        return CupertinoIcons.wrench_fill;
      case CollectionCategory.bathroom:
        return CupertinoIcons.drop_fill;
      case CollectionCategory.bedroom:
        return CupertinoIcons.bed_double_fill;
      case CollectionCategory.livingRoom:
        return CupertinoIcons.house_fill;
      case CollectionCategory.outdoor:
        return CupertinoIcons.tree;
      case CollectionCategory.energy:
        return CupertinoIcons.bolt_fill;
      case CollectionCategory.cleaning:
        return CupertinoIcons.wind;
      case CollectionCategory.organization:
        return CupertinoIcons.square_grid_2x2_fill;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = ref.watch(adminCollectionsViewModelProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Look' : 'Create Look',
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (vm.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoActivityIndicator(),
            )
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 140),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Cover Image Banner
                        _buildLabel('Cover Image'),
                        const SizedBox(height: 6),
                        _buildImagePickerBanner(theme),
                        const SizedBox(height: 24),

                        Text(
                          'Look Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Title'),
                        TextFormField(
                          controller: _titleController,
                          decoration: _inputDecoration('e.g. Cozy Minimalist Living Room', theme),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Description'),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration('Describe the look and style...', theme),
                          maxLines: 3,
                          minLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Category'),
                        const SizedBox(height: 6),
                        _buildCategorySelector(theme),
                        const SizedBox(height: 24),

                        const Divider(),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Text(
                              'Items in this Look',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(CupertinoIcons.add_circled, size: 22),
                              onPressed: _addItem,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No items yet. Tap + to add products to this look.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                        ...List.generate(_items.length, (idx) {
                          final entry = _items[idx];
                          final isLinked = entry.referenceId.isNotEmpty;
                          final isExpanded = _expandedItemIndex == idx;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      setState(() {
                                        _expandedItemIndex = isExpanded ? null : idx;
                                      });
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            'Item ${idx + 1}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        if (isLinked) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(CupertinoIcons.checkmark_seal_fill, size: 10, color: Colors.green),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Catalog Linked',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 9,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                                          size: 14,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(CupertinoIcons.minus_circle, size: 20, color: Colors.redAccent),
                                          onPressed: () => _removeItem(idx),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedSize(
                                    duration: AppDurations.normal,
                                    curve: AppCurves.defaultCurve,
                                    alignment: Alignment.topCenter,
                                    child: isExpanded
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const SizedBox(height: 12),
                                              if (productsAsync.isLoading) ...[
                                                _buildLabel('Loading products...'),
                                                const SizedBox(height: 4),
                                                const CupertinoActivityIndicator(),
                                                const SizedBox(height: 12),
                                              ] else if (productsAsync.hasValue) ...[
                                                _buildLabel('Link Product from Catalog'),
                                                const SizedBox(height: 4),
                                                _buildProductSelector(productsAsync.value!, idx),
                                                const SizedBox(height: 12),
                                              ],
                                              _buildLabel('Display Details'),
                                              const SizedBox(height: 4),
                                              TextFormField(
                                                key: ValueKey('label_$idx'),
                                                initialValue: entry.label,
                                                decoration: _inputDecoration('Product name', theme),
                                                onChanged: (v) => entry.label = v,
                                                textCapitalization: TextCapitalization.words,
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                key: ValueKey('subtitle_$idx'),
                                                initialValue: entry.subtitle,
                                                decoration: _inputDecoration('Brief description (e.g. GH₵49.00)', theme),
                                                onChanged: (v) => entry.subtitle = v,
                                                textCapitalization: TextCapitalization.sentences,
                                              ),
                                              const SizedBox(height: 8),
                                              TextFormField(
                                                key: ValueKey('imageUrl_$idx'),
                                                initialValue: entry.imageUrl,
                                                decoration: _inputDecoration('Image URL (optional)', theme),
                                                onChanged: (v) => entry.imageUrl = v,
                                              ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 32),
                        AnimatedTapScale(
                          onTap: _isSubmitting ? () {} : _saveCollection,
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.primary.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(27),
                            ),
                            alignment: Alignment.center,
                            child: vm.isLoading || _isSubmitting
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : Text(
                                    _isEdit ? 'Update Look' : 'Publish Look',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vm.isLoading || _isSubmitting)
            Container(
              color: Colors.black.withValues(alpha: 0.25),
              child: const Center(
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(radius: 14),
                        SizedBox(height: 16),
                        Text('Saving look...', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: CollectionCategory.values.length,
        itemBuilder: (context, index) {
          final cat = CollectionCategory.values[index];
          final isSelected = _selectedCategory == cat;
          final icon = _categoryIcon(cat);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedTapScale(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.defaultCurve,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 14,
                      color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat.displayName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductSelector(List<Product> products, int itemIndex) {
    final theme = Theme.of(context);
    final currentRefId = _items[itemIndex].referenceId;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isSelected = product.id == currentRefId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedTapScale(
              onTap: () {
                setState(() {
                  _items[itemIndex].referenceId = product.id;
                  _items[itemIndex].label = product.name;
                  _items[itemIndex].subtitle = formatGhs(product.price);
                  if (_items[itemIndex].imageUrl.isEmpty) {
                    _items[itemIndex].imageUrl = product.imageUrl;
                  }
                });
              },
              child: AnimatedContainer(
                duration: AppDurations.fast,
                curve: AppCurves.defaultCurve,
                width: 150,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        width: 38,
                        height: 38,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => Container(
                          color: Colors.grey.shade300,
                          child: const Icon(CupertinoIcons.photo, size: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatGhs(product.price),
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePickerBanner(ThemeData theme) {
    final hasImage = _pickedImageBytes != null || widget.collection?.coverImageUrl != null;

    return AnimatedTapScale(
      onTap: () => _showImageSourceBottomSheet(theme),
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_pickedImageBytes != null)
                Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
              else if (widget.collection?.coverImageUrl != null)
                CachedNetworkImage(
                  imageUrl: widget.collection!.coverImageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: theme.colorScheme.surfaceContainer),
                  errorWidget: (c, u, e) => const Center(
                    child: Icon(CupertinoIcons.photo, size: 48, color: Colors.grey),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.surfaceContainerLow,
                        theme.colorScheme.surfaceContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        size: 38,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to Upload Cover Image',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add a stunning cover to represent this look',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),

              if (hasImage)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                ),

              if (hasImage) ...[
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Cover Image Preview',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.camera_fill,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceBottomSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideTransition(
                  delay: Duration.zero,
                  offset: const Offset(0, 30),
                  child: Text(
                    'Select Cover Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 100),
                  offset: const Offset(0, 30),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.camera_fill, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 150),
                  offset: const Offset(0, 30),
                  child: const Divider(height: 1),
                ),
                FadeSlideTransition(
                  delay: const Duration(milliseconds: 200),
                  offset: const Offset(0, 30),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.photo_on_rectangle, color: theme.colorScheme.primary, size: 20),
                    ),
                    title: const Text('From Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, ThemeData theme) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerHigh,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
    );
  }

  Future<void> _saveCollection() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() != true) return;

    final viewModel = ref.read(adminCollectionsViewModelProvider.notifier);
    final user = ref.read(authViewModelProvider).user;
    if (user == null) {
      context.showSnackBar('User not found', type: SnackBarType.error);
      return;
    }

    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    String? coverImageUrl = widget.collection?.coverImageUrl;

    setState(() => _isSubmitting = true);
    try {
      if (_pickedImageBytes != null) {
        try {
          final fileName = _pickedImageName ?? 'cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
          coverImageUrl = await viewModel.uploadCoverImage(fileName, _pickedImageBytes!);
        } catch (e) {
          if (mounted) {
            context.showSnackBar('Image upload failed: $e', type: SnackBarType.error);
          }
          return;
        }
      }

      final items = _items
          .where((e) => e.label.trim().isNotEmpty)
          .map((e) => CollectionItem(
                id: '',
                itemType: e.itemType,
                referenceId: e.referenceId.isNotEmpty ? e.referenceId : null,
                label: e.label.trim(),
                subtitle: e.subtitle.trim().isNotEmpty ? e.subtitle.trim() : null,
                imageUrl: e.imageUrl.trim().isNotEmpty ? e.imageUrl.trim() : null,
              ))
          .toList();

      if (items.isEmpty) {
        if (mounted) {
          context.showSnackBar('Please add at least one product to this look.', type: SnackBarType.error);
        }
        return;
      }

      if (_isEdit) {
        await viewModel.editCollection(
          existingCollection: widget.collection!,
          title: title,
          description: description,
          coverImageUrl: coverImageUrl,
          category: _selectedCategory,
          items: items,
        );
        if (mounted) {
          context.showSnackBar('Look updated successfully', type: SnackBarType.success);
          Navigator.of(context).pop();
        }
      } else {
        await viewModel.createCollection(
          title: title,
          description: description,
          coverImageUrl: coverImageUrl,
          creatorId: user.id,
          creatorName: user.name,
          category: _selectedCategory,
          items: items,
        );
        if (mounted) {
          context.showSnackBar('Look created successfully', type: SnackBarType.success);
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Operation failed: $e', type: SnackBarType.error);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}

class LookItemEntry {
  String label;
  String subtitle;
  String imageUrl;
  String referenceId;
  CollectionItemType itemType;

  LookItemEntry({
    required this.label,
    required this.subtitle,
    required this.imageUrl,
    required this.referenceId,
    required this.itemType,
  });
}
