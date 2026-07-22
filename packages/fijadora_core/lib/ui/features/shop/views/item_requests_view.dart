import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/repositories/item_request_repository.dart';
import '../../../../domain/models/item_request.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/error_state_widget.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../core/utilities/responsive_helpers.dart';

final itemRequestsStreamProvider = StreamProvider<List<ItemRequest>>((ref) {
  return ref.watch(itemRequestRepositoryProvider).streamCustomerRequests();
});

class ItemRequestsView extends ConsumerWidget {
  const ItemRequestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final requestsAsync = ref.watch(itemRequestsStreamProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewItemRequestView()),
        ),
        icon: const Icon(CupertinoIcons.plus),
        label: const Text('Request Item'),
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: 'Could not load your requests.',
          onRetry: () => ref.invalidate(itemRequestsStreamProvider),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return const EmptyStateWidget(
              icon: CupertinoIcons.search,
              title: 'No requests yet',
              message: 'Can\'t find something in the shop? Request it here.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(context.pagePad),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _RequestCard(request: requests[index]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final ItemRequest request;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (request.status) {
      ItemRequestStatus.open => theme.colorScheme.primary,
      ItemRequestStatus.reviewing => Colors.orange,
      ItemRequestStatus.fulfilled => Colors.green,
      ItemRequestStatus.rejected => theme.colorScheme.error,
      ItemRequestStatus.closed => theme.colorScheme.onSurfaceVariant,
    };
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(request.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              StatusPill(label: request.status.label, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(request.description,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4)),
          const SizedBox(height: 10),
          Text('${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}

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
      if (mounted) Navigator.of(context).pop();
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
