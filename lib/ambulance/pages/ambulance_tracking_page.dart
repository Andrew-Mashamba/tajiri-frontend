// lib/ambulance/pages/ambulance_tracking_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../../services/message_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';
import '../widgets/tracking_status_timeline.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class AmbulanceTrackingPage extends StatefulWidget {
  final int emergencyId;
  const AmbulanceTrackingPage({super.key, required this.emergencyId});
  @override
  State<AmbulanceTrackingPage> createState() => _AmbulanceTrackingPageState();
}

class _AmbulanceTrackingPageState extends State<AmbulanceTrackingPage> {
  final AmbulanceService _service = AmbulanceService();
  final MessageService _messageService = MessageService();
  AmbulanceTracking? _tracking;
  bool _isLoading = true;
  bool _isSendingMessage = false;
  String? _error;
  Timer? _pollTimer;
  late final bool _isSwahili;
  int? _currentUserId;
  double _userLat = -6.7924;
  double _userLng = 39.2083;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadUserId();
    _acquireUserLocation();
    _loadTracking();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadTracking();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _acquireUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
    } catch (_) {
      // Keep defaults
    }
  }

  Future<void> _loadTracking() async {
    try {
      final result = await _service.trackAmbulance(widget.emergencyId);
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _isLoading = false;
          _tracking = result.data;
          _error = null;
        });
        _fitMapBounds();
      } else {
        // FIX 1a: Fallback to getDispatchStatus when trackAmbulance returns no data
        await _loadDispatchStatusFallback();
      }
    } catch (e) {
      if (!mounted) return;
      // FIX 1a: Try dispatch status as fallback on tracking error
      await _loadDispatchStatusFallback(fallbackError: '$e');
    }
  }

  /// FIX 1a: Fallback — fetch dispatch status when tracking data is unavailable
  Future<void> _loadDispatchStatusFallback({String? fallbackError}) async {
    try {
      final dispatchResult =
          await _service.getDispatchStatus(widget.emergencyId);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (dispatchResult.success && dispatchResult.data != null) {
          final e = dispatchResult.data!;
          // Map Emergency dispatch data into AmbulanceTracking
          _tracking = AmbulanceTracking(
            ambulanceId: e.ambulance?.id ?? 0,
            latitude: e.ambulance?.latitude ?? e.latitude,
            longitude: e.ambulance?.longitude ?? e.longitude,
            etaMinutes: e.ambulance?.etaMinutes,
            driverName: e.ambulance?.driverName,
            driverPhone: e.ambulance?.driverPhone,
            driverPhoto: e.ambulance?.driverPhoto,
            status: e.status,
            ambulanceProvider: e.ambulanceProvider,
          );
          _error = null;
        } else {
          _error = fallbackError ?? dispatchResult.message;
        }
      });
    } catch (e2) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = fallbackError ?? '$e2';
      });
    }
  }

  void _loadUserId() {
    final user = LocalStorageService.instanceSync?.getUser();
    if (user?.userId != null) {
      setState(() => _currentUserId = user!.userId);
    }
  }

  Set<Marker> _buildMapMarkers() {
    final markers = <Marker>{};
    // User location marker
    markers.add(Marker(
      markerId: const MarkerId('user'),
      position: LatLng(_userLat, _userLng),
      infoWindow: InfoWindow(
        title: _isSwahili ? 'Eneo Lako' : 'Your Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));
    // Ambulance location marker
    if (_tracking != null &&
        (_tracking!.latitude != 0 || _tracking!.longitude != 0)) {
      markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: LatLng(_tracking!.latitude, _tracking!.longitude),
        infoWindow: InfoWindow(
          title: _isSwahili ? 'Ambulensi' : 'Ambulance',
          snippet: _tracking!.driverName,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }
    return markers;
  }

  void _fitMapBounds() {
    if (_mapController == null || _tracking == null) return;
    if (_tracking!.latitude == 0 && _tracking!.longitude == 0) return;
    final bounds = LatLngBounds(
      southwest: LatLng(
        _userLat < _tracking!.latitude ? _userLat : _tracking!.latitude,
        _userLng < _tracking!.longitude ? _userLng : _tracking!.longitude,
      ),
      northeast: LatLng(
        _userLat > _tracking!.latitude ? _userLat : _tracking!.latitude,
        _userLng > _tracking!.longitude ? _userLng : _tracking!.longitude,
      ),
    );
    try {
      _mapController!
          .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (_) {
      // Map not ready yet
    }
  }

  Future<void> _callDriver() async {
    if (_tracking?.driverPhone == null) return;
    final uri = Uri.parse('tel:${_tracking!.driverPhone}');
    try {
      await launchUrl(uri);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindwa kupiga simu: $e'
              : 'Could not launch call: $e'),
        ),
      );
    }
  }

  void _chatWithCrew() {
    final messageController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isSwahili ? 'Tuma Ujumbe kwa Wafanyakazi' : 'Message the Crew',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isSwahili
                      ? 'Ujumbe utawasilishwa kwa timu ya ambulensi'
                      : 'Message will be delivered to the ambulance crew',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  autofocus: true,
                  maxLines: 3,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: _isSwahili ? 'Andika ujumbe...' : 'Type a message...',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isSendingMessage
                        ? null
                        : () async {
                            final text = messageController.text.trim();
                            if (text.isEmpty) return;
                            if (_currentUserId == null) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            setSheetState(() {});
                            setState(() => _isSendingMessage = true);
                            try {
                              await _messageService.sendMessage(
                                conversationId: widget.emergencyId,
                                userId: _currentUserId!,
                                content: text,
                                messageType: 'text',
                              );
                              messageController.clear();
                              if (!mounted) return;
                              setState(() => _isSendingMessage = false);
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(_isSwahili
                                      ? 'Ujumbe umetumwa!'
                                      : 'Message sent!'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _isSendingMessage = false);
                              messenger.showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          },
                    icon: _isSendingMessage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _isSwahili ? 'Tuma Ujumbe' : 'Send Message',
                      style: const TextStyle(fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => messageController.dispose());
  }

  Future<void> _shareLink() async {
    try {
      final result = await _service.shareTrackingLink(widget.emergencyId);
      if (!mounted) return;
      if (result.success && result.data != null) {
        final smsUri = Uri(
          scheme: 'sms',
          queryParameters: {'body': result.data!},
        );
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (_isSwahili ? 'Imeshindwa' : 'Failed to get link'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Fuatilia Ambulensi' : 'Track Ambulance',
          style:
              const TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null && _tracking == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 48, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(
                              color: _kSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadTracking,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary,
                            minimumSize: const Size(120, 48),
                          ),
                          child: Text(_isSwahili ? 'Jaribu tena' : 'Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTracking,
                  color: _kPrimary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // FEATURE 16: Google Maps with real markers
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: LatLng(_userLat, _userLng),
                              zoom: 13,
                            ),
                            onMapCreated: (controller) {
                              _mapController = controller;
                              _fitMapBounds();
                            },
                            markers: _buildMapMarkers(),
                            myLocationEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                            liteModeEnabled: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // FEATURE 45: Show estimated cost
                      if (_tracking?.estimatedCost != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.payments_rounded,
                                  size: 20, color: _kSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isSwahili
                                          ? 'Gharama Inayokadiriwa'
                                          : 'Estimated Cost',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _kSecondary),
                                    ),
                                    Text(
                                      'TZS ${_tracking!.estimatedCost!.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: _kPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),

                      // ETA
                      if (_tracking?.etaMinutes != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _kRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.timer_rounded,
                                  color: _kRed, size: 28),
                              const SizedBox(width: 12),
                              Column(
                                children: [
                                  Text(
                                    '${_tracking!.etaMinutes} ${_isSwahili ? 'dakika' : 'min'}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: _kRed),
                                  ),
                                  Text(
                                    _isSwahili
                                        ? 'Muda uliobaki'
                                        : 'Estimated arrival',
                                    style: const TextStyle(
                                        fontSize: 12, color: _kSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Ambulance provider badge
                      if (_tracking != null) ...[
                        Builder(builder: (context) {
                          final provider = _tracking!.ambulanceProvider?.isNotEmpty == true
                              ? _tracking!.ambulanceProvider!
                              : null;
                          if (provider == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_taxi_rounded,
                                    size: 20, color: _kSecondary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _isSwahili
                                            ? 'Huduma ya Ambulensi'
                                            : 'Ambulance Service',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: _kSecondary),
                                      ),
                                      Text(
                                        '$provider Ambulance',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _kPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // Status timeline
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TrackingStatusTimeline(
                          currentStatus:
                              _tracking?.status ?? EmergencyStatus.dispatched,
                          isSwahili: _isSwahili,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Driver card
                      if (_tracking?.driverName != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: const Color(0xFFE8E8E8),
                                backgroundImage: _tracking?.driverPhoto != null
                                    ? NetworkImage(_tracking!.driverPhoto!)
                                    : null,
                                child: _tracking?.driverPhoto == null
                                    ? const Icon(Icons.person_rounded,
                                        color: _kSecondary, size: 28)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _tracking!.driverName!,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      _isSwahili
                                          ? 'Dereva / Daktari wa Dharura'
                                          : 'Driver / Paramedic',
                                      style: const TextStyle(
                                          fontSize: 12, color: _kSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: IconButton(
                                  onPressed: _callDriver,
                                  icon: const Icon(Icons.phone_rounded,
                                      color: _kPrimary),
                                  tooltip:
                                      _isSwahili ? 'Piga simu' : 'Call',
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: _shareLink,
                                icon: const Icon(Icons.share_rounded,
                                    size: 20),
                                label: Text(
                                  _isSwahili ? 'Shiriki' : 'Share',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _kPrimary,
                                  side: const BorderSide(
                                      color: Color(0xFFE0E0E0)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 48,
                              child: FilledButton.icon(
                                onPressed: _callDriver,
                                icon: const Icon(Icons.phone_rounded,
                                    size: 20),
                                label: Text(
                                  _isSwahili
                                      ? 'Piga Dereva'
                                      : 'Call Driver',
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: _kPrimary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _chatWithCrew,
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 20),
                          label: Text(
                            _isSwahili ? 'Tuma Ujumbe' : 'Send Message',
                            style: const TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _kPrimary,
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
