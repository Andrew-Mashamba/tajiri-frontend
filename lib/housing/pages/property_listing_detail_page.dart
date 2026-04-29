import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/property_listing.dart';
import '../widgets/panorama_launcher.dart';
import '../services/property_listing_service.dart';
import 'property_inquiry_page.dart';

/// Hive-backed local bookmark store for property listings (spec line 865).
/// Used until a server-side `saved_listings` endpoint lands.
const String _kSavedKey = 'saved_property_listings';

Set<int> _readSavedIds() {
  final raw = LocalStorageService.instanceSync?.getString(_kSavedKey) ?? '';
  if (raw.isEmpty) return <int>{};
  return raw
      .split(',')
      .map((s) => int.tryParse(s.trim()))
      .whereType<int>()
      .toSet();
}

Future<void> _writeSavedIds(Set<int> ids) async {
  final storage = await LocalStorageService.getInstance();
  await storage.setString(_kSavedKey, ids.join(','));
}

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kCard = Color(0xFFFFFFFF);

class PropertyListingDetailPage extends StatefulWidget {
  final int listingId;
  final PropertyListing? initial;

  const PropertyListingDetailPage({
    super.key,
    required this.listingId,
    this.initial,
  });

  @override
  State<PropertyListingDetailPage> createState() => _PropertyListingDetailPageState();
}

class _PropertyListingDetailPageState extends State<PropertyListingDetailPage> {
  PropertyListing? _l;
  bool _loading = false;
  String? _error;
  int _photoIndex = 0;
  int? _viewerUserId;
  bool _saved = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isOwner => _viewerUserId != null && _l?.partnerUserId == _viewerUserId;

  @override
  void initState() {
    super.initState();
    _l = widget.initial;
    _viewerUserId = LocalStorageService.instanceSync?.getUser()?.userId;
    _saved = _readSavedIds().contains(widget.listingId);
    _load();
  }

