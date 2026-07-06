import 'package:flutter/material.dart';

class AssetFormDialog {
  static Future<void> show(
    BuildContext context, {
    required void Function(String name, String type, String status) onSave,
    String? initialName,
    String? initialType,
    String? initialStatus,
  }) async {
    final nameCtrl = TextEditingController(text: initialName);
    String type = initialType ?? 'Appliance';
    String status = initialStatus ?? 'Healthy';
    final isEdit = initialName != null;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Asset' : 'Add Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder()),
                autofocus: !isEdit,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: ['Appliance', 'Furniture', 'Plumbing', 'Electrical', 'HVAC']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['Healthy', 'Good Condition', 'Needs Service', 'Leaking', 'Flickering', 'Repaired']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => status = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                onSave(nameCtrl.text.trim(), type, status);
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
  }
}
