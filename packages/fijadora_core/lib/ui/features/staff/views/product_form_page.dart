import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../domain/models/product.dart';
import '../../../core/theme.dart';
import '../../../core/utilities/responsive_helpers.dart';
import '../../../shared/utils/notification_helper.dart';
import '../view_models/admin_products_view_model.dart';
import 'admin_products_view.dart';
import '../../services/service_constants.dart';

// â”€â”€â”€ Interactive Product Upload & Editing Page â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ProductFormPage extends ConsumerStatefulWidget {
  const ProductFormPage({super.key, this.product});

  final Product? product;

  @override
  ConsumerState<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends ConsumerState<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageUrlController;
  late TextEditingController _categoryController;

  // Track dynamic list of alternative images (each can be a picked file or existing URL)
  final List<({Uint8List? bytes, String? fileName, String? existingUrl})> _altImages = [];

  bool _isSubmitting = false;
  bool get _isEdit => widget.product != null;

  Uint8List? _pickedImageBytes;
  String? _pickedImageName;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAltImage(ImageSource source, int index) async {
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
        _altImages[index] = (bytes: bytes, fileName: file.name, existingUrl: null);
      });
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to select image: $e', type: SnackBarType.error);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _priceController = TextEditingController(text: p?.price != null ? p!.price.toStringAsFixed(2) : '');
    _stockController = TextEditingController(text: p?.inventoryCount != null ? p!.inventoryCount.toString() : '1');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');
    _categoryController = TextEditingController(text: p?.category ?? 'Lighting');

    if (p != null && p.imageUrls.isNotEmpty) {
      // populate alt images from existing URLs
      for (final alt in p.imageUrls) {
        if (alt != p.imageUrl) {
          _altImages.add((bytes: null, fileName: null, existingUrl: alt));
        }
      }
    }

    // Set listeners on controllers to rebuild/refresh preview card on text changes
    _nameController.addListener(() => setState(() {}));
    _priceController.addListener(() => setState(() {}));
    _stockController.addListener(() => setState(() {}));
    _imageUrlController.addListener(() => setState(() {}));
    _categoryController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _addAltField() {
    setState(() {
      _altImages.add((bytes: null, fileName: null, existingUrl: null));
    });
  }

  void _removeAltField(int index) {
    setState(() {
      _altImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = ref.watch(adminProductsViewModelProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Upload Product'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.clear),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (vm.isLoading || _isSubmitting)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoActivityIndicator(),
            )
          else
            TextButton(
              onPressed: _saveProduct,
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
                  // Live card preview header
                  Text(
                    'Live Preview (Store Card View)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 12),

                  // Live Preview Card
                  _buildLivePreviewCard(theme, isDark),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Form details
                  Text(
                    'Product details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name
                        _buildLabel('Product Name'),
                        TextFormField(
                          controller: _nameController,
                          decoration: _inputDecoration('Enter product name', theme),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Category & Price
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('Category'),
                                  DropdownButtonFormField<String>(
                                    initialValue: AdminProductsView.categories.contains(_categoryController.text) ? _categoryController.text : 'Lighting',
                                    decoration: _inputDecoration('', theme),
                                    items: AdminProductsView.categories
                                        .where((c) => c != 'All')
                                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        _categoryController.text = val;
                                        setState(() {});
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(r'Price ($)'),
                                  TextFormField(
                                    controller: _priceController,
                                    decoration: _inputDecoration('0.00', theme),
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                                    ],
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Required';
                                      final parsed = double.tryParse(v);
                                      if (parsed == null || parsed <= 0) return 'Invalid price';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stock
                        _buildLabel('Stock Inventory Count'),
                        TextFormField(
                          controller: _stockController,
                          decoration: _inputDecoration('How many units available', theme),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final parsed = int.tryParse(v);
                            if (parsed == null || parsed < 0) return 'Invalid count';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Description
                        _buildLabel('Product Description'),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _inputDecoration('Provide size, materials, details...', theme),
                          maxLines: 4,
                          minLines: 2,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Description is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Main Image Picker
                        _buildLabel('Product Image'),
                        const SizedBox(height: 4),
                        _buildImagePickerSelector(theme),
                        const SizedBox(height: 24),

                        // Alternative Images (camera/gallery pickers)
                        Row(
                          children: [
                            Text(
                              'Alternative Product Images (Optional)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(CupertinoIcons.add_circled, size: 20),
                              onPressed: _addAltField,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ...List.generate(_altImages.length, (idx) {
                          final alt = _altImages[idx];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Container(
                              height: 110,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                child: Row(
                                  children: [
                                    // Thumbnail
                                    Expanded(
                                      flex: 3,
                                      child: Container(
                                        color: theme.colorScheme.surfaceContainer,
                                        child: alt.bytes != null
                                            ? Image.memory(alt.bytes!, fit: BoxFit.cover)
                                            : (alt.existingUrl != null
                                                ? CachedNetworkImage(
                                                    imageUrl: alt.existingUrl!,
                                                    fit: BoxFit.cover,
                                                    errorWidget: (c, u, e) => const Icon(CupertinoIcons.photo, size: 28, color: Colors.grey),
                                                  )
                                                : const Center(child: Icon(CupertinoIcons.photo, size: 28, color: Colors.grey))),
                                      ),
                                    ),
                                    const VerticalDivider(width: 1),
                                    // Picker buttons + remove
                                    Expanded(
                                      flex: 5,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              TextButton.icon(
                                                onPressed: () => _pickAltImage(ImageSource.camera, idx),
                                                icon: Icon(CupertinoIcons.camera_fill, size: 15, color: theme.colorScheme.primary),
                                                label: Text('Camera', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                              ),
                                              TextButton.icon(
                                                onPressed: () => _pickAltImage(ImageSource.gallery, idx),
                                                icon: Icon(CupertinoIcons.photo_on_rectangle, size: 15, color: theme.colorScheme.primary),
                                                label: Text('Gallery', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                                              ),
                                            ],
                                          ),
                                          TextButton.icon(
                                            onPressed: () => _removeAltField(idx),
                                            icon: const Icon(CupertinoIcons.minus_circle, size: 14, color: Colors.redAccent),
                                            label: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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
                        Text('Saving product details...', style: TextStyle(fontWeight: FontWeight.w600)),
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

  Widget _buildLivePreviewCard(ThemeData theme, bool isDark) {
    final name = _nameController.text.trim().isEmpty ? 'Product Name' : _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final double price = priceText.isNotEmpty ? (double.tryParse(priceText) ?? 0.0) : 0.0;

    final stockText = _stockController.text.trim();
    final int stock = stockText.isNotEmpty ? (int.tryParse(stockText) ?? 0) : 0;
    final bool outOfStock = stock <= 0;

    Widget imageWidget;
    if (_pickedImageBytes != null) {
      imageWidget = Image.memory(_pickedImageBytes!, fit: BoxFit.cover);
    } else if (_imageUrlController.text.trim().isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: _imageUrlController.text.trim(),
        fit: BoxFit.cover,
        placeholder: (c, u) => Container(color: theme.colorScheme.surfaceContainerLow),
        errorWidget: (context, url, err) => _buildImagePlaceholder(theme),
      );
    } else {
      imageWidget = _buildImagePlaceholder(theme);
    }

    // Mirrors the customer-facing shop grid card (see shop_tab_view.dart).
    return Center(
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 0.82,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    if (outOfStock)
                      Container(color: Colors.black.withValues(alpha: 0.45)),
                    if (outOfStock)
                      const Center(
                        child: Text(
                          'Out of Stock',
                          style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                        child: Icon(CupertinoIcons.add, size: 14, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            Text(
              name,
              style: TextStyle(fontSize: 16, height: 1.1, color: theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              formatGhs(price),
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerSelector(ThemeData theme) {
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
            // Image Preview (Picked or Existing)
            Expanded(
              flex: 4,
              child: Container(
                color: theme.colorScheme.surfaceContainer,
                child: _pickedImageBytes != null
                    ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                    : (_imageUrlController.text.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: _imageUrlController.text.trim(),
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => const Icon(CupertinoIcons.photo, size: 40),
                          )
                        : const Center(
                            child: Icon(CupertinoIcons.photo, size: 40, color: Colors.grey),
                          )),
              ),
            ),
            const VerticalDivider(width: 1),
            // Picker Buttons
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

  Widget _buildImagePlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CupertinoIcons.photo, size: 36, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No image selected',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_isSubmitting) return;
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSubmitting = true);

    final viewModel = ref.read(adminProductsViewModelProvider.notifier);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.parse(_stockController.text.trim());
    final category = _categoryController.text.trim();

    String imageUrl = _imageUrlController.text.trim();

    if (_pickedImageBytes != null) {
      try {
        final fileName = _pickedImageName ?? 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        imageUrl = await viewModel.uploadImage(fileName, _pickedImageBytes!);
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Image upload failed: $e', type: SnackBarType.error);
        }
        return;
      }
    } else if (!_isEdit && imageUrl.isEmpty) {
      context.showSnackBar('Please capture or select a product image', type: SnackBarType.error);
      return;
    }

    // Upload any alt images that were picked as files, then build full list
    final imageUrls = <String>[imageUrl];
    for (int i = 0; i < _altImages.length; i++) {
      final alt = _altImages[i];
      if (alt.bytes != null) {
        try {
          final fileName = alt.fileName ?? 'alt_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          final altUrl = await viewModel.uploadImage(fileName, alt.bytes!);
          if (!imageUrls.contains(altUrl)) imageUrls.add(altUrl);
        } catch (e) {
          if (mounted) {
            context.showSnackBar('Alt image $i upload failed: $e', type: SnackBarType.error);
          }
          return;
        }
      } else if (alt.existingUrl != null && !imageUrls.contains(alt.existingUrl)) {
        imageUrls.add(alt.existingUrl!);
      }
    }

    try {
      if (_isEdit) {
        await viewModel.editProduct(
          existingProduct: widget.product!,
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          imageUrls: imageUrls,
          category: category,
          inventoryCount: stock,
        );
        if (mounted) {
          context.showSnackBar('Product updated successfully', type: SnackBarType.success);
          Navigator.of(context).pop();
        }
      } else {
        await viewModel.addProduct(
          name: name,
          description: description,
          price: price,
          imageUrl: imageUrl,
          imageUrls: imageUrls,
          category: category,
          inventoryCount: stock,
        );
        if (mounted) {
          context.showSnackBar('Product uploaded successfully', type: SnackBarType.success);
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
