import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/models/collection.dart';
import '../../../../domain/models/collection_item.dart';
import '../../../../domain/models/product.dart';
import '../../../core/theme.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../shop/view_models/wishlist_view_model.dart';
import '../../staff/view_models/admin_collections_view_model.dart';

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
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = ref.watch(adminCollectionsViewModelProvider);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Look' : 'Create Look'),
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
          else
            TextButton(
              onPressed: _saveCollection,
              child: Text(
                'Save',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Look Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        DropdownButtonFormField<CollectionCategory>(
                          initialValue: _selectedCategory,
                          decoration: _inputDecoration('', theme),
                          items: CollectionCategory.values.map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.displayName))
                          ).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildLabel('Cover Image'),
                        const SizedBox(height: 4),
                        _buildImagePicker(theme),
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
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(CupertinoIcons.add_circled, size: 20),
                              onPressed: _addItem,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No items yet. Tap + to add products to this look.',
                                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ),

                        ...List.generate(_items.length, (idx) {
                          final entry = _items[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('Item ${idx + 1}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(CupertinoIcons.minus_circle, size: 18, color: Colors.redAccent),
                                        onPressed: () => _removeItem(idx),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: entry.label,
                                    decoration: _inputDecoration('Product name', theme),
                                    onChanged: (v) => entry.label = v,
                                    textCapitalization: TextCapitalization.words,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: entry.subtitle,
                                    decoration: _inputDecoration('Brief description', theme),
                                    onChanged: (v) => entry.subtitle = v,
                                    textCapitalization: TextCapitalization.sentences,
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    initialValue: entry.imageUrl,
                                    decoration: _inputDecoration('Image URL (optional)', theme),
                                    onChanged: (v) => entry.imageUrl = v,
                                  ),
                                  if (productsAsync.hasValue) ...[
                                    const SizedBox(height: 8),
                                    _buildProductSelector(productsAsync.value!, idx),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (vm.isLoading)
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

  Widget _buildProductSelector(List<Product> products, int itemIndex) {
    final theme = Theme.of(context);
    final currentRefId = _items[itemIndex].referenceId;

    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isSelected = product.id == currentRefId;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: AnimatedTapScale(
              onTap: () {
                setState(() {
                  _items[itemIndex].referenceId = product.id;
                  _items[itemIndex].label = product.name;
                  _items[itemIndex].subtitle = '\$${product.price.toStringAsFixed(2)}';
                  if (_items[itemIndex].imageUrl.isEmpty) _items[itemIndex].imageUrl = product.imageUrl;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                color: theme.colorScheme.surfaceContainer,
                child: _pickedImageBytes != null
                    ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                    : (widget.collection?.coverImageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.collection!.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => const Icon(CupertinoIcons.photo, size: 40),
                          )
                        : const Center(
                            child: Icon(CupertinoIcons.photo, size: 40, color: Colors.grey),
                          )),
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(CupertinoIcons.camera_fill, size: 18, color: theme.colorScheme.primary),
                    label: Text(
                      'Take Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(CupertinoIcons.photo_on_rectangle, size: 18, color: theme.colorScheme.primary),
                    label: Text(
                      'From Gallery',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      fillColor: theme.colorScheme.surfaceContainerLow,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1),
      ),
    );
  }

  Future<void> _saveCollection() async {
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

    try {
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
