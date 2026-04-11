// lib/fitness/pages/browse_gyms_page.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';
import '../widgets/gym_card.dart';
import 'gym_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BrowseGymsPage extends StatefulWidget {
  final int userId;
  const BrowseGymsPage({super.key, required this.userId});
  @override
  State<BrowseGymsPage> createState() => _BrowseGymsPageState();
}

class _BrowseGymsPageState extends State<BrowseGymsPage> {
  final FitnessService _service = FitnessService();
  final TextEditingController _searchController = TextEditingController();
  List<Gym> _gyms = [];
  bool _isLoading = true;
  bool _streamingOnly = false;

  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.findGyms(
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      hasStreaming: _streamingOnly ? true : null,
    );
    if (mounted) setState(() { _isLoading = false; if (result.success) _gyms = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(backgroundColor: _kCardBg, elevation: 0, scrolledUnderElevation: 1, title: const Text('Tafuta Gym', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController, onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'Tafuta gym kwa jina...', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: _kSecondary), filled: true, fillColor: _kCardBg,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              FilterChip(
                label: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.live_tv_rounded, size: 14), SizedBox(width: 4), Text('Live Streaming', style: TextStyle(fontSize: 12))]),
                selected: _streamingOnly, selectedColor: _kPrimary.withValues(alpha: 0.15),
                onSelected: (v) { setState(() => _streamingOnly = v); _load(); },
              ),
            ]),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                : _gyms.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.fitness_center_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16),
                        Text('Hakuna gym', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      ]))
                    : RefreshIndicator(
                        onRefresh: _load, color: _kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16), itemCount: _gyms.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GymCard(gym: _gyms[i], onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GymDetailPage(userId: widget.userId, gym: _gyms[i]))).then((_) { if (mounted) _load(); })),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
