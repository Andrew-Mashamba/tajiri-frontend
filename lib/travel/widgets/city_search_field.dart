import 'dart:async';
import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../services/travel_service.dart';
import 'mode_icon.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class CitySearchField {
  CitySearchField._();

  static Future<City?> show(BuildContext context, {String? title}) {
    return showModalBottomSheet<City>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CitySearchSheet(title: title ?? 'Chagua Mji'),
    );
  }
}

class _CitySearchSheet extends StatefulWidget {
  final String title;
  const _CitySearchSheet({required this.title});

  @override
  State<_CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<_CitySearchSheet> {
  final TravelService _service = TravelService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<City> _cities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadCities([String? query]) async {
    setState(() => _isLoading = true);
    final result = await _service.getCities(query: query);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _cities = result.items;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _loadCities(value.isEmpty ? null : value);
    });
  }

  String _countryFlag(String countryCode) {
    if (countryCode.length != 2) return '';
    final c1 = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final c2 = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCodes([c1, c2]);
  }

  List<String> _cityModes(City city) {
    final modes = <String>[];
    if (city.hasBusTerminal) modes.add('bus');
    if (city.hasAirport) modes.add('flight');
    if (city.hasTrainStation) modes.add('train');
    if (city.hasFerryTerminal) modes.add('ferry');
    return modes;
  }

  @override
  Widget build(BuildContext context) {
    final tzCities = _cities.where((c) => c.country.toUpperCase() == 'TZ').toList();
    final otherCities = _cities.where((c) => c.country.toUpperCase() != 'TZ').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Tafuta mji / Search city',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search, color: _kSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Results
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
                    )
                  : _cities.isEmpty
                      ? Center(
                          child: Text(
                            'Hakuna mji uliopatikana / No city found',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          children: [
                            if (tzCities.isNotEmpty) ...[
                              _sectionHeader('Tanzania'),
                              ...tzCities.map(_cityTile),
                            ],
                            if (otherCities.isNotEmpty) ...[
                              _sectionHeader('Nchi Nyingine / Other Countries'),
                              ...otherCities.map(_cityTile),
                            ],
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _kSecondary,
        ),
      ),
    );
  }

  Widget _cityTile(City city) {
    final modes = _cityModes(city);
    return ListTile(
      leading: Text(
        _countryFlag(city.country.toUpperCase()),
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        city.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _kPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            '${city.code}${city.region != null ? ' \u2022 ${city.region}' : ''}',
            style: const TextStyle(fontSize: 12, color: _kSecondary),
          ),
          if (modes.isNotEmpty) ...[
            const SizedBox(width: 8),
            ModeIcon.modeRow(modes, size: 14, color: _kSecondary),
          ],
        ],
      ),
      onTap: () => Navigator.pop(context, city),
    );
  }
}
