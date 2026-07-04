import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import 'unit_card.dart';

class PropertyCard extends StatelessWidget {
  const PropertyCard({
    super.key,
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
  final void Function(String assetId, String assetName) onAssetTap;
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
            child: UnitCard(
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
      child: MergeSemantics(
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
      ),
    );
  }
}
