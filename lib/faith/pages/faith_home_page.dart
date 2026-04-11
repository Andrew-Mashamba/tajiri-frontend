// lib/faith/pages/faith_home_page.dart
import 'package:flutter/material.dart';
import '../models/faith_models.dart';
import '../services/faith_service.dart';
import '../widgets/worship_place_card.dart';
import '../widgets/prayer_time_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class FaithHomePage extends StatefulWidget {
  final int userId;
  const FaithHomePage({super.key, required this.userId});
  @override
  State<FaithHomePage> createState() => _FaithHomePageState();
}

class _FaithHomePageState extends State<FaithHomePage> {
  final FaithService _service = FaithService();

  FaithPreference? _preference;
  DailyInspiration? _inspiration;
  PrayerTimes? _prayerTimes;
  List<PlaceOfWorship> _nearbyPlaces = [];
  bool _isLoading = true;
  bool _isSettingFaith = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final prefResult = await _service.getPreference(widget.userId);
    if (mounted) {
      if (prefResult.success && prefResult.data != null) {
        _preference = prefResult.data;
        await _loadFaithContent();
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFaithContent() async {
    if (_preference == null) return;
    final results = await Future.wait([
      _service.getDailyInspiration(faith: _preference!.faith),
      if (_preference!.faith == FaithType.islam)
        _service.getPrayerTimes(latitude: -6.7924, longitude: 39.2083)
      else
        Future.value(FaithResult<PrayerTimes>(success: false)),
      _service.getNearbyPlaces(latitude: -6.7924, longitude: 39.2083),
    ]);
    if (mounted) {
      final inspResult = results[0] as FaithResult<DailyInspiration>;
      final prayerResult = results[1] as FaithResult<PrayerTimes>;
      final placesResult = results[2] as FaithListResult<PlaceOfWorship>;
      setState(() {
        if (inspResult.success) _inspiration = inspResult.data;
        if (prayerResult.success) _prayerTimes = prayerResult.data;
        if (placesResult.success) _nearbyPlaces = placesResult.items;
      });
    }
  }

  Future<void> _setFaith(FaithType faith) async {
    setState(() => _isSettingFaith = true);
    final result = await _service.setPreference(
      userId: widget.userId,
      faith: faith,
    );
    if (mounted) {
      setState(() => _isSettingFaith = false);
      if (result.success) {
        _preference = result.data;
        await _loadFaithContent();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    if (_preference == null) return _buildFaithSelector();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _preference!.faith == FaithType.islam ? Icons.mosque_rounded : Icons.church_rounded,
                      color: Colors.white, size: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text('Imani Yangu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _preference!.faith == FaithType.islam
                      ? 'Sala, msikiti, na msukumo wa kila siku.'
                      : 'Ibada, kanisa, na msukumo wa kila siku.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Daily Inspiration
          if (_inspiration != null) ...[
            const Text('Msukumo wa Leo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text("Today's Inspiration", style: TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: _kPrimary, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _inspiration!.text,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _kPrimary, height: 1.5, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Text('— ${_inspiration!.source}', style: const TextStyle(fontSize: 13, color: _kSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Prayer Times (Islam only)
          if (_prayerTimes != null) ...[
            const Text('Nyakati za Sala', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('Prayer Times', style: TextStyle(fontSize: 12, color: _kSecondary)),
            const SizedBox(height: 10),
            ..._prayerTimes!.allPrayers.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: PrayerTimeCard(name: entry.key, time: entry.value),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Nearby Places
          const Text('Maeneo ya Ibada', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Nearby Places of Worship', style: TextStyle(fontSize: 12, color: _kSecondary)),
          const SizedBox(height: 10),
          if (_nearbyPlaces.isNotEmpty)
            ..._nearbyPlaces.take(5).map((place) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: WorshipPlaceCard(place: place),
                ))
          else
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.location_off_outlined, size: 48, color: _kSecondary),
                  SizedBox(height: 8),
                  Text('Hakuna maeneo ya karibu', style: TextStyle(color: _kSecondary, fontSize: 14)),
                ],
              ),
            ),

          // Change faith preference
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _preference = null),
              child: const Text(
                'Badilisha imani / Change faith preference',
                style: TextStyle(color: _kSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFaithSelector() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mosque_outlined, size: 56, color: _kPrimary),
            const SizedBox(height: 16),
            const Text('Imani Yangu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 4),
            const Text('My Faith', style: TextStyle(fontSize: 14, color: _kSecondary)),
            const SizedBox(height: 8),
            const Text(
              'Chagua imani yako ili tuonyeshe maudhui yanayofaa.',
              style: TextStyle(fontSize: 14, color: _kSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_isSettingFaith)
              const CircularProgressIndicator(strokeWidth: 2, color: _kPrimary)
            else ...[
              _FaithOptionTile(
                icon: Icons.mosque_rounded,
                label: 'Uislamu / Islam',
                onTap: () => _setFaith(FaithType.islam),
              ),
              const SizedBox(height: 10),
              _FaithOptionTile(
                icon: Icons.church_rounded,
                label: 'Ukristo / Christianity',
                onTap: () => _setFaith(FaithType.christianity),
              ),
              const SizedBox(height: 10),
              _FaithOptionTile(
                icon: Icons.auto_awesome_rounded,
                label: 'Nyingine / Other',
                onTap: () => _setFaith(FaithType.other),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FaithOptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FaithOptionTile({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: _kPrimary),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          ],
        ),
      ),
    );
  }
}
