// lib/ofisi_mtaa/pages/my_applications_page.dart
import 'package:flutter/material.dart';
import '../models/ofisi_mtaa_models.dart';
import '../services/ofisi_mtaa_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MyApplicationsPage extends StatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  State<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends State<MyApplicationsPage> {
  List<ServiceRequest> _requests = [];
  bool _loading = true;

  final _service = OfisiMtaaService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getMyRequests();
    if (mounted) {
      setState(() {
        _requests = result.items;
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
          'Maombi Yangu',
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
          : _requests.isEmpty
              ? const Center(
                  child: Text(
                    'Huna maombi yoyote',
                    style: TextStyle(color: _kSecondary, fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (_, i) => _buildRequest(_requests[i]),
                  ),
                ),
    );
  }

  Widget _buildRequest(ServiceRequest req) {
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
          Text(
            req.serviceType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // ── Timeline ──
          _timelineStep('Imepokelewa', req.status.index >= 0, true),
          _timelineStep(
              'Inakaguliwa', req.status.index >= 1, req.status.index >= 1),
          _timelineStep('Tayari kuchukuliwa', req.status.index >= 2,
              req.status.index >= 2),
          const SizedBox(height: 8),
          if (req.estimatedDate.isNotEmpty)
            Text(
              'Muda: ${req.estimatedDate.split("T").first}',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
        ],
      ),
    );
  }

  Widget _timelineStep(String label, bool reached, bool active) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? _kPrimary : const Color(0xFFDDDDDD),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: reached ? _kPrimary : _kSecondary,
              fontWeight: reached ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
