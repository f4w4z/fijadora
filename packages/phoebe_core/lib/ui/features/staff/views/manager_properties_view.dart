import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/property.dart';
import '../../../../domain/models/trade_type.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../core/utilities/responsive_helpers.dart';


class ManagerPropertiesView extends ConsumerStatefulWidget {
  const ManagerPropertiesView({super.key});

  @override
  ConsumerState<ManagerPropertiesView> createState() => _ManagerPropertiesViewState();
}

class _ManagerPropertiesViewState extends ConsumerState<ManagerPropertiesView> {
  final Set<String> _expandedUnits = {};
  StreamSubscription<List<Property>>? _sub;
  List<Map<String, dynamic>> _properties = [];

  @override
  void initState() {
    super.initState();
    final repo = ref.read(propertiesRepositoryProvider);
    final userId = ref.read(authViewModelProvider).user?.id ?? '';
    _sub = repo.streamProperties(userId).listen((props) {
      if (!mounted) return;
      setState(() {
        _properties = props.map(_propertyToMap).toList();
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  static Map<String, dynamic> _propertyToMap(Property p) => {
    'id': p.id,
    'name': p.name,
    'address': p.address,
    'units': p.units.map((u) => {
      'number': u.number,
      'rooms': u.rooms.map((r) => {
        'name': r.name,
        'assets': r.assets.map((a) => {
          'name': a.name,
          'type': a.type,
          'status': a.status,
        }).toList(),
      }).toList(),
    }).toList(),
  };

  void _addProperty(String name, String address) {
    setState(() {
      _properties.add({
        'id': 'prop-${DateTime.now().millisecondsSinceEpoch}',
        'name': name,
        'address': address,
        'units': [],
      });
    });
  }

  void _editProperty(int index, String name, String address) {
    setState(() {
      _properties[index]['name'] = name;
      _properties[index]['address'] = address;
    });
  }

  void _deleteProperty(int index) {
    setState(() {
      _properties.removeAt(index);
    });
  }

  void _addUnit(int propIndex, String number) {
    setState(() {
      (_properties[propIndex]['units'] as List).add({
        'number': number,
        'rooms': [],
      });
    });
  }

  void _deleteUnit(int propIndex, int unitIndex) {
    setState(() {
      (_properties[propIndex]['units'] as List).removeAt(unitIndex);
    });
  }

  void _addRoom(int propIndex, int unitIndex, String roomName) {
    setState(() {
      final units = _properties[propIndex]['units'] as List;
      (units[unitIndex]['rooms'] as List).add({
        'name': roomName,
        'assets': [],
      });
    });
  }

  void _addAsset(int propIndex, int unitIndex, int roomIndex, String name, String type, String status) {
    setState(() {
      final units = _properties[propIndex]['units'] as List;
      final rooms = units[unitIndex]['rooms'] as List;
      (rooms[roomIndex]['assets'] as List).add({
        'name': name,
        'type': type,
        'status': status,
      });
    });
  }

  void _editAsset(int propIndex, int unitIndex, int roomIndex, int assetIndex, String name, String type, String status) {
    setState(() {
      final units = _properties[propIndex]['units'] as List;
      final rooms = units[unitIndex]['rooms'] as List;
      final assets = rooms[roomIndex]['assets'] as List;
      assets[assetIndex] = {'name': name, 'type': type, 'status': status};
    });
  }

  void _deleteAsset(int propIndex, int unitIndex, int roomIndex, int assetIndex) {
    setState(() {
      final units = _properties[propIndex]['units'] as List;
      final rooms = units[unitIndex]['rooms'] as List;
      final assets = rooms[roomIndex]['assets'] as List;
      assets.removeAt(assetIndex);
    });
  }

  Future<void> _triggerMaintenance(Map<String, dynamic> property, Map<String, dynamic> asset, String roomName, String unitNumber) async {
    final dispatchMode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dispatch Mode'),
        content: const Text('How should this job be dispatched?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'admin'),
            child: const Text('Admin Queue'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'open'),
            child: const Text('Open to Workers'),
          ),
        ],
      ),
    );
    if (dispatchMode == null || !mounted) return;

    final user = ref.read(authViewModelProvider).user;
    if (user == null) return;

    final descController = TextEditingController(
      text: '[${asset['type']}] ${asset['name']} — ${asset['status']} in $roomName, Unit $unitNumber',
    );
    final addressController = TextEditingController(text: property['address'] as String);

    try {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Raise Maintenance Job'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Property: ${property['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Asset: ${asset['name']} ($roomName, Unit $unitNumber)'),
              const SizedBox(height: 4),
              Text('Dispatch: ${dispatchMode == 'admin' ? 'Admin Queue' : 'Open to Workers'}'),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Issue Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Raise Job')),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

      final tradeType = _inferTradeType(asset['type'] as String);
      final job = MaintenanceJob(
        id: 'job-${DateTime.now().millisecondsSinceEpoch}',
        description: descController.text,
        tradeType: tradeType,
        status: JobStatus.pending,
        scheduleDateTime: DateTime.now().add(const Duration(hours: 2)),
        address: addressController.text,
        images: const [],
        customerId: user.id,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      try {
        await ref.read(jobsRepositoryProvider).createJob(job: job);
        ref.read(notificationServiceProvider).sendNotification(
          title: 'New Maintenance Request',
          body: '${property['name']}: ${asset['name']} needs ${tradeType.displayName.toLowerCase()} service',
        );
        if (mounted) {
          context.showSnackBar('Job raised for ${asset['name']} (${dispatchMode == 'admin' ? 'admin dispatch' : 'open to workers'})', type: SnackBarType.success);
        }
      } catch (e) {
        if (mounted) {
          context.showSnackBar('Failed to raise job: $e', type: SnackBarType.error);
        }
      }
    } finally {
      descController.dispose();
      addressController.dispose();
    }
  }

  TradeType _inferTradeType(String assetType) {
    switch (assetType) {
      case 'Plumbing': return TradeType.plumbing;
      case 'Electrical': return TradeType.electrical;
      case 'HVAC': return TradeType.acEngineering;
      case 'Appliance': return TradeType.electrical;
      case 'Furniture': return TradeType.interiorDesign;
      default: return TradeType.plumbing;
    }
  }

  bool _isHealthy(String status) =>
      status == 'Healthy' || status == 'Good Condition' || status == 'Repaired';

  int _countAlerts(List units) {
    int count = 0;
    for (final unit in units) {
      for (final room in unit['rooms'] as List) {
        for (final asset in room['assets'] as List) {
          if (!_isHealthy(asset['status'] as String)) count++;
        }
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark
        ? const Color(0xFF222222)
        : const Color(0xFFE5E5E5);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.md, context.pagePad, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Properties', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5, color: theme.colorScheme.onSurface)),
                  ),
                  AnimatedTapScale(
                    onTap: () => _showAddPropertySheet(),
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
              child: _properties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.building_2_fill, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                          const SizedBox(height: 12),
                          Text('No properties yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showAddPropertySheet(),
                            icon: const Icon(CupertinoIcons.add, size: 16),
                            label: const Text('Add Property'),
                          ),
                        ],
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(context.pagePad, AppSpacing.sm, context.pagePad, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final property = _properties[index];
                                final propId = property['id'] as String;
                                final units = property['units'] as List;
                                final alertCount = _countAlerts(units);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _PropertyCard(
                                    property: property,
                                    propIndex: index,
                                    propId: propId,
                                    alertCount: alertCount,
                                    borderColor: borderColor,
                                    expandedUnits: _expandedUnits,
                                    onUnitToggle: (key) {
                                      setState(() {
                                        if (_expandedUnits.contains(key)) {
                                          _expandedUnits.remove(key);
                                        } else {
                                          _expandedUnits.add(key);
                                        }
                                      });
                                    },
                                    onAssetTap: (assetName) =>
                                        _showAssetHistorySheet(assetName),
                                    onEditProperty: () => _showEditPropertySheet(index),
                                    onDeleteProperty: () => _confirmDeleteProperty(index),
                                    onAddUnit: () => _showAddUnitSheet(index),
                                    onDeleteUnit: (unitIndex) => _confirmDeleteUnit(index, unitIndex),
                                    onAddRoom: (unitIndex) => _showAddRoomSheet(index, unitIndex),
                                    onAddAsset: (unitIndex, roomIndex) => _showAddAssetSheet(index, unitIndex, roomIndex),
                                    onEditAsset: (unitIndex, roomIndex, assetIndex) =>
                                        _showEditAssetSheet(index, unitIndex, roomIndex, assetIndex),
                                    onDeleteAsset: (unitIndex, roomIndex, assetIndex) =>
                                        _confirmDeleteAsset(index, unitIndex, roomIndex, assetIndex),
                                    onTriggerMaintenance: (unitNumber, roomName, asset) =>
                                        _triggerMaintenance(property, asset, roomName, unitNumber),
                                  ),
                                );
                              },
                              childCount: _properties.length,
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

  void _showAddPropertySheet() {
    final nameCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Property Name', border: OutlineInputBorder()), autofocus: true),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              _addProperty(nameCtrl.text.trim(), addrCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      addrCtrl.dispose();
    });
  }

  void _showEditPropertySheet(int index) {
    final prop = _properties[index];
    final nameCtrl = TextEditingController(text: prop['name'] as String);
    final addrCtrl = TextEditingController(text: prop['address'] as String);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Property'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Property Name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              _editProperty(index, nameCtrl.text.trim(), addrCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) {
      nameCtrl.dispose();
      addrCtrl.dispose();
    });
  }

