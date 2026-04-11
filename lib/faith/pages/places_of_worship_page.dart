// lib/faith/pages/places_of_worship_page.dart
import 'package:flutter/material.dart';
import '../models/faith_models.dart';
import '../services/faith_service.dart';
import '../widgets/worship_place_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PlacesOfWorshipPage extends StatefulWidget {
  final int userId;
  const PlacesOfWorshipPage({super.key, required this.userId});
  @override
  State<PlacesOfWorshipPage> createState() => _PlacesOfWorshipPageState();
}

class _PlacesOfWorshipPageState extends State<PlacesOfWorshipPage> {
  final FaithService _service = FaithService();
  List<PlaceOfWorship> _places = [];
  bool _isLoading = true;
  WorshipPlaceType? _filterType;

  final double _latitude = -6.7924;
  final double _longitude = 39.2083;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    final result = await _service.getNearbyPlaces(
      latitude: _latitude,
      longitude: _longitude,
      type: _filterType,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _places = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Maeneo ya Ibada',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Places of Worship',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Zote',
                  isSelected: _filterType == null,
                  onTap: () {
                    _filterType = null;
                    _loadPlaces();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Misikiti',
                  isSelected: _filterType == WorshipPlaceType.mosque,
                  onTap: () {
                    _filterType = WorshipPlaceType.mosque;
                    _loadPlaces();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Makanisa',
                  isSelected: _filterType == WorshipPlaceType.church,
                  onTap: () {
                    _filterType = WorshipPlaceType.church;
                    _loadPlaces();
                  },
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _places.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_rounded,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Hakuna maeneo yaliyopatikana',
                                style: TextStyle(color: _kSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPlaces,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _places.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) =>
                              WorshipPlaceCard(place: _places[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _kSecondary,
          ),
        ),
      ),
    );
  }
}
