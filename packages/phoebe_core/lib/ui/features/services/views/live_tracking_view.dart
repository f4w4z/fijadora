import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../shared/utils/notification_helper.dart';
import '../../../core/utilities/responsive_helpers.dart';

class LiveTrackingView extends StatefulWidget {
  const LiveTrackingView({super.key, required this.jobId, required this.address});

  final String jobId;
  final String address;

  @override
  State<LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<LiveTrackingView> {
  late final MapController _mapController;
  Timer? _movementTimer;
  int _currentStep = 0;
  int _etaMinutes = 12;

  // Mock path coordinates from Start point to Destination (NY coordinates)
  final List<LatLng> _routePoints = const [
    LatLng(40.7250, -74.0100),
    LatLng(40.7230, -74.0080),
    LatLng(40.7210, -74.0090),
    LatLng(40.7180, -74.0070),
    LatLng(40.7160, -74.0080),
    LatLng(40.7140, -74.0065),
    LatLng(40.7128, -74.0060), // Destination (Appt 4B / NY center)
  ];

  late LatLng _workerLocation;
  final LatLng _destinationLocation = const LatLng(40.7128, -74.0060);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _workerLocation = _routePoints[0];
    _startTechnicianMovement();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _startTechnicianMovement() {
    _movementTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;

      if (_currentStep < _routePoints.length - 1) {
        setState(() {
          _currentStep++;
          _workerLocation = _routePoints[_currentStep];
          if (_etaMinutes > 2) {
            _etaMinutes -= 2;
          } else {
            _etaMinutes = 1;
          }
        });
        
        // Auto-center map slightly ahead
        _mapController.move(_workerLocation, 14.5);
      } else {
        _movementTimer?.cancel();
        setState(() {
          _etaMinutes = 0;
        });
        context.showSnackBar('Technician has arrived at your location!', type: SnackBarType.info);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Technician', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Flutter Map view
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _workerLocation,
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.phoebehomes.app',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: theme.colorScheme.primary.withValues(alpha: 0.6),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Destination marker (Customer home)
                  Marker(
                    point: _destinationLocation,
                    width: 40,
                    height: 40,
                    child: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      radius: 20,
                      child: const Icon(CupertinoIcons.house_fill, color: Colors.white, size: 20),
                    ),
                  ),
                  // Worker location marker
                  Marker(
                    point: _workerLocation,
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Icon(CupertinoIcons.car_detailed, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Worker Details Card
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20.0,
                    spreadRadius: 4.0,
                  ),
                ],
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF222222)
                      : const Color(0xFFE5E5E5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with ETA
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estimated Arrival',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _etaMinutes > 0 ? '$_etaMinutes mins away' : 'Arrived',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: _etaMinutes > 0 ? theme.colorScheme.primary : Colors.green,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'EN ROUTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Divider(
                    height: 1,
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF222222)
                        : const Color(0xFFE5E5E5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Worker info row
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.indigo,
                        child: Text(
                          'AJ',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Alex Johnson',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(CupertinoIcons.star_fill, size: 12, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '4.9 (124 jobs) • Certified Plumber',
                                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'White Ford Transit (Plate: PH-992)',
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // CTA button
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.showSnackBar('Calling technician: +1 (555) 019-2831', type: SnackBarType.info);
                            },
                            icon: const Icon(CupertinoIcons.phone_fill, size: 16),
                            label: const Text('Call Staff', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: BorderSide(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF222222)
                                    : const Color(0xFFE5E5E5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
