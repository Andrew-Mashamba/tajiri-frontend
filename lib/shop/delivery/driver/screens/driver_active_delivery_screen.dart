// Driver Active Delivery Screen — full-screen map + bottom sheet
// shown while the driver is carrying out a delivery.
//
// GPS is streamed via geolocator; position is pushed to backend every 30 s.
// Status actions (Confirm Pickup / Confirm Delivery) are sent via DriverService.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/tajiri_delivery_models.dart';
import '../services/driver_service.dart';

// ─── Design tokens ─────────────────────────────────────────────────────────
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kGreen = Color(0xFF2E7D32);

class DriverActiveDeliveryScreen extends StatefulWidget {
  final TajiriDeliveryJob job;
  final int userId;
  final String token;

  const DriverActiveDeliveryScreen({
    super.key,
    required this.job,
    required this.userId,
    required this.token,
  });

  @override
  State<DriverActiveDeliveryScreen> createState() =>
      _DriverActiveDeliveryScreenState();
}

class _DriverActiveDeliveryScreenState
    extends State<DriverActiveDeliveryScreen> {
  // Map
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Current job (updated after status changes)
  late TajiriDeliveryJob _job;

  // Location tracking
  StreamSubscription<Position>? _positionSub;
  LatLng? _driverLatLng;
  DateTime? _lastLocationPush;
  bool _actioning = false;
  bool _codCashCollected = false;

  static const Duration _locationPushInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _job = widget.job;
    _codCashCollected = _job.codCashCollected;
    _buildMarkers();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ─── Markers ────────────────────────────────────────────────────

  void _buildMarkers() {
    final markers = <Marker>{};

    if (_job.pickupLat != null && _job.pickupLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(_job.pickupLat!, _job.pickupLng!),
        infoWindow: InfoWindow(title: 'Pickup', snippet: _job.pickupAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }

    if (_job.dropoffLat != null && _job.dropoffLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('dropoff'),
        position: LatLng(_job.dropoffLat!, _job.dropoffLng!),
        infoWindow:
            InfoWindow(title: 'Dropoff', snippet: _job.dropoffAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    if (_driverLatLng != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverLatLng!,
        infoWindow: const InfoWindow(title: 'You'),
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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

  // ─── Location tracking ───────────────────────────────────────────

  Future<void> _startLocationTracking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _driverLatLng = latLng);
      _buildMarkers();
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));

      // Push to backend every 30 s
      final now = DateTime.now();
      if (_lastLocationPush == null ||
          now.difference(_lastLocationPush!) >= _locationPushInterval) {
        _lastLocationPush = now;
        DriverService.updateLocation(
          widget.token,
          widget.userId,
          pos.latitude,
          pos.longitude,
          pos.heading,
        );
      }
    });
  }

  // ─── Status actions ──────────────────────────────────────────────

  Future<void> _confirmPickup() async {
    setState(() => _actioning = true);
    final ok = await DriverService.confirmPickup(
      widget.token,
      widget.userId,
      _job.id,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _job = TajiriDeliveryJob(
            id: _job.id,
            jobNumber: _job.jobNumber,
            status: 'picked_up',
            driverId: _job.driverId,
            pickupName: _job.pickupName,
            pickupPhone: _job.pickupPhone,
            pickupAddress: _job.pickupAddress,
            pickupLat: _job.pickupLat,
            pickupLng: _job.pickupLng,
            dropoffName: _job.dropoffName,
            dropoffPhone: _job.dropoffPhone,
            dropoffAddress: _job.dropoffAddress,
            dropoffLat: _job.dropoffLat,
            dropoffLng: _job.dropoffLng,
            quotedPriceTzs: _job.quotedPriceTzs,
            weightKg: _job.weightKg,
            itemValueTzs: _job.itemValueTzs,
            notes: _job.notes,
            driverName: _job.driverName,
            driverPhone: _job.driverPhone,
            vehicleType: _job.vehicleType,
            vehiclePlate: _job.vehiclePlate,
          ));
      _showSnack('Pickup confirmed!');
    } else {
      _showSnack('Failed to confirm pickup — try again');
    }
    if (mounted) setState(() => _actioning = false);
  }

  Future<void> _collectCash() async {
    final amount = _job.orderTotalTzs > 0 ? _job.orderTotalTzs : _job.itemValueTzs;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Collect Cash'),
        content: Text(
          'Confirm you collected TZS ${amount.toStringAsFixed(0)} from the customer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, collected'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actioning = true);
    final ok = await DriverService.collectCashPayment(
      _job.id,
      amount,
      widget.token,
      userId: widget.userId,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _codCashCollected = true);
      _showSnack('Cash collected! You can now confirm delivery.');
    } else {
      _showSnack('Failed to record cash collection — try again');
    }
    setState(() => _actioning = false);
  }

  Future<void> _confirmDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delivery'),
        content: const Text(
          'Has the package been handed to the recipient?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, delivered'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _actioning = true);
    final ok = await DriverService.confirmDelivery(
      widget.token,
      widget.userId,
      _job.id,
    );
    if (!mounted) return;
    if (ok) {
      await _showSuccessAndPop();
    } else {
      _showSnack('Failed to confirm delivery — try again');
      setState(() => _actioning = false);
    }
  }

  Future<void> _showSuccessAndPop() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Delivery Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: _kGreen, size: 56),
            const SizedBox(height: 12),
            Text(
              'You earned ${_job.priceFormatted}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // dismiss dialog
              Navigator.pop(context, true); // pop screen with success flag
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _callBuyer() async {
    final phone = _job.dropoffPhone;
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, maxLines: 2, overflow: TextOverflow.ellipsis),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── UI ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final initialCamera = _job.pickupLat != null
        ? CameraPosition(
            target: LatLng(_job.pickupLat!, _job.pickupLng!),
            zoom: 14,
          )
        : const CameraPosition(
            target: LatLng(-6.7924, 39.2083), // Dar es Salaam
            zoom: 12,
          );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _kSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Delivery',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _kPrimary,
              ),
            ),
            Text(
              _job.jobNumber,
              style: const TextStyle(fontSize: 12, color: _kTertiary),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _kDivider),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initialCamera,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              if (_driverLatLng != null) {
                c.animateCamera(CameraUpdate.newLatLng(_driverLatLng!));
              }
            },
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.65,
            builder: (_, scrollController) => _BottomSheet(
              job: _job,
              actioning: _actioning,
              codCashCollected: _codCashCollected,
              onConfirmPickup:
                  _job.canConfirmPickup ? _confirmPickup : null,
              onConfirmDelivery: _job.canConfirmDelivery
                  ? ((!_job.isCod || _codCashCollected) ? _confirmDelivery : null)
                  : null,
              onCollectCash: (_job.isCod &&
                      !_codCashCollected &&
                      _job.canConfirmDelivery)
                  ? _collectCash
                  : null,
              onCallBuyer: _callBuyer,
              scrollController: scrollController,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom Sheet ──────────────────────────────────────────────────────────

class _BottomSheet extends StatelessWidget {
  final TajiriDeliveryJob job;
  final bool actioning;
  final bool codCashCollected;
  final VoidCallback? onConfirmPickup;
  final VoidCallback? onConfirmDelivery;
  final VoidCallback? onCollectCash;
  final VoidCallback onCallBuyer;
  final ScrollController scrollController;

  const _BottomSheet({
    required this.job,
    required this.actioning,
    required this.codCashCollected,
    required this.onConfirmPickup,
    required this.onConfirmDelivery,
    required this.onCollectCash,
    required this.onCallBuyer,
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
          // Drag handle
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
          // Status label
          Text(
            job.statusLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.jobNumber,
            style: const TextStyle(fontSize: 13, color: _kTertiary),
          ),
          const SizedBox(height: 20),
          // Recipient row
          _RecipientRow(
            name: job.dropoffName,
            phone: job.dropoffPhone,
            address: job.dropoffAddress,
            onCall: onCallBuyer,
          ),
          const SizedBox(height: 20),
          // Action buttons
          if (onConfirmPickup != null)
            _ActionButton(
              label: 'Confirm Pickup',
              loading: actioning,
              onTap: onConfirmPickup!,
            )
          else ...[
            // COD: show "Collect Cash" button first if not yet collected
            if (job.isCod && !codCashCollected && onCollectCash != null) ...[
              _CodCollectButton(
                amount: job.orderTotalTzs > 0
                    ? job.orderTotalTzs
                    : job.itemValueTzs,
                loading: actioning,
                onTap: onCollectCash!,
              ),
              const SizedBox(height: 10),
            ],
            if (job.isCod && codCashCollected) ...[
              const _CodCollectedBadge(),
              const SizedBox(height: 10),
            ],
            if (onConfirmDelivery != null)
              _ActionButton(
                label: 'Confirm Delivery',
                loading: actioning,
                onTap: onConfirmDelivery!,
              )
            else if (job.isCod && !codCashCollected)
              _ActionButton(
                label: 'Confirm Delivery',
                loading: false,
                onTap: null,
                disabled: true,
              ),
          ],
        ],
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  final String name;
  final String phone;
  final String address;
  final VoidCallback onCall;

  const _RecipientRow({
    required this.name,
    required this.phone,
    required this.address,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFF0F0F0),
          child: Icon(Icons.person_rounded, color: _kSecondary, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                phone,
                style:
                    const TextStyle(fontSize: 13, color: _kSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 12, color: _kTertiary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          height: 48,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onCall,
            child: const Icon(
              Icons.phone_rounded,
              color: _kPrimary,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final bool disabled;

  const _ActionButton({
    required this.label,
    required this.loading,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: (loading || disabled) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

class _CodCollectButton extends StatelessWidget {
  final double amount;
  final bool loading;
  final VoidCallback onTap;

  const _CodCollectButton({
    required this.amount,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = amount > 0
        ? 'TZS ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}'
        : '';
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: const Icon(Icons.money_rounded, size: 22),
        label: Text(
          'Collect Cash${formatted.isNotEmpty ? ': $formatted' : ''}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _CodCollectedBadge extends StatelessWidget {
  const _CodCollectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: _kGreen, size: 18),
          SizedBox(width: 8),
          Text(
            'Cash collected by driver ✓',
            style: TextStyle(
              color: _kGreen,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
