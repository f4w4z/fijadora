import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LiveTrackingView extends StatelessWidget {
  const LiveTrackingView({super.key, required this.jobId, required this.address});

  final String jobId;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.map_pin_ellipse, size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(
                'Live tracking',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Technician location will appear here once they are en route to:\n$address',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
