import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    final isOffline = status.valueOrNull == ConnectivityStatus.disconnected;

    return AnimatedSlide(
      offset: isOffline ? Offset.zero : const Offset(0, -1),
      duration: const Duration(milliseconds: 250),
      child: AnimatedOpacity(
        opacity: isOffline ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: isOffline
            ? Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'You are offline — showing cached data',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