  Future<void> _toggleSave() async {
    final ids = _readSavedIds();
    if (ids.contains(widget.listingId)) {
      ids.remove(widget.listingId);
    } else {
      ids.add(widget.listingId);
    }
    await _writeSavedIds(ids);
    if (!mounted) return;
    setState(() => _saved = ids.contains(widget.listingId));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_saved
          ? (_isSwahili ? 'Imehifadhiwa' : 'Saved')
          : (_isSwahili ? 'Imeondolewa' : 'Removed')),
    ));
  }

  Future<void> _share() async {
    final l = _l;
    if (l == null) return;
    final price = NumberFormat('#,##0', 'en_US').format(l.priceTzs);
    final loc = l.locationDisplay.isEmpty ? '' : ' • ${l.locationDisplay}';
    final body = '${l.title}$loc\nTZS $price\n'
        'tajiri.app/listing/${l.id}';
    await SharePlus.instance.share(ShareParams(text: body));
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await PropertyListingService.get(
      id: widget.listingId,
      viewerUserId: _viewerUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success) {
        _l = res.listing;
      } else {
        _error = res.message ?? 'Failed';
      }
    });
  }

  Future<void> _openInquiry({InquiryKindOption initial = InquiryKindOption.viewing}) async {
    final l = _l;
    if (l == null) return;
    if (_viewerUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Tafadhali ingia kwanza' : 'Please sign in first'),
      ));
      return;
    }
    if (_isOwner) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Huwezi kuuliza juu ya tangazo lako mwenyewe'
            : "You can't inquire on your own listing"),
      ));
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyInquiryPage(
          listing: l,
          customerUserId: _viewerUserId!,
          initialKind: initial,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = _l;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          l?.title ?? (_isSwahili ? 'Mali' : 'Property'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: l == null
            ? null
            : [
                IconButton(
                  tooltip: _saved
                      ? (_isSwahili ? 'Ondoa hifadhi' : 'Remove')
                      : (_isSwahili ? 'Hifadhi' : 'Save'),
                  onPressed: _toggleSave,
                  icon: Icon(
                    _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _kPrimary,
                  ),
                ),
                IconButton(
                  tooltip: _isSwahili ? 'Shiriki' : 'Share',
                  onPressed: _share,
                  icon: const Icon(Icons.share_rounded, color: _kPrimary),
                ),
              ],
      ),
      body: _loading && l == null
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null && l == null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(_error!, style: const TextStyle(color: _kMuted))),
                )
              : l == null
                  ? Center(child: Text(_isSwahili ? 'Hapatikani' : 'Not found',
                      style: const TextStyle(color: _kMuted)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                        children: [
                          _photoCarousel(l),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _titlePriceCard(l),
                                const SizedBox(height: 10),
                                _statsCard(l),
                                if (l.amenities.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _amenitiesCard(l),
                                ],
                                const SizedBox(height: 10),
                                _descriptionCard(l),
                                if (_hasResearchChips(l)) ...[
                                  const SizedBox(height: 10),
                                  _researchChipsCard(l),
                                ],
                                if (l.matterportEnabled &&
                                    l.matterportUrl != null &&
                                    l.matterportUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  PanoramaLauncher(url: l.matterportUrl!),
                                ],
                                if (l.floorPlanUrls.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _floorPlanCard(l),
                                ],
                                if (l.locationDisplay.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  _locationCard(l),
                                ],
                                const SizedBox(height: 10),
                                _partnerCard(l),
                                const SizedBox(height: 10),
                                _openHouseCta(l),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
      bottomNavigationBar: l == null ? null : _bottomBar(l),
    );
  }

  Widget _photoCarousel(PropertyListing l) {
    if (l.photos.isEmpty) {
      return Container(
        height: 220,
        color: _kPrimary.withValues(alpha: 0.06),
        child: Icon(l.propertyType.icon, size: 64, color: _kMuted),
      );
    }
    return SizedBox(
      height: 240,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: l.photos.length,
            onPageChanged: (i) => setState(() => _photoIndex = i),
            itemBuilder: (_, i) {
              final url = PropertyListing.resolvePhoto(l.photos[i]);
              return Image.network(
                url,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: _kPrimary.withValues(alpha: 0.06),
                  child: Icon(l.propertyType.icon, size: 48, color: _kMuted),
                ),
              );
            },
          ),
          if (l.photos.length > 1)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(l.photos.length, (i) {
                  final on = i == _photoIndex;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: on ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: on ? Colors.white : Colors.white70,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          // Spec line 925 — photo verification badge.
          if (l.photoVerificationStatus == 'verified')
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      _isSwahili ? 'Imehakikishwa' : 'Verified',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _titlePriceCard(PropertyListing l) {
    final price = NumberFormat('#,##0', 'en_US').format(l.priceTzs);
    final freq = l.priceFrequency != null
        ? (_isSwahili ? l.priceFrequency!.labelSwahili : l.priceFrequency!.label)
        : '';
    return _card([
      Row(
        children: [
          Icon(l.propertyType.icon, size: 18, color: _kPrimary),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: l.listingKind == ListingKind.sale
                  ? const Color(0xFFE3F2FD)
                  : const Color(0xFFEDE7F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _isSwahili ? l.listingKind.labelSwahili : l.listingKind.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: l.listingKind == ListingKind.sale
                    ? const Color(0xFF0D47A1)
                    : const Color(0xFF4527A0),
              ),
            ),
          ),
          const Spacer(),
          if (!l.isActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isSwahili ? 'Haipatikani' : 'Inactive',
                style: const TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFFB71C1C),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        l.title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
      ),
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'TZS $price',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kPrimary),
          ),
          if (freq.isNotEmpty) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(freq, style: const TextStyle(fontSize: 11, color: _kMuted)),
            ),
          ],
        ],
      ),
    ]);
  }

  Widget _statsCard(PropertyListing l) {
    final stats = <Widget>[];
    if (l.bedrooms != null) {
      stats.add(_statTile(Icons.bed_rounded, '${l.bedrooms}', _isSwahili ? 'Vyumba' : 'Beds'));
    }
    if (l.bathrooms != null) {
      stats.add(_statTile(Icons.bathtub_outlined, '${l.bathrooms}', _isSwahili ? 'Bafu' : 'Baths'));
    }
    if (l.areaSqm != null) {
      stats.add(_statTile(Icons.square_foot_rounded, '${l.areaSqm}', 'm²'));
    }
    if (l.plotSizeSqm != null) {
      stats.add(_statTile(Icons.crop_din_rounded, '${l.plotSizeSqm}', _isSwahili ? 'Kiwanja m²' : 'Plot m²'));
    }
    if (stats.isEmpty) return const SizedBox.shrink();
    return _card([
      Row(children: stats.map((w) => Expanded(child: w)).toList()),
    ]);
  }

  Widget _statTile(IconData icon, String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Icon(icon, size: 18, color: _kPrimary),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
          Text(label, style: const TextStyle(fontSize: 10, color: _kMuted)),
        ],
      ),
    );
  }

  Widget _amenitiesCard(PropertyListing l) {
    return _card([
      Text(_isSwahili ? 'Vifaa' : 'Amenities',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: l.amenities.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(_amenityLabel(a),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
            )).toList(),
      ),
    ]);
  }

  String _amenityLabel(String key) {
    final swMap = <String, String>{
      'parking': 'Parking',
      'garden': 'Bustani',
      'security': 'Ulinzi',
      'water_tank': 'Tank ya maji',
      'generator': 'Generator',
      'furnished': 'Vyombo',
      'wifi': 'Wifi',
      'pool': 'Bwawa',
      'gym': 'Gym',
      'air_conditioning': 'AC',
    };
    final enMap = <String, String>{
      'parking': 'Parking',
      'garden': 'Garden',
      'security': 'Security',
      'water_tank': 'Water tank',
      'generator': 'Generator',
      'furnished': 'Furnished',
      'wifi': 'Wifi',
      'pool': 'Pool',
      'gym': 'Gym',
      'air_conditioning': 'AC',
    };
    return _isSwahili ? (swMap[key] ?? key) : (enMap[key] ?? key);
  }

  Widget _descriptionCard(PropertyListing l) {
    return _card([
      Text(_isSwahili ? 'Maelezo' : 'Description',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
      const SizedBox(height: 6),
      Text(l.description, style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
    ]);
  }

  bool _hasResearchChips(PropertyListing l) {
    return l.epcBand != null ||
        l.matterportEnabled ||
        l.backOnMarketAt != null ||
        l.obfuscateLocationUntilInquiry;
  }

  Widget _researchChipsCard(PropertyListing l) {
    final isSw = _isSwahili;
    return _card([
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          if (l.epcBand != null && l.epcBand!.isNotEmpty)
            _detailChip(
              isSw ? 'EPC ${l.epcBand}' : 'EPC ${l.epcBand}',
              const Color(0xFFE8F5E9),
              const Color(0xFF1B5E20),
              Icons.bolt_rounded,
            ),
          if (l.matterportEnabled)
            _detailChip(
              isSw ? 'Ziara ya 3D' : '3D Tour',
              const Color(0xFFE3F2FD),
              const Color(0xFF0D47A1),
              Icons.view_in_ar_rounded,
            ),
          if (l.backOnMarketAt != null)
            _detailChip(
              isSw ? 'Imerudi sokoni' : 'Back on market',
              const Color(0xFFFFF8E1),
              const Color(0xFFE65100),
              Icons.refresh_rounded,
            ),
          if (l.obfuscateLocationUntilInquiry)
            _detailChip(
              isSw ? 'Eneo limefichwa' : 'Location hidden',
              const Color(0xFFEEEEEE),
              const Color(0xFF666666),
              Icons.location_off_rounded,
            ),
        ],
      ),
    ]);
  }

  Widget _detailChip(String text, Color bg, Color fg, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floorPlanCard(PropertyListing l) {
    final isSw = _isSwahili;
    return _card([
      Row(
        children: [
          const Icon(Icons.architecture_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Text(
            isSw ? 'Ramani ya nyumba' : 'Floor plan',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: _kPrimary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 160,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: l.floorPlanUrls.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, i) => ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              PropertyListing.resolvePhoto(l.floorPlanUrls[i]),
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 200,
                height: 160,
                color: const Color(0xFFEEEEEE),
                child: const Icon(Icons.broken_image_rounded,
                    color: Color(0xFF666666)),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _locationCard(PropertyListing l) {
    return _card([
      Row(
        children: [
          const Icon(Icons.place_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              l.locationDisplay,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
          if (l.lat != null && l.lng != null)
            TextButton.icon(
              onPressed: () => _openMaps(l),
              icon: const Icon(Icons.map_rounded, size: 14),
              label: Text(_isSwahili ? 'Fungua' : 'Open'),
              style: TextButton.styleFrom(
                foregroundColor: _kPrimary,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      // Spec line 861 — static map preview via OSM (no API key needed).
      if (l.lat != null && l.lng != null) ...[
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            onTap: () => _openMaps(l),
            child: Image.network(
              'https://staticmap.openstreetmap.de/staticmap.php?'
              'center=${l.lat},${l.lng}&zoom=15&size=600x200&maptype=mapnik'
              '&markers=${l.lat},${l.lng},red-pushpin',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 160,
                color: const Color(0xFFEEEEEE),
                child: const Icon(Icons.map_rounded, size: 36, color: _kMuted),
              ),
            ),
          ),
        ),
      ],
      // Spec line 932 — Walk/Bike/Transit scores.
      if (l.walkScore != null || l.bikeScore != null || l.transitScore != null) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            if (l.walkScore != null)
              _scoreBadge(Icons.directions_walk_rounded,
                  _isSwahili ? 'Tembea' : 'Walk', l.walkScore!),
            if (l.bikeScore != null)
              _scoreBadge(Icons.directions_bike_rounded,
                  _isSwahili ? 'Baisikeli' : 'Bike', l.bikeScore!),
            if (l.transitScore != null)
              _scoreBadge(Icons.directions_bus_rounded,
                  _isSwahili ? 'Daladala' : 'Transit', l.transitScore!),
          ],
        ),
      ],
      if (l.neighborhoodDescription != null && l.neighborhoodDescription!.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(
          _isSwahili ? 'Eneo' : 'Neighborhood',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.4),
        ),
        const SizedBox(height: 4),
        Text(
          l.neighborhoodDescription!,
          style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4),
        ),
      ],
    ]);
  }

  Widget _scoreBadge(IconData icon, String label, int score) {
    final color = score >= 75
        ? const Color(0xFF1B5E20)
        : score >= 50
            ? const Color(0xFFE65100)
            : const Color(0xFFB71C1C);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(width: 4),
            Text('$score',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  /// Spec line 942 — open-house RSVP button. Lets the customer RSVP to the
  /// next open-house slot on this listing; the partner sees the count on
  /// their inbox + uses it to plan staffing.
  Widget _openHouseCta(PropertyListing l) {
    return _card([
      Row(
        children: [
          const Icon(Icons.event_available_rounded, size: 16, color: _kPrimary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _isSwahili ? 'Open House' : 'Open House',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _rsvpToOpenHouse(l),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(_isSwahili ? 'RSVP' : 'RSVP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        _isSwahili
            ? 'Jiunge na ukaguzi wa kikundi. Mshirika atatuma ratiba kabla.'
            : 'Join a group viewing. Partner sends the schedule beforehand.',
        style: const TextStyle(fontSize: 11, color: _kMuted),
      ),
    ]);
  }

  Future<void> _rsvpToOpenHouse(PropertyListing l) async {
    if (_viewerUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Tafadhali ingia kwanza' : 'Please sign in first'),
      ));
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;
    final at = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/partner-c2b/research/rsvps'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'listing_id': l.id,
          'user_id': _viewerUserId,
          'event_starts_at': at.toUtc().toIso8601String(),
        }),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.statusCode == 200
            ? (_isSwahili ? 'RSVP imerekodiwa' : 'RSVP recorded')
            : (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili ? 'Imeshindikana' : 'Failed'),
      ));
    }
  }

  Future<void> _openMaps(PropertyListing l) async {
    if (l.lat == null || l.lng == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${l.lat},${l.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _partnerCard(PropertyListing l) {
    return _card([
      Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: _kPrimary.withValues(alpha: 0.06),
            child: Text(
              (l.partnerName ?? '?').characters.first,
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.partnerName ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text(_isSwahili ? 'Wakala' : 'Agent',
                    style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
        ],
      ),
    ]);
  }

  Widget _bottomBar(PropertyListing l) {
    if (!l.isActive) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: _kBorder)),
          ),
          child: Text(
            _isSwahili ? 'Tangazo hili halipatikani sasa' : 'This listing is unavailable',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _kMuted),
          ),
        ),
      );
    }
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _kBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: OutlinedButton.icon(
                  onPressed: () => _openInquiry(initial: InquiryKindOption.question),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                  label: Text(_isSwahili ? 'Uliza' : 'Ask'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ElevatedButton.icon(
                  onPressed: () => _openInquiry(initial: InquiryKindOption.viewing),
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(_isSwahili ? 'Ona' : 'Tour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ),
            if (l.listingKind == ListingKind.sale)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    onPressed: () => _openInquiry(initial: InquiryKindOption.offer),
                    icon: const Icon(Icons.attach_money_rounded, size: 16),
                    label: Text(_isSwahili ? 'Toa Bei' : 'Offer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}