  void _confirmDeleteProperty(int index) {
    final prop = _properties[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: Text('Remove "${prop['name']}" and all its units?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { _deleteProperty(index); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddUnitSheet(int propIndex) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Unit'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Unit Number', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              _addUnit(propIndex, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  void _confirmDeleteUnit(int propIndex, int unitIndex) {
    final unit = (_properties[propIndex]['units'] as List)[unitIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Unit'),
        content: Text('Remove Unit ${unit['number']} and all its rooms?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { _deleteUnit(propIndex, unitIndex); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddRoomSheet(int propIndex, int unitIndex) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Room'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Room Name', border: OutlineInputBorder()), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              _addRoom(propIndex, unitIndex, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ).then((_) => ctrl.dispose());
  }

  void _showAddAssetSheet(int propIndex, int unitIndex, int roomIndex) {
    final nameCtrl = TextEditingController();
    String type = 'Appliance';
    String status = 'Healthy';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder()), autofocus: true),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: ['Appliance', 'Furniture', 'Plumbing', 'Electrical', 'HVAC'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) { if (v != null) setDialogState(() => type = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['Healthy', 'Good Condition', 'Needs Service', 'Leaking', 'Flickering', 'Repaired'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { if (v != null) setDialogState(() => status = v); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                _addAsset(propIndex, unitIndex, roomIndex, nameCtrl.text.trim(), type, status);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    ).then((_) => nameCtrl.dispose());
  }

  void _showEditAssetSheet(int propIndex, int unitIndex, int roomIndex, int assetIndex) {
    final units = _properties[propIndex]['units'] as List;
    final rooms = units[unitIndex]['rooms'] as List;
    final assets = rooms[roomIndex]['assets'] as List;
    final asset = assets[assetIndex];
    final nameCtrl = TextEditingController(text: asset['name'] as String);
    String type = asset['type'] as String;
    String status = asset['status'] as String;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Asset'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Asset Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: ['Appliance', 'Furniture', 'Plumbing', 'Electrical', 'HVAC'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) { if (v != null) setDialogState(() => type = v); },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                items: ['Healthy', 'Good Condition', 'Needs Service', 'Leaking', 'Flickering', 'Repaired'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) { if (v != null) setDialogState(() => status = v); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                _editAsset(propIndex, unitIndex, roomIndex, assetIndex, nameCtrl.text.trim(), type, status);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    ).then((_) => nameCtrl.dispose());
  }

  void _confirmDeleteAsset(int propIndex, int unitIndex, int roomIndex, int assetIndex) {
    final units = _properties[propIndex]['units'] as List;
    final rooms = units[unitIndex]['rooms'] as List;
    final assets = rooms[roomIndex]['assets'] as List;
    final asset = assets[assetIndex];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Asset'),
        content: Text('Remove "${asset['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { _deleteAsset(propIndex, unitIndex, roomIndex, assetIndex); Navigator.pop(ctx); },
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAssetHistorySheet(String assetName) {
    context.showSnackBar('Maintenance history coming soon', type: SnackBarType.info);
  }
}

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.propIndex,
    required this.propId,
    required this.alertCount,
    required this.borderColor,
    required this.expandedUnits,
    required this.onUnitToggle,
    required this.onAssetTap,
    required this.onEditProperty,
    required this.onDeleteProperty,
    required this.onAddUnit,
    required this.onDeleteUnit,
    required this.onAddRoom,
    required this.onAddAsset,
    required this.onEditAsset,
    required this.onDeleteAsset,
    required this.onTriggerMaintenance,
  });

  final Map<String, dynamic> property;
  final int propIndex;
  final String propId;
  final int alertCount;
  final Color borderColor;
  final Set<String> expandedUnits;
  final void Function(String key) onUnitToggle;
  final void Function(String assetName) onAssetTap;
  final VoidCallback onEditProperty;
  final VoidCallback onDeleteProperty;
  final VoidCallback onAddUnit;
  final void Function(int unitIndex) onDeleteUnit;
  final void Function(int unitIndex) onAddRoom;
  final void Function(int unitIndex, int roomIndex) onAddAsset;
  final void Function(int unitIndex, int roomIndex, int assetIndex) onEditAsset;
  final void Function(int unitIndex, int roomIndex, int assetIndex) onDeleteAsset;
  final void Function(String unitNumber, String roomName, Map<String, dynamic> asset) onTriggerMaintenance;

  @override
  Widget build(BuildContext context) {
    final units = property['units'] as List;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PropertyHeader(
          property: property,
          alertCount: alertCount,
          borderColor: borderColor,
          onEdit: onEditProperty,
          onDelete: onDeleteProperty,
          onAddUnit: onAddUnit,
        ),
        const SizedBox(height: 12),
        ...units.asMap().entries.map((entry) {
          final unitIndex = entry.key;
          final unit = entry.value;
          final unitKey = '$propId-${unit['number']}';
          final isExpanded = expandedUnits.contains(unitKey);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UnitCard(
              unit: unit,
              unitIndex: unitIndex,
              unitKey: unitKey,
              isExpanded: isExpanded,
              borderColor: borderColor,
              onToggle: () => onUnitToggle(unitKey),
              onDelete: () => onDeleteUnit(unitIndex),
              onAddRoom: () => onAddRoom(unitIndex),
              onAssetTap: onAssetTap,
              onAddAsset: (roomIndex) => onAddAsset(unitIndex, roomIndex),
              onEditAsset: (roomIndex, assetIndex) => onEditAsset(unitIndex, roomIndex, assetIndex),
              onDeleteAsset: (roomIndex, assetIndex) => onDeleteAsset(unitIndex, roomIndex, assetIndex),
              onTriggerMaintenance: (roomName, asset) => onTriggerMaintenance(unit['number'] as String, roomName, asset),
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PropertyHeader extends StatelessWidget {
  const _PropertyHeader({
    required this.property,
    required this.alertCount,
    required this.borderColor,
    required this.onEdit,
    required this.onDelete,
    required this.onAddUnit,
  });

  final Map<String, dynamic> property;
  final int alertCount;
  final Color borderColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddUnit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              CupertinoIcons.building_2_fill,
              size: 18,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  property['address'] as String,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          AnimatedTapScale(
            onTap: onAddUnit,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(CupertinoIcons.add, size: 16, color: theme.colorScheme.primary),
            ),
          ),
          const SizedBox(width: 4),
          if (alertCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
              ),
              child: Text(
                '$alertCount alert${alertCount > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.error),
              ),
            ),
          PopupMenuButton<String>(
            iconSize: 18,
            icon: Icon(CupertinoIcons.ellipsis, color: theme.colorScheme.onSurfaceVariant),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [Icon(CupertinoIcons.pencil, size: 16), SizedBox(width: 8), Text('Edit')])),
              const PopupMenuItem(value: 'delete', child: Row(children: [Icon(CupertinoIcons.trash, size: 16), SizedBox(width: 8), Text('Delete')])),
            ],
          ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.unitIndex,
    required this.unitKey,
    required this.isExpanded,
    required this.borderColor,
    required this.onToggle,
    required this.onDelete,
    required this.onAddRoom,
    required this.onAssetTap,
    required this.onAddAsset,
    required this.onEditAsset,
    required this.onDeleteAsset,
    required this.onTriggerMaintenance,
  });

  final Map<String, dynamic> unit;
  final int unitIndex;
  final String unitKey;
  final bool isExpanded;
  final Color borderColor;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onAddRoom;
  final void Function(String assetName) onAssetTap;
  final void Function(int roomIndex) onAddAsset;
  final void Function(int roomIndex, int assetIndex) onEditAsset;
  final void Function(int roomIndex, int assetIndex) onDeleteAsset;
  final void Function(String roomName, Map<String, dynamic> asset) onTriggerMaintenance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rooms = unit['rooms'] as List;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          AnimatedTapScale(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(unit['number'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Unit ${unit['number']}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  AnimatedTapScale(
                    onTap: onDelete,
                    child: Icon(CupertinoIcons.trash, size: 14, color: theme.colorScheme.error.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(CupertinoIcons.chevron_down, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _UnitRoomsSection(
              rooms: rooms,
              borderColor: borderColor,
              onAssetTap: onAssetTap,
              onAddRoom: onAddRoom,
              onAddAsset: onAddAsset,
              onEditAsset: onEditAsset,
              onDeleteAsset: onDeleteAsset,
              onTriggerMaintenance: onTriggerMaintenance,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

class _UnitRoomsSection extends StatelessWidget {
  const _UnitRoomsSection({
    required this.rooms,
    required this.borderColor,
    required this.onAssetTap,
    required this.onAddRoom,
    required this.onAddAsset,
    required this.onEditAsset,
    required this.onDeleteAsset,
    required this.onTriggerMaintenance,
  });

  final List rooms;
  final Color borderColor;
  final void Function(String assetName) onAssetTap;
  final VoidCallback onAddRoom;
  final void Function(int roomIndex) onAddAsset;
  final void Function(int roomIndex, int assetIndex) onEditAsset;
  final void Function(int roomIndex, int assetIndex) onDeleteAsset;
  final void Function(String roomName, Map<String, dynamic> asset) onTriggerMaintenance;

  bool _isHealthy(String status) =>
      status == 'Healthy' || status == 'Good Condition' || status == 'Repaired';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flatBgColor = theme.brightness == Brightness.dark
        ? const Color(0xFF161616)
        : const Color(0xFFF9F9F9);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: borderColor),
          const SizedBox(height: 12),
          ...rooms.asMap().entries.map((entry) {
            final roomIndex = entry.key;
            final room = entry.value;
            final assets = room['assets'] as List;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(room['name'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.3)),
                      const Spacer(),
                      AnimatedTapScale(
                        onTap: () => onAddAsset(roomIndex),
                        child: Icon(CupertinoIcons.add_circled, size: 16, color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...assets.asMap().entries.map((aEntry) {
                    final assetIndex = aEntry.key;
                    final asset = aEntry.value as Map<String, dynamic>;
                    final assetName = asset['name'] as String;
                    final assetStatus = asset['status'] as String;
                    final healthy = _isHealthy(assetStatus);
                    final statusColor = healthy ? const Color(0xFF34C759) : theme.colorScheme.error;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => onAssetTap(assetName),
                        onLongPress: () => _showAssetActions(context, asset, room['name'] as String, roomIndex, assetIndex, healthy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: flatBgColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(assetName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    const SizedBox(height: 1),
                                    Text(asset['type'] as String, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  assetStatus.toUpperCase(),
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(CupertinoIcons.time, size: 15, color: theme.colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          AnimatedTapScale(
            onTap: onAddRoom,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 14, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Text('Add Room', style: TextStyle(fontSize: 12, color: theme.colorScheme.primary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAssetActions(BuildContext context, Map<String, dynamic> asset, String roomName, int roomIndex, int assetIndex, bool healthy) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(asset['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(CupertinoIcons.pencil),
              title: const Text('Edit'),
              onTap: () { Navigator.pop(ctx); onEditAsset(roomIndex, assetIndex); },
            ),
            ListTile(
              leading: Icon(CupertinoIcons.time, color: healthy ? null : theme.colorScheme.error),
              title: Text('Maintenance History', style: TextStyle(color: healthy ? null : theme.colorScheme.error)),
              onTap: () { Navigator.pop(ctx); onAssetTap(asset['name'] as String); },
            ),
            if (!healthy)
              ListTile(
                leading: Icon(CupertinoIcons.wrench, color: theme.colorScheme.error),
                title: Text('Trigger Maintenance', style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
                onTap: () { Navigator.pop(ctx); onTriggerMaintenance(roomName, asset); },
              ),
            ListTile(
              leading: Icon(CupertinoIcons.trash, color: theme.colorScheme.error),
              title: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
              onTap: () { Navigator.pop(ctx); onDeleteAsset(roomIndex, assetIndex); },
            ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
