import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/repositories/item_request_repository.dart';
import '../../../core/utilities/responsive_helpers.dart';

class NewItemRequestView extends ConsumerStatefulWidget {
  const NewItemRequestView({super.key});

  @override
  ConsumerState<NewItemRequestView> createState() => _NewItemRequestViewState();
}

class _NewItemRequestViewState extends ConsumerState<NewItemRequestView> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final image = await _picker.pickImage(source: source, imageQuality: 60);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imageName = 'req_${DateTime.now().millisecondsSinceEpoch}.jpg';
      });
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    if (title.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in title and description')));
      return;
    }
    setState(() => _submitting = true);
    try {
      String? imageUrl;
      if (_imageBytes != null && _imageName != null) {
        imageUrl = await ref.read(itemRequestRepositoryProvider).uploadRequestImage(_imageName!, _imageBytes!);
      }
      await ref.read(itemRequestRepositoryProvider).createRequest(
            title: title,
            description: desc,
            category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
            imageUrl: imageUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showMaterialBanner(
          MaterialBanner(
            content: const Text('Request submitted! We\'ll notify you if this product becomes available.'),
            leading: const Icon(CupertinoIcons.bell_fill),
            actions: [
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request an Item')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(context.pagePad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                builder: (c) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(CupertinoIcons.camera),
                        title: const Text('Take a photo'),
                        onTap: () {
                          Navigator.of(c).pop();
                          _pick(ImageSource.camera);
                        },
                      ),
                      ListTile(
                        leading: const Icon(CupertinoIcons.photo),
                        title: const Text('Choose from gallery'),
                        onTap: () {
                          Navigator.of(c).pop();
                          _pick(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover, width: double.infinity, height: 180),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.camera_fill, size: 36, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text('Add a photo of the item',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
              ),
            ),
            if (_imageBytes != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _imageBytes = null),
                  icon: const Icon(CupertinoIcons.delete, size: 16),
                  label: const Text('Remove photo'),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'What do you need?', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Describe it', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting ? const CircularProgressIndicator() : const Text('Submit Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
