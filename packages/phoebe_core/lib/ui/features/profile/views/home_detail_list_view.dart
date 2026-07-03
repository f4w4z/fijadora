import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/models/property.dart';

class HomeDetailListView extends ConsumerWidget {
  const HomeDetailListView({super.key, required this.type, this.property});

  final String type;
  final Property? property;

  String get _title {
    switch (type) {
      case 'rooms':
        return 'Rooms';
      case 'appliances':
        return 'Appliances';
      case 'history':
        return 'Maintenance History';
      default:
        return 'Details';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.tray_2, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No $_title available',
                style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
