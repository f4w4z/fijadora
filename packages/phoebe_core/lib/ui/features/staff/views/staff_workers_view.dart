import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../ui/shared/utils/notification_helper.dart';
import '../../../../ui/shared/widgets/animated_tap_scale.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/app_user.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/notification_service.dart';

class StaffWorkersView extends ConsumerStatefulWidget {
  const StaffWorkersView({super.key});

  @override
  ConsumerState<StaffWorkersView> createState() => _StaffWorkersViewState();
}

class _StaffWorkersViewState extends ConsumerState<StaffWorkersView> {
  final List<Map<String, dynamic>> _teamWorkers = [
    {'name': 'Alex Johnson', 'specialty': 'Electrical', 'rating': 4.8, 'available': true, 'vehicle': 'White Ford Transit'},
    {'name': 'Sarah Smith', 'specialty': 'Plumbing', 'rating': 4.9, 'available': true, 'vehicle': 'Blue Ram ProMaster'},
    {'name': 'Mike Chen', 'specialty': 'HVAC', 'rating': 4.7, 'available': false, 'vehicle': 'Silver Mercedes Sprinter'},
    {'name': 'James Wilson', 'specialty': 'General', 'rating': 4.5, 'available': true, 'vehicle': 'Red Chevy Express'},
  ];

  void _addWorker(String name, String specialty) {
    setState(() {
      _teamWorkers.add({
        'name': name,
        'specialty': specialty,
        'rating': 5.0,
        'available': true,
        'vehicle': '',
      });
    });
  }

  void _toggleAvailability(int index) {
    setState(() {
      _teamWorkers[index]['available'] = !(_teamWorkers[index]['available'] as bool);
    });
  }

  void _deleteWorker(int index) {
    setState(() {
      _teamWorkers.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Workers', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                  ),
                  AnimatedTapScale(
                    onTap: () => _showAddWorkerSheet(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(CupertinoIcons.add, color: theme.colorScheme.primary, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildWorkerList(theme, borderColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerList(ThemeData theme, Color borderColor) {
    final authWorkers = ref.watch(authRepositoryProvider).getAllWorkers();
    final pending = authWorkers.where((w) => w.workerStatus == 'pending').toList();
    final approved = authWorkers.where((w) => w.workerStatus == 'approved').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
      children: [
        if (pending.isNotEmpty) ...[
          Row(
            children: [
              Text('Pending Approvals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE65100).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${pending.length}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...pending.map((worker) => _PendingWorkerCard(worker: worker)),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Text('Team', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
            if (approved.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('${approved.length} approved', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (approved.isNotEmpty)
          ...approved.map((worker) => _ApprovedAuthWorkerCard(worker: worker)),
        ..._teamWorkers.asMap().entries.map((entry) {
          final index = entry.key;
          final worker = entry.value;
          return _TeamWorkerCard(
            worker: worker,
            theme: theme,
            borderColor: borderColor,
            onToggle: () => _toggleAvailability(index),
            onDelete: () => _confirmDeleteWorker(index),
          );
        }),
        if (approved.isEmpty && _teamWorkers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.person_3_fill, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('No workers yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _showAddWorkerSheet(),
                    icon: const Icon(CupertinoIcons.add, size: 16),
                    label: const Text('Add Worker'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showAddWorkerSheet() {
    final nameCtrl = TextEditingController();
    String specialty = 'Electrical';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Worker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Worker Name', border: OutlineInputBorder()), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: specialty,
                decoration: const InputDecoration(labelText: 'Specialty', border: OutlineInputBorder()),
                items: TradeType.values.map((t) => DropdownMenuItem(value: t.displayName, child: Text(t.displayName))).toList(),
                onChanged: (v) { if (v != null) setDialogState(() => specialty = v); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                _addWorker(nameCtrl.text.trim(), specialty);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteWorker(int index) {
    final worker = _teamWorkers[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Worker'),
        content: Text('Remove ${worker['name']} from the team?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { _deleteWorker(index); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _PendingWorkerCard extends ConsumerWidget {
  const _PendingWorkerCard({required this.worker});
  final AppUser worker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE65100).withValues(alpha: 0.1),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100), fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(worker.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('PENDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFFE65100))),
          ),
          const SizedBox(width: 8),
          AnimatedTapScale(
            onTap: () => _approve(context, ref),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF34C759).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.checkmark_alt, size: 18, color: Color(0xFF34C759)),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedTapScale(
            onTap: () => _reject(context, ref),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(CupertinoIcons.xmark, size: 18, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _approve(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).updateWorkerStatus(userId: worker.id, status: 'approved');
    ref.read(notificationServiceProvider).sendNotification(
      title: 'Worker Approved',
      body: '${worker.name} can now access the worker app.',
    );
    if (context.mounted) {
      context.showSnackBar('${worker.name} approved', type: SnackBarType.success);
    }
  }

  void _reject(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).updateWorkerStatus(userId: worker.id, status: 'rejected');
    if (context.mounted) {
      context.showSnackBar('${worker.name} rejected', type: SnackBarType.error);
    }
  }
}

class _ApprovedAuthWorkerCard extends StatelessWidget {
  const _ApprovedAuthWorkerCard({required this.worker});
  final AppUser worker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark ? const Color(0xFF222222) : const Color(0xFFE5E5E5);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              worker.name.isNotEmpty ? worker.name[0].toUpperCase() : 'W',
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(worker.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 2),
                Text(worker.email, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF34C759).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('APPROVED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF34C759))),
          ),
        ],
      ),
    );
  }
}

class _TeamWorkerCard extends StatelessWidget {
  const _TeamWorkerCard({
    required this.worker,
    required this.theme,
    required this.borderColor,
    required this.onToggle,
    required this.onDelete,
  });

  final Map<String, dynamic> worker;
  final ThemeData theme;
  final Color borderColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              (worker['name'] as String)[0],
              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(worker['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: (worker['available'] as bool ? const Color(0xFF34C759) : theme.colorScheme.error).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        worker['available'] as bool ? 'Available' : 'Busy',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: worker['available'] as bool ? const Color(0xFF34C759) : theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('${worker['specialty']}  •  ★ ${worker['rating']}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                if ((worker['vehicle'] as String).isNotEmpty)
                  Text(worker['vehicle'] as String, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
              ],
            ),
          ),
          PopupMenuButton<String>(
            iconSize: 18,
            icon: Icon(CupertinoIcons.ellipsis, color: theme.colorScheme.onSurfaceVariant),
            onSelected: (value) {
              if (value == 'toggle') onToggle();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'toggle',
                child: Row(children: [
                  Icon(worker['available'] as bool ? CupertinoIcons.pause_circle : CupertinoIcons.play_circle, size: 16),
                  const SizedBox(width: 8),
                  Text(worker['available'] as bool ? 'Mark Busy' : 'Mark Available'),
                ]),
              ),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(CupertinoIcons.trash, size: 16), SizedBox(width: 8), Text('Remove')])),
            ],
          ),
        ],
      ),
    );
  }
}
