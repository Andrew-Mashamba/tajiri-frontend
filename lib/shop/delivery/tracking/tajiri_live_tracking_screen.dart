// Tajiri Live Tracking Screen — buyer/seller view of a delivery in progress.
//
// Shows a full-screen Google Map with:
//   • Green pickup marker
//   • Red dropoff marker
//   • Animated driver marker (from Firebase Realtime DB stream)
// A bottom status timeline shows the current delivery phase.
// Job status is polled from backend every 20 s.
// A success overlay appears when delivery is confirmed.

import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_config.dart';
import '../driver/services/driver_service.dart';
import '../models/tajiri_delivery_models.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kGreen = Color(0xFF2E7D32);

class TajiriLiveTrackingScreen extends StatefulWidget {
  final int jobId;
  final int? driverId;
  final String dropoffAddress;
  final String? authToken;

  const TajiriLiveTrackingScreen({
    super.key,
    required this.jobId,
    required this.driverId,
    required this.dropoffAddress,
    required this.authToken,
  });

  @override
  State<TajiriLiveTrackingScreen> createState() =>
      _TajiriLiveTrackingScreenState();
}

class _TajiriLiveTrackingScreenState extends State<TajiriLiveTrackingScreen> {
  // Map
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Job state
  TajiriDeliveryJob? _job;
  bool _loadingJob = true;
  bool _delivered = false;

  // Driver location from Firebase
  StreamSubscription<DatabaseEvent>? _driverLocSub;
  DriverLocationUpdate? _driverLoc;

  // Polling timer
  Timer? _pollTimer;

  static const Duration _pollInterval = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _fetchJobStatus();
    _startPolling();
    if (widget.driverId != null) {
      _subscribeDriverLocation(widget.driverId!);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _driverLocSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Firebase driver location ────────────────────────────────────

  void _subscribeDriverLocation(int driverId) {
    final ref = FirebaseDatabase.instance.ref('driver_locations/$driverId');
    _driverLocSub = ref.onValue.listen((event) {
      if (!mounted) return;
      final data = event.snapshot.value;
      if (data == null) return;
      try {
        final map = Map<Object?, Object?>.from(data as Map);
        final loc = DriverLocationUpdate.fromMap(map);
        setState(() => _driverLoc = loc);
        _rebuildMarkers();
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(loc.lat, loc.lng)),
        );
      } catch (_) {}
    });
  }

  // ─── Job status polling ──────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchJobStatus());
  }

  Future<void> _fetchJobStatus() async {
    try {
      if (ApiConfig.useGraphqlBackend) {
        final job = await DriverService.getJobStatus(widget.jobId);
        if (!mounted) return;
        if (job != null) {
          setState(() {
            _job = job;
            _loadingJob = false;
            if (job.isDelivered) _delivered = true;
          });
          _rebuildMarkers();
          if (job.driverId != null && _driverLocSub == null) {
            _subscribeDriverLocation(job.driverId!);
          }
        } else if (mounted) {
          setState(() => _loadingJob = false);
        }
        return;
      }

      final token = widget.authToken;
      final headers = token != null
          ? ApiConfig.authHeaders(token)
          : ApiConfig.headers;

      final res = await http
          .get(
            Uri.parse(
              '${ApiConfig.baseUrl}/tajiri-delivery/jobs/${widget.jobId}/status',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (res.statusCode == 200 && json['success'] == true) {
        final data = json['data'] as Map<String, dynamic>?;
        if (data != null) {
          final job = TajiriDeliveryJob.fromJson(data);
          setState(() {
            _job = job;
            _loadingJob = false;
            if (job.isDelivered) _delivered = true;
          });
          _rebuildMarkers();

          // Subscribe driver location if we now have a driverId
          if (job.driverId != null && _driverLocSub == null) {
            _subscribeDriverLocation(job.driverId!);
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loadingJob = false);
    }
  }

  // ─── Markers ────────────────────────────────────────────────────

  void _rebuildMarkers() {
    final markers = <Marker>{};

    final job = _job;
    if (job != null) {
      if (job.pickupLat != null && job.pickupLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(job.pickupLat!, job.pickupLng!),
          infoWindow:
              InfoWindow(title: 'Pickup', snippet: job.pickupAddress),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
      }
      if (job.dropoffLat != null && job.dropoffLng != null) {
        markers.add(Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(job.dropoffLat!, job.dropoffLng!),
          infoWindow:
              InfoWindow(title: 'Dropoff', snippet: job.dropoffAddress),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }
    }

    final loc = _driverLoc;
    if (loc != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: LatLng(loc.lat, loc.lng),
        infoWindow:
            InfoWindow(title: job?.driverName ?? 'Driver'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        rotation: loc.heading,
        flat: true,
      ));
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });
    }
  }

  // ─── Phone call ──────────────────────────────────────────────────

  Future<void> _callDriver() async {
    final phone = _job?.driverPhone;
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // ─── UI ──────────────────────────────────────────────────────────

  LatLng get _initialCamera {
    if (_job?.dropoffLat != null) {
      return LatLng(_job!.dropoffLat!, _job!.dropoffLng!);
    }
    return const LatLng(-6.7924, 39.2083); // Dar es Salaam
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Track Delivery',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kDivider),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialCamera,
                zoom: 13,
              ),
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (c) => _mapController = c,
            ),
            // Bottom panel
            DraggableScrollableSheet(
              initialChildSize: 0.38,
              minChildSize: 0.28,
              maxChildSize: 0.7,
              builder: (_, ctrl) => _TrackingPanel(
                job: _job,
                loading: _loadingJob,
                dropoffAddress: widget.dropoffAddress,
                onCallDriver: _callDriver,
                scrollController: ctrl,
              ),
            ),
            // Delivered overlay
            if (_delivered) _DeliveredOverlay(onDismiss: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

// ─── Tracking Panel ────────────────────────────────────────────────────────

class _TrackingPanel extends StatelessWidget {
  final TajiriDeliveryJob? job;
  final bool loading;
  final String dropoffAddress;
  final VoidCallback onCallDriver;
  final ScrollController scrollController;

  const _TrackingPanel({
    required this.job,
    required this.loading,
    required this.dropoffAddress,
    required this.onCallDriver,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(blurRadius: 16, color: Colors.black12, spreadRadius: 1),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              ),
            )
          else ...[
            // Status timeline
            _StatusTimeline(status: job?.status ?? 'pending'),
            const SizedBox(height: 20),
            // Driver info
            if (job?.driverName != null)
              _DriverInfoCard(
                job: job!,
                onCallDriver: onCallDriver,
              ),
            if (job?.driverName == null)
              _SearchingCard(dropoffAddress: dropoffAddress),
          ],
        ],
      ),
    );
  }
}

