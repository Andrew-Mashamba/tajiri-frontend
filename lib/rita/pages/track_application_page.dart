// lib/rita/pages/track_application_page.dart
import 'package:flutter/material.dart';
import '../models/rita_models.dart';
import '../services/rita_service.dart';
import '../widgets/application_timeline.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TrackApplicationPage extends StatefulWidget {
  const TrackApplicationPage({super.key});
  @override
  State<TrackApplicationPage> createState() => _TrackApplicationPageState();
}

class _TrackApplicationPageState extends State<TrackApplicationPage> {
  final _ctrl = TextEditingController();
  CertificateApplication? _app;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; _app = null; });
    final result = await RitaService.trackApplication(q);
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
        title: const Text('Fuatilia Ombi',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Ingiza nambari ya ufuatiliaji',
              style: TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Tracking number',
                hintStyle: const TextStyle(fontSize: 13, color: _kSecondary),
                filled: true, fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              style: const TextStyle(fontSize: 14, color: _kPrimary),
            )),
            const SizedBox(width: 8),
            SizedBox(height: 48, child: ElevatedButton(
              onPressed: _loading ? null : _track,
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search_rounded, color: Colors.white),
            )),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          if (_app != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_app!.typeLabel,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary))),
                  Text('#${_app!.trackingNumber}',
                      style: const TextStyle(fontSize: 12, color: _kSecondary)),
                ]),
                if (_app!.holderName != null) ...[
                  const SizedBox(height: 4),
                  Text('Jina: ${_app!.holderName}',
                      style: const TextStyle(fontSize: 13, color: _kSecondary)),
                ],
                const SizedBox(height: 16),
                ApplicationTimeline(currentStage: _app!.stageIndex),
                if (_app!.collectionOffice != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: _kSecondary),
                    const SizedBox(width: 4),
                    Expanded(child: Text('Kuchukua: ${_app!.collectionOffice}',
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
