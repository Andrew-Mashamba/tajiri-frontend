// lib/ambulance/pages/hospital_directory_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/local_storage_service.dart';
import '../models/ambulance_models.dart';
import '../services/ambulance_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kRed = Color(0xFFCC0000);

class HospitalDirectoryPage extends StatefulWidget {
  final int userId;
  const HospitalDirectoryPage({super.key, required this.userId});
  @override
  State<HospitalDirectoryPage> createState() => _HospitalDirectoryPageState();
}

class _HospitalDirectoryPageState extends State<HospitalDirectoryPage> {
  final AmbulanceService _service = AmbulanceService();
  final TextEditingController _searchCtrl = TextEditingController();
  List<Hospital> _hospitals = [];
  bool _isLoading = true;
  String? _filterCapability;
  late final bool _isSwahili;

  static const _capabilities = [
    'trauma',
    'maternity',
    'pediatric',
    'icu',
    'surgery'
  ];

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      // FIX 7: Pass coordinates so backend can calculate distance.
      // TODO: Replace with actual geolocator coordinates in production.
      final result = await _service.getHospitals(
        lat: -6.7924,
        lng: 39.2083,
        capability: _filterCapability,
        search: _searchCtrl.text.trim().isNotEmpty
            ? _searchCtrl.text.trim()
            : null,
      );
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _hospitals = result.items;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  Future<void> _callHospital(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
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

  Future<void> _openDirections(Hospital h) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${h.latitude},${h.longitude}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSwahili
              ? 'Imeshindwa kufungua maelekezo: $e'
              : 'Could not open directions: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(
          _isSwahili ? 'Hospitali' : 'Hospitals',
          style: const TextStyle(
              color: _kPrimary, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _load(),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: _isSwahili
                    ? 'Tafuta hospitali...'
                    : 'Search hospitals...',
                hintStyle:
                    const TextStyle(fontSize: 13, color: _kSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: _kSecondary, size: 22),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: _kSecondary, size: 20),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                isDense: true,
                filled: true,
                fillColor: _kBg,
              ),
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              children: [
                _Chip(
                    label: _isSwahili ? 'Zote' : 'All',
                    selected: _filterCapability == null,
                    onTap: () {
                      _filterCapability = null;
                      _load();
                    }),
                ..._capabilities.map((c) => _Chip(
                      label: c[0].toUpperCase() + c.substring(1),
                      selected: _filterCapability == c,
                      onTap: () {
                        _filterCapability = c;
                        _load();
                      },
                    )),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _hospitals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_hospital_rounded,
                                size: 48, color: _kSecondary),
                            const SizedBox(height: 12),
                            Text(
                                _isSwahili
                                    ? 'Hakuna hospitali'
                                    : 'No hospitals found',
                                style: const TextStyle(
                                    color: _kSecondary, fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _hospitals.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) {
                            final h = _hospitals[i];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: _kRed.withValues(
                                                alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    10),
                                          ),
                                          child: const Icon(
                                              Icons
                                                  .local_hospital_rounded,
                                              color: _kRed,
                                              size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment
                                                    .start,
                                            children: [
                                              Text(h.name,
                                                  style: const TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight
                                                              .w500,
                                                      color:
                                                          _kPrimary),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow
                                                          .ellipsis),
                                              if (h.type != null)
                                                Text(h.type!,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            _kSecondary)),
                                            ],
                                          ),
                                        ),
                                        if (h.distanceKm != null)
                                          Text(
                                              '${h.distanceKm!.toStringAsFixed(1)} km',
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                  color: _kPrimary)),
                                      ],
                                    ),
                                    if (h.capabilities.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: h.capabilities
                                            .take(4)
                                            .map((c) {
                                          return Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 8,
                                                    vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFFF0F0F0),
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(6),
                                            ),
                                            child: Text(c,
                                                style:
                                                    const TextStyle(
                                                        fontSize: 11,
                                                        color:
                                                            _kSecondary)),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (h.rating > 0) ...[
                                          const Icon(
                                              Icons.star_rounded,
                                              size: 14,
                                              color:
                                                  Color(0xFFFFB300)),
                                          const SizedBox(width: 2),
                                          Text(
                                              h.rating
                                                  .toStringAsFixed(1),
                                              style:
                                                  const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          _kSecondary)),
                                          const SizedBox(width: 12),
                                        ],
                                        if (h.bedCount > 0)
                                          Text(
                                              '${h.bedCount} ${_isSwahili ? 'vitanda' : 'beds'}',
                                              style:
                                                  const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          _kSecondary)),
                                        if (h.waitTimeMinutes !=
                                            null) ...[
                                          const SizedBox(width: 12),
                                          Row(
                                            mainAxisSize:
                                                MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons
                                                      .schedule_rounded,
                                                  size: 13,
                                                  color: Color(
                                                      0xFFE65100)),
                                              const SizedBox(
                                                  width: 3),
                                              Text(
                                                '~${h.waitTimeMinutes} ${_isSwahili ? 'dak kusubiri' : 'min wait'}',
                                                style:
                                                    const TextStyle(
                                                        fontSize:
                                                            12,
                                                        color: Color(
                                                            0xFFE65100),
                                                        fontWeight:
                                                            FontWeight
                                                                .w500),
                                              ),
                                            ],
                                          ),
                                        ],
                                        const Spacer(),
                                        if (h.phone != null)
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: IconButton(
                                              onPressed: () =>
                                                  _callHospital(
                                                      h.phone!),
                                              icon: const Icon(
                                                  Icons
                                                      .phone_rounded,
                                                  size: 20,
                                                  color:
                                                      _kPrimary),
                                              tooltip: _isSwahili
                                                  ? 'Piga simu'
                                                  : 'Call',
                                            ),
                                          ),
                                        SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: IconButton(
                                            onPressed: () =>
                                                _openDirections(h),
                                            icon: const Icon(
                                                Icons
                                                    .directions_rounded,
                                                size: 20,
                                                color: _kPrimary),
                                            tooltip: _isSwahili
                                                ? 'Maelekezo'
                                                : 'Directions',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : _kPrimary)),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: _kPrimary,
        backgroundColor: Colors.white,
        side: BorderSide(
            color: selected ? _kPrimary : const Color(0xFFE0E0E0)),
      ),
    );
  }
}
