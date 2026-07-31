import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../../data/repositories/jobs_repository.dart';
import '../../../../data/repositories/properties_repository.dart';
import '../../../../data/repositories/users_repository.dart';
import '../../../../data/services/app_notification_service.dart';
import '../../../../domain/models/maintenance_job.dart';
import '../../../../domain/models/job_status.dart';
import '../../../../domain/models/property.dart';
import '../../../../domain/models/trade_type.dart';
import '../../../../domain/models/app_user.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../manager/views/maintenance_history_page.dart';
import '../../../core/utilities/responsive_helpers.dart';
import 'asset_form_dialog.dart';
import 'property_card.dart';


class ManagerPropertiesView extends ConsumerStatefulWidget {
  const ManagerPropertiesView({super.key});

  @override
  ConsumerState<ManagerPropertiesView> createState() => _ManagerPropertiesViewState();
}

class _ManagerPropertiesViewState extends ConsumerState<ManagerPropertiesView> {
  final Set<String> _expandedUnits = {};
  List<Map<String, dynamic>> _properties = [];
  ProviderSubscription<AsyncValue<List<Property>>>? _propertiesSub;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authViewModelProvider).user?.id ?? '';
    // Seed the first frame from the cached provider value (no re-fetch).
    ref.read(propertiesStreamProvider(userId)).whenData((props) {
      _properties = props.map(_propertyToMap).toList();
    });
    // Update via setState from an async listener so rebuilds never happen
    // during another widget's build scope (e.g. while a dialog keyboard
    // animates the viewport).
    _propertiesSub = ref.listenManual(
      propertiesStreamProvider(userId),
      (prev, next) {
        next.whenData((props) {
          if (mounted) {
            setState(() => _properties = props.map(_propertyToMap).toList());
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _propertiesSub?.close();
    super.dispose();
  }

  static Map<String, dynamic> _propertyToMap(Property p) => {
    'id': p.id,
    'name': p.name,
    'address': p.address,
    'units': p.units.map((u) => {
      'id': u.id,
      'number': u.number,
      'rooms': u.rooms.map((r) => {
        'id': r.id,
        'name': r.name,
        'assets': r.assets.map((a) => {
          'id': a.id,
          'name': a.name,
          'type': a.type,
          'status': a.status,
        }).toList(),
      }).toList(),
    }).toList(),
  };

  void _addProperty(String name, String address) async {
    final userId = ref.read(authViewModelProvider).user?.id ?? '';
    final property = Property(
      id: '',
      name: name,
      address: address,
      managerId: userId,
      createdAt: DateTime.now(),
      units: const [],
    );
    try {
      await ref.read(propertiesRepositoryProvider).createProperty(property);
      if (mounted) {
        context.showSnackBar('Property added successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add property: $e', type: SnackBarType.error);
      }
    }
  }

  void _editProperty(int index, String name, String address) async {
    final propertyMap = _properties[index];
    final propertyId = propertyMap['id'] as String;
    final userId = ref.read(authViewModelProvider).user?.id ?? '';
    final property = Property(
      id: propertyId,
      name: name,
      address: address,
      managerId: userId,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(propertiesRepositoryProvider).updateProperty(property);
      if (mounted) {
        context.showSnackBar('Property updated successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to update property: $e', type: SnackBarType.error);
      }
    }
  }

  void _deleteProperty(int index) async {
    final propertyMap = _properties[index];
    final propertyId = propertyMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).deleteProperty(propertyId);
      if (mounted) {
        context.showSnackBar('Property deleted successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to delete property: $e', type: SnackBarType.error);
      }
    }
  }

  void _addUnit(int propIndex, String number) async {
    final propertyMap = _properties[propIndex];
    final propertyId = propertyMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).addUnit(propertyId, number);
      if (mounted) {
        context.showSnackBar('Unit added successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add unit: $e', type: SnackBarType.error);
      }
    }
  }

  void _deleteUnit(int propIndex, int unitIndex) async {
    final propertyMap = _properties[propIndex];
    final propertyId = propertyMap['id'] as String;
    final unitMap = (propertyMap['units'] as List)[unitIndex];
    final unitId = unitMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).deleteUnit(propertyId, unitId);
      if (mounted) {
        context.showSnackBar('Unit deleted successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to delete unit: $e', type: SnackBarType.error);
      }
    }
  }

  void _addRoom(int propIndex, int unitIndex, String roomName) async {
    final propertyMap = _properties[propIndex];
    final propertyId = propertyMap['id'] as String;
    final unitMap = (propertyMap['units'] as List)[unitIndex];
    final unitId = unitMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).addRoom(propertyId, unitId, roomName);
      if (mounted) {
        context.showSnackBar('Room added successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add room: $e', type: SnackBarType.error);
      }
    }
  }

  void _addAsset(int propIndex, int unitIndex, int roomIndex, String name, String type, String status) async {
    final propertyMap = _properties[propIndex];
    final propertyId = propertyMap['id'] as String;
    final unitMap = (propertyMap['units'] as List)[unitIndex];
    final roomMap = (unitMap['rooms'] as List)[roomIndex];
    final roomId = roomMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).addAsset(propertyId, roomId, name, type, status);
      if (mounted) {
        context.showSnackBar('Asset added successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add asset: $e', type: SnackBarType.error);
      }
    }
  }

  void _editAsset(int propIndex, int unitIndex, int roomIndex, int assetIndex, String name, String type, String status) async {
    final propertyMap = _properties[propIndex];
    final propertyId = propertyMap['id'] as String;
    final unitMap = (propertyMap['units'] as List)[unitIndex];
    final roomMap = (unitMap['rooms'] as List)[roomIndex];
    final assetMap = (roomMap['assets'] as List)[assetIndex];
    final assetId = assetMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).updateAsset(propertyId, assetId, name, type, status);
      if (mounted) {
        context.showSnackBar('Asset updated successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to update asset: $e', type: SnackBarType.error);
      }
    }
  }

  void _deleteAsset(int propIndex, int unitIndex, int roomIndex, int assetIndex) async {
    final propertyMap = _properties[propIndex];
    final propertyId = propertyMap['id'] as String;
    final unitMap = (propertyMap['units'] as List)[unitIndex];
    final roomMap = (unitMap['rooms'] as List)[roomIndex];
    final assetMap = (roomMap['assets'] as List)[assetIndex];
    final assetId = assetMap['id'] as String;
    try {
      await ref.read(propertiesRepositoryProvider).deleteAsset(propertyId, assetId);
      if (mounted) {
        context.showSnackBar('Asset deleted successfully', type: SnackBarType.success);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to delete asset: $e', type: SnackBarType.error);
      }
    }
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
                maxLines: 3,
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
        assetId: asset['id'] as String?,
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
                                  child: PropertyCard(
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
                                    onAssetTap: (assetId, assetName) =>
                                        _showAssetHistorySheet(assetId, assetName),
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
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()), maxLines: 3),
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
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder()), maxLines: 3),
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
    AssetFormDialog.show(
      context,
      onSave: (name, type, status) {
        _addAsset(propIndex, unitIndex, roomIndex, name, type, status);
      },
    );
  }

  void _showEditAssetSheet(int propIndex, int unitIndex, int roomIndex, int assetIndex) {
    final units = _properties[propIndex]['units'] as List;
    final rooms = units[unitIndex]['rooms'] as List;
    final assets = rooms[roomIndex]['assets'] as List;
    final asset = assets[assetIndex];
    AssetFormDialog.show(
      context,
      initialName: asset['name'] as String,
      initialType: asset['type'] as String,
      initialStatus: asset['status'] as String,
      onSave: (name, type, status) {
        _editAsset(propIndex, unitIndex, roomIndex, assetIndex, name, type, status);
      },
    );
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

  void _showAssetHistorySheet(String assetId, String assetName) async {
    // Show loading indicator while we fetch real data from Supabase
    if (!mounted) return;
    final loadingSnack = ScaffoldMessenger.of(context);
    loadingSnack.showSnackBar(
      const SnackBar(content: Text('Loading history...'), duration: Duration(seconds: 10)),
    );

    try {
      final [jobs, workers] = await Future.wait([
        ref.read(jobsRepositoryProvider).fetchJobsForAsset(assetId: assetId),
        ref.read(workersProvider.future),
      ]);

      final assetJobs = jobs as List<MaintenanceJob>;
      final allWorkers = workers as List<AppUser>;

      final history = assetJobs.map((j) {
        final worker = allWorkers.cast<AppUser?>().firstWhere(
          (w) => w?.id == j.workerId,
          orElse: () => null,
        );
        final d = j.createdAt;
        final dateStr = '${d.month}/${d.day}/${d.year}';
        return {
          'date': dateStr,
          'technician': worker?.name ?? 'Assigned Technician',
          'action': j.description,
          'images': j.images,
        };
      }).toList();

      if (!mounted) return;
      loadingSnack.hideCurrentSnackBar();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MaintenanceHistoryPage(
            assetName: assetName,
            history: history,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      loadingSnack.hideCurrentSnackBar();
      context.showSnackBar('Failed to load history: $e', type: SnackBarType.error);
    }
  }
}
