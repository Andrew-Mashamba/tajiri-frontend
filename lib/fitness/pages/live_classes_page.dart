// lib/fitness/pages/live_classes_page.dart
import 'package:flutter/material.dart';
import '../models/fitness_models.dart';
import '../services/fitness_service.dart';
import '../widgets/class_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

class LiveClassesPage extends StatefulWidget {
  final int userId;
  final WorkoutType? initialType;
  const LiveClassesPage({super.key, required this.userId, this.initialType});
  @override
  State<LiveClassesPage> createState() => _LiveClassesPageState();
}

class _LiveClassesPageState extends State<LiveClassesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FitnessService _service = FitnessService();
  List<FitnessClass> _live = [];
  List<FitnessClass> _onDemand = [];
  bool _isLoadingLive = true;
  bool _isLoadingOnDemand = true;
  WorkoutType? _filterType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filterType = widget.initialType;
    _loadAll();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    await Future.wait([_loadLive(), _loadOnDemand()]);
  }

  Future<void> _loadLive() async {
    setState(() => _isLoadingLive = true);
    final result = await _service.getClasses(liveOnly: true, workoutType: _filterType?.name);
    if (mounted) setState(() { _isLoadingLive = false; if (result.success) _live = result.items; });
  }

  Future<void> _loadOnDemand() async {
    setState(() => _isLoadingOnDemand = true);
    final result = await _service.getClasses(recordedOnly: true, workoutType: _filterType?.name);
    if (mounted) setState(() { _isLoadingOnDemand = false; if (result.success) _onDemand = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Madarasa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController, labelColor: _kPrimary, unselectedLabelColor: _kSecondary, indicatorColor: _kPrimary,
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.circle, size: 8, color: Colors.red), const SizedBox(width: 6), Text('Live (${_live.length})')])),
            Tab(text: 'Rekodi (${_onDemand.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Workout type filter
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Zote', style: TextStyle(fontSize: 12)),
                    selected: _filterType == null, selectedColor: _kPrimary.withValues(alpha: 0.15),
                    onSelected: (_) { setState(() => _filterType = null); _loadAll(); },
                  ),
                ),
                ...WorkoutType.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Row(mainAxisSize: MainAxisSize.min, children: [Icon(t.icon, size: 14), const SizedBox(width: 4), Text(t.displayName, style: const TextStyle(fontSize: 12))]),
                        selected: _filterType == t, selectedColor: _kPrimary.withValues(alpha: 0.15),
                        onSelected: (_) { setState(() => _filterType = _filterType == t ? null : t); _loadAll(); },
                      ),
                    )),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(_live, _isLoadingLive),
                _buildList(_onDemand, _isLoadingOnDemand),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<FitnessClass> classes, bool isLoading) {
    if (isLoading) return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    if (classes.isEmpty) return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.live_tv_outlined, size: 64, color: Colors.grey.shade300), const SizedBox(height: 16), Text('Hakuna madarasa', style: TextStyle(fontSize: 16, color: Colors.grey.shade500))],
    ));
    return RefreshIndicator(
      onRefresh: _loadAll, color: _kPrimary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: classes.length,
        itemBuilder: (context, i) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ClassCard(fitnessClass: classes[i])),
      ),
    );
  }
}
