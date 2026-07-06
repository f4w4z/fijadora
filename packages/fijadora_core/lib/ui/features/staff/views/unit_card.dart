import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/animated_tap_scale.dart';

class UnitCard extends StatelessWidget {
  const UnitCard({
    super.key,
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
  final void Function(String assetId, String assetName) onAssetTap;
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
  final void Function(String assetId, String assetName) onAssetTap;
  final VoidCallback onAddRoom;
  final void Function(int roomIndex) onAddAsset;
  final void Function(int roomIndex, int assetIndex) onEditAsset;
  final void Function(int roomIndex, int assetIndex) onDeleteAsset;
  final void Function(String roomName, Map<String, dynamic> asset) onTriggerMaintenance;

  static bool _isHealthy(String status) =>
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
                        onTap: () => onAssetTap(asset['id'] as String, assetName),
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
              onTap: () { Navigator.pop(ctx); onAssetTap(asset['id'] as String, asset['name'] as String); },
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
