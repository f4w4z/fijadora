import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { connected, disconnected }

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) {
  final connectivity = Connectivity();

  final controller = StreamController<ConnectivityStatus>.broadcast();

  void emitStatus(List<ConnectivityResult> results) {
    final isConnected = results.any(
      (r) => r != ConnectivityResult.none,
    );
    controller.add(
      isConnected ? ConnectivityStatus.connected : ConnectivityStatus.disconnected,
    );
  }

  final sub = connectivity.onConnectivityChanged.listen(emitStatus);

  connectivity.checkConnectivity().then(emitStatus);

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

