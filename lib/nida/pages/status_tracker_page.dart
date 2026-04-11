// lib/nida/pages/status_tracker_page.dart
import 'package:flutter/material.dart';
import '../models/nida_models.dart';
import '../services/nida_service.dart';
import '../widgets/status_timeline.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class StatusTrackerPage extends StatefulWidget {
  final int userId;
  const StatusTrackerPage({super.key, required this.userId});
  @override
  State<StatusTrackerPage> createState() => _StatusTrackerPageState();
}

class _StatusTrackerPageState extends State<StatusTrackerPage> {
  final _ctrl = TextEditingController();
  NidaApplication? _app;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final result = await NidaService.checkStatus(q);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.data != null) {
        _app = result.data;
      } else {
        _error = result.message ?? 'Haikupatikana';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Fuatilia Hali',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Ingiza nambari ya risiti au NIDA yako',
              style: TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. 19900101-12345-67890-12',
                    hintStyle: const TextStyle(fontSize: 12, color: _kSecondary),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ],
          if (_app != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Risiti: ${_app!.receiptNumber}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
                  if (_app!.nidaNumber != null)
                    Text('NIDA: ${_app!.nidaNumber}',
                        style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  if (_app!.officeName != null)
                    Text('Ofisi: ${_app!.officeName}',
                        style: const TextStyle(fontSize: 13, color: _kSecondary)),
                  const SizedBox(height: 16),
                  StatusTimeline(currentStage: _app!.stageIndex),
                  if (_app!.estimatedDate != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tarehe inayokadiriwa: ${_app!.estimatedDate!.day}/${_app!.estimatedDate!.month}/${_app!.estimatedDate!.year}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
