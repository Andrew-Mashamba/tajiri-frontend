// lib/owners_club/pages/vehicle_showcase_page.dart
import 'package:flutter/material.dart';
import '../models/owners_club_models.dart';
import '../services/owners_club_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class VehicleShowcasePage extends StatefulWidget {
  final Community community;
  const VehicleShowcasePage({super.key, required this.community});
  @override
  State<VehicleShowcasePage> createState() => _VehicleShowcasePageState();
}

class _VehicleShowcasePageState extends State<VehicleShowcasePage> {
  final OwnersClubService _service = OwnersClubService();
  List<VehicleShowcase> _showcases = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getShowcases(widget.community.id);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _showcases = result.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Vehicle Showcase', style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _showcases.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.directions_car_rounded, size: 48, color: _kSecondary),
                      SizedBox(height: 12),
                      Text('No showcases yet', style: TextStyle(color: _kSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _showcases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final s = _showcases[i];
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero image
                            if (s.photos.isNotEmpty)
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  s.photos.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE8E8E8),
                                    child: const Icon(Icons.directions_car_rounded,
                                        size: 48, color: _kSecondary),
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 120,
                                color: const Color(0xFFE8E8E8),
                                child: const Center(
                                    child: Icon(Icons.directions_car_rounded,
                                        size: 48, color: _kSecondary)),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.title,
                                      style: const TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('by ${s.userName ?? 'Member'}',
                                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                  if (s.story != null && s.story!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(s.story!,
                                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      const Icon(Icons.build_rounded, size: 14, color: _kSecondary),
                                      const SizedBox(width: 4),
                                      Text('${s.modifications.length} mods',
                                          style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.thumb_up_alt_rounded, size: 14, color: _kSecondary),
                                      const SizedBox(width: 4),
                                      Text('${s.votes}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.photo_library_rounded, size: 14, color: _kSecondary),
                                      const SizedBox(width: 4),
                                      Text('${s.photos.length}', style: const TextStyle(fontSize: 12, color: _kSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
