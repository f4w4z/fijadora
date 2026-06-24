import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../shared/widgets/animated_tap_scale.dart';
import 'appliance_detail_page.dart';

class HomeDetailListView extends StatelessWidget {
  const HomeDetailListView({super.key, required this.type});

  final String type;

  String get _title {
    switch (type) {
      case 'rooms':
        return 'Rooms';
      case 'appliances':
        return 'Appliances';
      case 'paint':
        return 'Paint Codes';
      case 'warranties':
        return 'Warranties';
      case 'history':
        return 'Maintenance History';
      default:
        return 'Details';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _getItems();

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No records found.',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24.0),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return AnimatedTapScale(
                  onTap: () {
                    if (type == 'appliances') {
                      _showApplianceDetail(context, item);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text('${item.title} detail sheet: ${item.subtitle.replaceAll('\n', ' ')}'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF222222)
                            : const Color(0xFFE5E5E5),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (item.icon != null) ...[
                          Icon(item.icon, color: theme.colorScheme.primary, size: 24),
                          const SizedBox(width: 16.0),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                item.subtitle,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item.statusText != null) ...[
                          const SizedBox(width: 12.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: item.statusColor?.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.statusText!.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: item.statusColor ?? Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<_DetailItem> _getItems() {
    switch (type) {
      case 'rooms':
        return [
          _DetailItem(title: 'Kitchen', subtitle: 'Ground floor, tiled, gas line hookup', icon: CupertinoIcons.square_grid_2x2),
          _DetailItem(title: 'Living Room', subtitle: 'Ground floor, solid oak hardwood flooring', icon: CupertinoIcons.square_grid_2x2),
          _DetailItem(title: 'Master Bedroom', subtitle: 'First floor, premium wool carpet, balcony access', icon: CupertinoIcons.square_grid_2x2),
          _DetailItem(title: 'Guest Bedroom', subtitle: 'First floor, standard carpet, built-in wardrobe', icon: CupertinoIcons.square_grid_2x2),
          _DetailItem(title: 'Home Office', subtitle: 'Ground floor, quiet zone, high-speed ethernet ports', icon: CupertinoIcons.square_grid_2x2),
          _DetailItem(title: 'Bathroom', subtitle: 'First floor, ventilation fan, bathtub', icon: CupertinoIcons.square_grid_2x2),
        ];
      case 'appliances':
        return [
          _DetailItem(
            title: 'Bosch Dishwasher',
            subtitle: 'Model: SHE3AR76UC | Kitchen',
            icon: CupertinoIcons.device_desktop,
            statusText: 'Healthy',
            statusColor: Colors.green,
          ),
          _DetailItem(
            title: 'Samsung Refrigerator',
            subtitle: 'Model: RF28T5001SR | Kitchen',
            icon: CupertinoIcons.device_desktop,
            statusText: 'Healthy',
            statusColor: Colors.green,
          ),
          _DetailItem(
            title: 'Carrier HVAC Condenser',
            subtitle: 'Model: 24ABB3 | Living Room Closet',
            icon: CupertinoIcons.device_desktop,
            statusText: 'Needs Service',
            statusColor: Colors.orange,
          ),
          _DetailItem(
            title: 'Whirlpool Front Load Washer',
            subtitle: 'Model: WFW5620HW | Laundry Room',
            icon: CupertinoIcons.device_desktop,
            statusText: 'Healthy',
            statusColor: Colors.green,
          ),
        ];
      case 'paint':
        return [
          _DetailItem(title: 'Living Room Walls', subtitle: 'Sherwin-Williams Extra White (SW 7006) | Satin Finish', icon: CupertinoIcons.paintbrush),
          _DetailItem(title: 'Master Bedroom Walls', subtitle: 'Benjamin Moore Classic Gray (OC-23) | Eggshell Finish', icon: CupertinoIcons.paintbrush),
          _DetailItem(title: 'Kitchen Backsplash Area', subtitle: 'Behr Ultra Pure White | Semi-Gloss Finish', icon: CupertinoIcons.paintbrush),
        ];
      case 'warranties':
        return [
          _DetailItem(
            title: 'Carrier HVAC Compressor',
            subtitle: 'Warranty ID: W-9988223\nActive Coverage till 12/08/2028',
            icon: CupertinoIcons.doc_text,
            statusText: 'Active',
            statusColor: Colors.green,
          ),
          _DetailItem(
            title: 'Bosch Dishwasher Heating Loop',
            subtitle: 'Warranty ID: W-1049281\nActive Coverage till 01/10/2027',
            icon: CupertinoIcons.doc_text,
            statusText: 'Active',
            statusColor: Colors.green,
          ),
          _DetailItem(
            title: 'Samsung Fridge Compressor',
            subtitle: 'Warranty ID: W-4493819\nActive Coverage till 15/05/2030',
            icon: CupertinoIcons.doc_text,
            statusText: 'Active',
            statusColor: Colors.green,
          ),
        ];
      case 'history':
        return [
          _DetailItem(
            title: 'CeLight Switch Repair',
            subtitle: '22/06/2026 | Replaced flickering rocker switch\nTechnician: Sarah Smith',
            icon: CupertinoIcons.clock,
            statusText: 'Completed',
            statusColor: Colors.green,
          ),
          _DetailItem(
            title: 'Kitchen Sink Leak Repair',
            subtitle: '20/06/2026 | Replaced broken washer & joint seal\nTechnician: Alex Johnson',
            icon: CupertinoIcons.clock,
            statusText: 'Completed',
            statusColor: Colors.green,
          ),
          _DetailItem(
            title: 'HVAC Seasonal Inspection',
            subtitle: '10/05/2025 | Cleaned air filters & vents\nTechnician: Alex Johnson',
            icon: CupertinoIcons.clock,
            statusText: 'Completed',
            statusColor: Colors.green,
          ),
        ];
      default:
        return [];
    }
  }

  void _showApplianceDetail(BuildContext context, _DetailItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApplianceDetailPage(
          title: item.title,
          subtitle: item.subtitle,
          statusText: item.statusText,
          statusColor: item.statusColor,
          icon: item.icon,
        ),
      ),
    );
  }
}

class _DetailItem {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? statusText;
  final Color? statusColor;

  _DetailItem({
    required this.title,
    required this.subtitle,
    this.icon,
    this.statusText,
    this.statusColor,
  });
}
