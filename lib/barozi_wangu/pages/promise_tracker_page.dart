// lib/barozi_wangu/pages/promise_tracker_page.dart
import 'package:flutter/material.dart';
import '../models/barozi_wangu_models.dart';
import '../services/barozi_wangu_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class PromiseTrackerPage extends StatefulWidget {
  final int councillorId;
  const PromiseTrackerPage({super.key, required this.councillorId});

  @override
  State<PromiseTrackerPage> createState() => _PromiseTrackerPageState();
}

class _PromiseTrackerPageState extends State<PromiseTrackerPage> {
  List<CampaignPromise> _promises = [];
  bool _loading = true;

  final _service = BaroziWanguService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getPromises(widget.councillorId);
    if (mounted) {
      setState(() {
        _promises = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text(
          'Ahadi za Uchaguzi',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _promises.isEmpty
              ? const Center(
                  child: Text(
                    'Hakuna ahadi zilizorekodiwa',
                    style: TextStyle(color: _kSecondary, fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _promises.length,
                    itemBuilder: (_, i) => _buildPromise(_promises[i]),
                  ),
                ),
    );
  }

  Widget _buildPromise(CampaignPromise promise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promise.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _statusBadge(promise.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thumb_up_rounded,
                  size: 14, color: _kSecondary),
              const SizedBox(width: 4),
              Text(
                '${promise.communityVotes}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
              ),
              const Spacer(),
              Text(
                promise.createdAt.split('T').first,
                style: const TextStyle(fontSize: 11, color: _kSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(PromiseStatus status) {
    final (label, color) = switch (status) {
      PromiseStatus.kept => ('Imetimizwa', const Color(0xFF4CAF50)),
      PromiseStatus.inProgress => ('Inaendelea', const Color(0xFFFFA000)),
      PromiseStatus.broken => ('Imevunjwa', const Color(0xFFE53935)),
      PromiseStatus.notStarted => ('Haijaanza', _kSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