// ─── Status Timeline ───────────────────────────────────────────────────────

class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  static const _steps = [
    ('pending', 'Searching'),
    ('assigned', 'Assigned'),
    ('picked_up', 'Picked Up'),
    ('in_transit', 'In Transit'),
    ('delivered', 'Delivered'),
  ];

  int get _currentIndex {
    switch (status) {
      case 'pending':
        return 0;
      case 'assigned':
      case 'en_route_pickup':
        return 1;
      case 'picked_up':
        return 2;
      case 'in_transit':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _steps[current].$2,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final stepIdx = (i - 1) ~/ 2;
              final filled = stepIdx < current;
              return Expanded(
                child: Container(
                  height: 2,
                  color: filled ? _kPrimary : _kDivider,
                ),
              );
            } else {
              // Step dot
              final stepIdx = i ~/ 2;
              final done = stepIdx < current;
              final active = stepIdx == current;
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? _kPrimary : _kDivider,
                  border: active
                      ? Border.all(color: _kPrimary, width: 2)
                      : null,
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _steps
              .map(
                (s) => Text(
                  s.$2,
                  style: const TextStyle(fontSize: 9, color: _kTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DriverInfoCard extends StatelessWidget {
  final TajiriDeliveryJob job;
  final VoidCallback onCallDriver;

  const _DriverInfoCard({required this.job, required this.onCallDriver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFE0E0E0),
            child: Icon(Icons.person_rounded, color: _kSecondary, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  job.driverName ?? 'Driver',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (job.vehicleType != null)
                  Text(
                    job.vehicleType!,
                    style:
                        const TextStyle(fontSize: 13, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (job.vehiclePlate != null)
                  Text(
                    job.vehiclePlate!,
                    style:
                        const TextStyle(fontSize: 13, color: _kTertiary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onCallDriver,
              child: const Icon(
                Icons.phone_rounded,
                color: _kPrimary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingCard extends StatelessWidget {
  final String dropoffAddress;
  const _SearchingCard({required this.dropoffAddress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Looking for a driver nearby…',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                Text(
                  dropoffAddress,
                  style: const TextStyle(fontSize: 12, color: _kTertiary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Delivered Overlay ────────────────────────────────────────────────────

class _DeliveredOverlay extends StatelessWidget {
  final VoidCallback onDismiss;
  const _DeliveredOverlay({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: _kGreen,
                  size: 72,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Package Delivered!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your order has been successfully\ndelivered to the destination.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: _kSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
