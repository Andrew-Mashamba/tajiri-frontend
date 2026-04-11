// lib/huduma/pages/huduma_home_page.dart
import 'package:flutter/material.dart';
import '../models/huduma_models.dart';
import '../services/huduma_service.dart';
import '../widgets/sermon_card.dart';
import 'sermon_player_page.dart';
import 'speakers_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class HudumaHomePage extends StatefulWidget {
  final int userId;
  const HudumaHomePage({super.key, required this.userId});
  @override
  State<HudumaHomePage> createState() => _HudumaHomePageState();
}

class _HudumaHomePageState extends State<HudumaHomePage> {
  List<Sermon> _sermons = [];
  List<Speaker> _speakers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      HudumaService.getSermons(),
      HudumaService.getSpeakers(),
    ]);
    if (mounted) {
      final serR = results[0] as PaginatedResult<Sermon>;
      final spkR = results[1] as PaginatedResult<Speaker>;
      setState(() {
        _isLoading = false;
        if (serR.success) _sermons = serR.items;
        if (spkR.success) _speakers = spkR.items;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
        : RefreshIndicator(
            onRefresh: _load,
            color: _kPrimary,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Search button
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded, size: 24, color: _kPrimary),
                    onPressed: _showSearch,
                  ),
                ),
                  // Speakers row
                  if (_speakers.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Wahubiri / Speakers',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                        TextButton(
                          onPressed: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SpeakersPage())),
                          child: const Text('Wote / All', style: TextStyle(color: _kPrimary, fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _speakers.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final sp = _speakers[i];
                          return GestureDetector(
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => const SpeakersPage())),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage: sp.photoUrl != null ? NetworkImage(sp.photoUrl!) : null,
                                  child: sp.photoUrl == null
                                      ? const Icon(Icons.person_rounded, color: _kSecondary)
                                      : null,
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 70,
                                  child: Text(sp.name,
                                      style: const TextStyle(fontSize: 11, color: _kPrimary),
                                      maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Sermons
                  const Text('Mahubiri / Sermons',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 10),
                  if (_sermons.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: const Text('Hakuna mahubiri / No sermons',
                          style: TextStyle(color: _kSecondary, fontSize: 13)),
                    )
                  else
                    ..._sermons.map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: SermonCard(
                            sermon: s,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => SermonPlayerPage(sermon: s))),
                          ),
                        )),
                  const SizedBox(height: 24),
                ],
              ),
            );
  }

  void _showSearch() async {
    final query = await showSearch<String>(
      context: context,
      delegate: _SermonSearchDelegate(),
    );
    if (query != null && query.isNotEmpty && mounted) {
      final r = await HudumaService.search(query: query);
      if (r.success && r.items.isNotEmpty && mounted) {
        setState(() => _sermons = r.items);
      }
    }
  }
}

class _SermonSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => query = ''),
      ];
  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => close(context, ''));
  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }
  @override
  Widget buildSuggestions(BuildContext context) =>
      const Center(child: Text('Tafuta hubiri... / Search sermons...', style: TextStyle(color: _kSecondary)));
}
