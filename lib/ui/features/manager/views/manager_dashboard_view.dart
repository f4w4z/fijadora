import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import '../../../shared/widgets/custom_pinned_header.dart';
import '../../../shared/widgets/floating_header_layout.dart';
import 'maintenance_history_page.dart';

class ManagerDashboardView extends ConsumerStatefulWidget {
  const ManagerDashboardView({super.key});

  @override
  ConsumerState<ManagerDashboardView> createState() => _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends ConsumerState<ManagerDashboardView> {
  // Tracks which unit cards are expanded (key = "propId-unitNumber")
  final Set<String> _expandedUnits = {};

  final List<Map<String, dynamic>> _mockProperties = [
    {
      'id': 'prop-1',
      'name': 'Greenwood Apartments',
      'address': '742 Evergreen Terrace, Springfield',
      'units': [
        {
          'number': '302',
          'rooms': [
            {
              'name': 'Kitchen',
              'assets': [
                {'name': 'Bosch Dishwasher', 'type': 'Appliance', 'status': 'Healthy'},
                {'name': 'Samsung Refrigerator', 'type': 'Appliance', 'status': 'Healthy'},
              ]
            },
            {
              'name': 'Living Room',
              'assets': [
                {'name': 'Noguchi Coffee Table', 'type': 'Furniture', 'status': 'Good Condition'},
                {'name': 'Carrier AC Unit', 'type': 'Appliance', 'status': 'Needs Service'},
              ]
            }
          ]
        },
        {
          'number': '304',
          'rooms': [
            {
              'name': 'Kitchen',
              'assets': [
                {'name': 'Kitchen Sink Washer', 'type': 'Plumbing', 'status': 'Leaking'},
              ]
            }
          ]
        }
      ]
    },
    {
      'id': 'prop-2',
      'name': 'Oakwood Heights',
      'address': 'Apartment 4B, Oakwood Heights, NY',
      'units': [
        {
          'number': '4B',
          'rooms': [
            {
              'name': 'Kitchen',
              'assets': [
                {'name': 'Kitchen Sink Pipe', 'type': 'Plumbing', 'status': 'Repaired'},
              ]
            },
            {
              'name': 'Living Room',
              'assets': [
                {'name': 'Ceiling Light Switch', 'type': 'Electrical', 'status': 'Flickering'},
              ]
            }
          ]
        }
      ]
    }
  ];

  final Map<String, List<Map<String, dynamic>>> _mockHistory = {
    'Bosch Dishwasher': [
      {'date': '12/04/2026', 'action': 'Replaced heating element', 'technician': 'Alex Johnson'},
      {'date': '01/10/2025', 'action': 'Regular maintenance & cleaning', 'technician': 'Sarah Smith'},
    ],
    'Carrier AC Unit': [
      {'date': '15/06/2026', 'action': 'Compressor checked, diagnosed wear', 'technician': 'Alex Johnson'},
      {'date': '10/05/2025', 'action': 'Cleaned air filters', 'technician': 'Alex Johnson'},
    ],
    'Kitchen Sink Pipe': [
      {'date': '20/06/2026', 'action': 'Replaced broken washer and joint seal', 'technician': 'Alex Johnson'},
    ],
    'Ceiling Light Switch': [
      {'date': '22/06/2026', 'action': 'Replaced flickering rocker switch', 'technician': 'Sarah Smith'},
    ]
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final borderColor = theme.brightness == Brightness.dark
        ? const Color(0xFF222222)
        : const Color(0xFFE5E5E5);

    return Scaffold(
      body: FloatingHeaderLayout(
        header: CustomPinnedHeader(
          title: 'Properties',
          actions: [
            HeaderActionButton(
              icon: CupertinoIcons.square_arrow_right,
              onTap: () async => authViewModel.signOut(),
            ),
          ],
        ),
        bodyBuilder: (context, topPadding) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: topPadding)),
              SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final property = _mockProperties[index];
                  final propId = property['id'] as String;
                  final units = property['units'] as List;
                  final alertCount = _countAlerts(units);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: _PropertyCard(
                      property: property,
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
                          _showAssetHistorySheet(context, assetName),
                    ),
                  );
                },
                childCount: _mockProperties.length,
              ),
            ),
          ),
        ],
      );
    },
   ),
  );
 }

  int _countAlerts(List units) {
    int count = 0;
    for (final unit in units) {
      for (final room in unit['rooms'] as List) {
        for (final asset in room['assets'] as List) {
          final status = asset['status'] as String;
          if (!_isHealthy(status)) count++;
        }
      }
    }
    return count;
  }

  bool _isHealthy(String status) =>
      status == 'Healthy' || status == 'Good Condition' || status == 'Repaired';

  void _showAssetHistorySheet(BuildContext context, String assetName) {
    final history = _mockHistory[assetName] ?? [];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaintenanceHistoryPage(
          assetName: assetName,
          history: history,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.property,
    required this.propId,
    required this.alertCount,
    required this.borderColor,
    required this.expandedUnits,
    required this.onUnitToggle,
    required this.onAssetTap,
  });

  final Map<String, dynamic> property;
  final String propId;
  final int alertCount;
  final Color borderColor;
  final Set<String> expandedUnits;
  final void Function(String key) onUnitToggle;
  final void Function(String assetName) onAssetTap;

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
        ),
        const SizedBox(height: 12),
        ...units.map((unit) {
          final unitKey = '$propId-${unit['number']}';
          final isExpanded = expandedUnits.contains(unitKey);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UnitCard(
              unit: unit,
              unitKey: unitKey,
              isExpanded: isExpanded,
              borderColor: borderColor,
              onToggle: () => onUnitToggle(unitKey),
              onAssetTap: onAssetTap,
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
  });

  final Map<String, dynamic> property;
  final int alertCount;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Building icon pill
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
          if (alertCount > 0)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.2)),
              ),
              child: Text(
                '$alertCount alert${alertCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF3B30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({
    required this.unit,
    required this.unitKey,
    required this.isExpanded,
    required this.borderColor,
    required this.onToggle,
    required this.onAssetTap,
  });

  final Map<String, dynamic> unit;
  final String unitKey;
  final bool isExpanded;
  final Color borderColor;
  final VoidCallback onToggle;
  final void Function(String assetName) onAssetTap;

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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: Text(
                        unit['number'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Unit ${unit['number']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      CupertinoIcons.chevron_down,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
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
  });

  final List rooms;
  final Color borderColor;
  final void Function(String assetName) onAssetTap;

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
          ...rooms.map((room) {
            final assets = room['assets'] as List;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Room label
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        room['name'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Asset rows
                  ...assets.map((asset) {
                    final assetName = asset['name'] as String;
                    final assetStatus = asset['status'] as String;
                    final healthy = _isHealthy(assetStatus);
                    final statusColor = healthy
                        ? const Color(0xFF34C759)
                        : const Color(0xFFFF3B30);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AnimatedTapScale(
                        onTap: () => onAssetTap(assetName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
                                    Text(
                                      assetName,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      asset['type'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: statusColor.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  assetStatus.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                CupertinoIcons.time,
                                size: 15,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
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
        ],
      ),
    );
  }
}
