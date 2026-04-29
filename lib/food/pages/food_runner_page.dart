import 'package:flutter/material.dart';

import '../models/food_run.dart';
import '../services/food_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);

class FoodRunnerPage extends StatefulWidget {
  final int userId;
  const FoodRunnerPage({super.key, required this.userId});

  @override
  State<FoodRunnerPage> createState() => _FoodRunnerPageState();
}

class _FoodRunnerPageState extends State<FoodRunnerPage> with SingleTickerProviderStateMixin {
  final FoodService _service = FoodService();
  late TabController _tabs;
  List<FoodRun> _available = const [];
  List<FoodRun> _mine = const [];
  bool _loadingAvailable = true;
  bool _loadingMine = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadBoth();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadBoth() async {
    await Future.wait([_loadAvailable(), _loadMine()]);
  }

  Future<void> _loadAvailable() async {
    setState(() {
      _loadingAvailable = true;
      _error = null;
    });
    final res = await _service.listFoodRuns(status: 'unclaimed');
    if (!mounted) return;
    if (res.success) {
      setState(() {
        _available = res.items.map(FoodRun.fromJson).toList();
        _loadingAvailable = false;
      });
    } else {
      setState(() {
        _error = res.message ?? 'Imeshindwa';
        _loadingAvailable = false;
      });
    }
  }

  Future<void> _loadMine() async {
    setState(() => _loadingMine = true);
    final res = await _service.myFoodRuns(userId: widget.userId);
    if (!mounted) return;
    if (res.success) {
      setState(() {
        _mine = res.items.map(FoodRun.fromJson).toList();
        _loadingMine = false;
      });
    } else {
      setState(() => _loadingMine = false);
    }
  }

  Future<void> _claim(FoodRun run) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.claimFoodRun(runId: run.id, runnerUserId: widget.userId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(res.success ? 'Umechukua safari' : (res.message ?? 'Imeshindwa'))));
    if (res.success) {
      _tabs.animateTo(1);
      _loadBoth();
    }
  }

  Future<void> _release(FoodRun run) async {
    final messenger = ScaffoldMessenger.of(context);
    final reason = await _promptReason();
    if (reason == null) return;
    final res = await _service.releaseFoodRun(runId: run.id, runnerUserId: widget.userId, reason: reason);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(res.success ? 'Safari imeachwa' : (res.message ?? 'Imeshindwa'))));
    if (res.success) _loadBoth();
  }

  Future<void> _updateStatus(FoodRun run, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final res = await _service.updateFoodRunStatus(
      runId: run.id,
      runnerUserId: widget.userId,
      status: status,
    );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(res.success ? 'Imefanikiwa' : (res.message ?? 'Imeshindwa'))));
    if (res.success) _loadMine();
  }

  Future<String?> _promptReason() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sababu ya kuachia'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'Sababu (hiari)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Ghairi')),
          TextButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Achia')),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        title: const Text('Chukua Safari', style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          tabs: const [
            Tab(text: 'Zinazopatikana'),
            Tab(text: 'Zangu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _availableList(),
          _myList(),
        ],
      ),
    );
  }

  Widget _availableList() {
    if (_loadingAvailable) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48, color: _kSecondary),
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(fontSize: 13, color: _kSecondary), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _loadAvailable, child: const Text('Jaribu tena')),
            ],
          ),
        ),
      );
    }
    if (_available.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_bike_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Hakuna safari kwa sasa',
                style: TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAvailable,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _available.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _runCard(_available[i], isMine: false),
      ),
    );
  }

  Widget _myList() {
    if (_loadingMine) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }
    if (_mine.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Hujachukua safari bado',
                style: TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadMine,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mine.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _runCard(_mine[i], isMine: true),
      ),
    );
  }

  Widget _runCard(FoodRun run, {required bool isMine}) {
    Color statusColor;
    String statusLabel;
    switch (run.status) {
      case 'unclaimed':
        statusColor = const Color(0xFFE67E22);
        statusLabel = 'Bure';
        break;
      case 'claimed':
        statusColor = const Color(0xFF1976D2);
        statusLabel = 'Imechukuliwa';
        break;
      case 'picking_up':
        statusColor = const Color(0xFF8E24AA);
        statusLabel = 'Inachukuliwa';
        break;
      case 'delivered':
        statusColor = _kAccent;
        statusLabel = 'Imefikishwa';
        break;
      default:
        statusColor = _kSecondary;
        statusLabel = run.status;
    }
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                  ),
                ),
                const Spacer(),
                Text(
                  '${run.portions} milo',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                ),
                if (run.distanceKm != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${run.distanceKm!.toStringAsFixed(1)} km',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _routeRow(Icons.restaurant_rounded, 'Mpishi', run.chefName ?? '—', run.pickupAddress),
            const SizedBox(height: 8),
            _routeRow(Icons.volunteer_activism_rounded, 'Shirika', run.orgName ?? '—', run.dropoffAddress),
            const SizedBox(height: 12),
            if (!isMine && run.isUnclaimed)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _claim(run),
                  icon: const Icon(Icons.directions_bike_rounded, size: 16),
                  label: const Text('Chukua safari'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            if (isMine && run.isClaimed) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _release(run),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kPrimary,
                        side: BorderSide(color: _kPrimary.withValues(alpha: 0.2)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Achia'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(run, 'picking_up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Ninachukua'),
                    ),
                  ),
                ],
              ),
            ],
            if (isMine && run.isPickingUp) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(run, 'delivered'),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Nimefikisha'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String name, String? address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _kSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label: $name',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (address != null && address.isNotEmpty)
                Text(
                  address,
                  style: const TextStyle(fontSize: 11, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
