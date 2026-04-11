// lib/nightlife/pages/nightlife_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/nightlife_models.dart';
import '../services/nightlife_service.dart';
import '../widgets/venue_card.dart';
import '../widgets/event_card.dart';
import 'venue_detail_page.dart';
import 'reserve_table_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class NightlifeHomePage extends StatefulWidget {
  final int userId;
  const NightlifeHomePage({super.key, required this.userId});
  @override
  State<NightlifeHomePage> createState() => _NightlifeHomePageState();
}

class _NightlifeHomePageState extends State<NightlifeHomePage> {
  List<Venue> _venues = [];
  List<NightlifeEvent> _tonightEvents = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      NightlifeService.getVenues(),
      NightlifeService.getTonightsEvents(),
    ]);
    if (!mounted) return;
    final vr = results[0] as PaginatedResult<Venue>;
    final er = results[1] as PaginatedResult<NightlifeEvent>;
    setState(() {
      _isLoading = false;
      if (vr.success) _venues = vr.items;
      if (er.success) _tonightEvents = er.items;
    });
    if (!vr.success && !er.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Imeshindwa kupakia data'
            : 'Failed to load data'),
      ));
    }
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child:
                CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _loadData,
            color: _kPrimary,
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                  // Tonight's events
                  if (_tonightEvents.isNotEmpty) ...[
                    Text(
                      _isSwahili ? 'Usiku huu' : 'Tonight',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary),
                    ),
                    const SizedBox(height: 10),
                    ..._tonightEvents.take(5).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: NightlifeEventCard(
                            event: e,
                            isSwahili: _isSwahili,
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Reserve button
                  GestureDetector(
                    onTap: _venues.isNotEmpty
                        ? () => _nav(ReserveTablePage(venues: _venues))
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.table_bar_rounded,
                              color: Colors.white, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _isSwahili
                                  ? 'Weka Nafasi ya Meza'
                                  : 'Reserve a Table',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Venues
                  Text(
                    _isSwahili ? 'Maeneo' : 'Venues',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary),
                  ),
                  const SizedBox(height: 10),
                  if (_venues.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          _isSwahili
                              ? 'Hakuna maeneo'
                              : 'No venues found',
                          style: const TextStyle(
                              fontSize: 14, color: _kSecondary),
                        ),
                      ),
                    )
                  else
                    ..._venues.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: VenueCard(
                            venue: v,
                            isSwahili: _isSwahili,
                            onTap: () => _nav(VenueDetailPage(venue: v)),
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }
}
