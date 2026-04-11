// lib/ambulance/pages/aed_map_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class AedMapPage extends StatefulWidget {
  const AedMapPage({super.key});
  @override
  State<AedMapPage> createState() => _AedMapPageState();
}

class _AedMapPageState extends State<AedMapPage> {
  final AmbulanceService _service = AmbulanceService();
  late final bool _isSwahili;
  bool _isLoading = true;
  List<AedLocation> _locations = [];
  GoogleMapController? _mapController;
  double _userLat = -6.7924;
  double _userLng = 39.2083;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _acquireLocationAndLoad();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _acquireLocationAndLoad() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied &&
            permission != LocationPermission.deniedForever) {
          final position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                  accuracy: LocationAccuracy.medium));
          _userLat = position.latitude;
          _userLng = position.longitude;
        }
      }
    } catch (_) {
      // Keep defaults
    }
    await _loadAedLocations();
  }

  Future<void> _loadAedLocations() async {
    try {
      final result = await _service.getAedLocations(
        lat: _userLat,
        lng: _userLng,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) {
          _locations = result.items;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindwa kupakia maeneo ya AED: $e'
              : 'Failed to load AED locations: $e'),
        ),
      );
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    // User marker
    markers.add(Marker(
      markerId: const MarkerId('user'),
      position: LatLng(_userLat, _userLng),
      infoWindow: InfoWindow(
        title: _isSwahili ? 'Eneo Lako' : 'Your Location',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    ));
    // AED markers
    for (final loc in _locations) {
      markers.add(Marker(
        markerId: MarkerId('aed_${loc.id ?? loc.name}'),
        position: LatLng(loc.latitude, loc.longitude),
        infoWindow: InfoWindow(
          title: loc.name,
          snippet: loc.address,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Maeneo ya AED' : 'AED Locations',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.monitor_heart_rounded,
                          size: 20, color: _kRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isSwahili
                              ? 'Maeneo ya AED (Automated External Defibrillator) karibu nawe'
                              : 'AED (Automated External Defibrillator) locations near you',
                          style: const TextStyle(
                              fontSize: 12, color: _kSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Map
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_userLat, _userLng),
                      zoom: 13,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    markers: _buildMarkers(),
                    myLocationEnabled: false,
                    zoomControlsEnabled: true,
                    mapToolbarEnabled: true,
                  ),
                ),
                // List of AEDs
                if (_locations.isNotEmpty)
                  Container(
                    height: 140,
                    color: Colors.white,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      itemCount: _locations.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final loc = _locations[i];
                        return GestureDetector(
                          onTap: () {
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(loc.latitude, loc.longitude),
                                16,
                              ),
                            );
                          },
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _kBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.monitor_heart_rounded,
                                        size: 16,
                                        color: _kRed),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        loc.name,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _kPrimary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (loc.address != null)
                                  Expanded(
                                    child: Text(
                                      loc.address!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: _kSecondary),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _isSwahili
                          ? 'Hakuna maeneo ya AED yaliyopatikana karibu'
                          : 'No AED locations found nearby',
                      style: const TextStyle(
                          fontSize: 13, color: _kSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
    );
  }
}
