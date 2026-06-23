import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/view_models/auth_view_model.dart';

class ManagerDashboardView extends ConsumerStatefulWidget {
  const ManagerDashboardView({super.key});

  @override
  ConsumerState<ManagerDashboardView> createState() => _ManagerDashboardViewState();
}

class _ManagerDashboardViewState extends ConsumerState<ManagerDashboardView> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Building Manager Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_right),
            onPressed: () async {
              await authViewModel.signOut();
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: _mockProperties.length,
        itemBuilder: (context, index) {
          final property = _mockProperties[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 24.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF222222)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Property Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        property['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        property['address'] as String,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF222222)
                      : const Color(0xFFE5E5E5),
                ),
                // Units list
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (property['units'] as List).length,
                  itemBuilder: (context, uIdx) {
                    final unit = property['units'][uIdx];
                    return ExpansionTile(
                      shape: const Border(),
                      title: Text(
                        'Unit ${unit['number']}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      children: (unit['rooms'] as List).map((room) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  room['name'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              ...(room['assets'] as List).map((asset) {
                                final assetName = asset['name'] as String;
                                final assetStatus = asset['status'] as String;
                                final isHealthy = assetStatus == 'Healthy' || assetStatus == 'Good Condition' || assetStatus == 'Repaired';

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                    side: BorderSide(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFF222222)
                                          : const Color(0xFFE5E5E5),
                                    ),
                                  ),
                                  elevation: 0,
                                  child: ListTile(
                                    title: Text(assetName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: Text(asset['type'] as String, style: const TextStyle(fontSize: 11)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isHealthy ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            assetStatus.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: isHealthy ? Colors.green : Colors.red,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(CupertinoIcons.info_circle, size: 16),
                                      ],
                                    ),
                                    onTap: () => _showAssetHistorySheet(context, assetName),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAssetHistorySheet(BuildContext context, String assetName) {
    final history = _mockHistory[assetName] ?? [];
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$assetName History',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Maintenance and repairs record.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: Text('No historical repairs recorded for this asset.')),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['date'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  'By: ${item['technician']}',
                                  style: TextStyle(color: theme.colorScheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['action'] as String,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
