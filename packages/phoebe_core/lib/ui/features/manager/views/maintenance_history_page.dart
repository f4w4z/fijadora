import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MaintenanceHistoryPage extends StatelessWidget {
  const MaintenanceHistoryPage({
    super.key,
    required this.assetName,
    required this.history,
  });

  final String assetName;
  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = theme.brightness == Brightness.dark
        ? const Color(0xFF222222)
        : const Color(0xFFE5E5E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance History'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assetName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maintenance & repair history',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          Expanded(
            child: history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.archivebox,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No records found',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    itemCount: history.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item['date'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? const Color(0xFF1A1A1A)
                                        : const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: borderColor),
                                  ),
                                  child: Text(
                                    item['technician'] as String,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
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
        ],
      ),
    );
  }
}
