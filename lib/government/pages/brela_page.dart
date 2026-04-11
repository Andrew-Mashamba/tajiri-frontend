// lib/government/pages/brela_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/government_models.dart';
import '../services/government_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class BrelaPage extends StatefulWidget {
  final int userId;
  const BrelaPage({super.key, required this.userId});
  @override
  State<BrelaPage> createState() => _BrelaPageState();
}

class _BrelaPageState extends State<BrelaPage> {
  final GovernmentService _service = GovernmentService();
  final _searchController = TextEditingController();

  List<BrelaInfo> _results = [];
  bool _isSearching = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final name = _searchController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza jina la biashara')),
      );
      return;
    }

    setState(() { _isSearching = true; _error = null; _results = []; _hasSearched = true; });

    final result = await _service.searchBrela(
      userId: widget.userId,
      businessName: name,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result.success) {
          _results = result.items;
        } else {
          _error = result.message ?? 'Imeshindwa kutafuta';
        }
      });
    }
  }

  Future<void> _openBrelaPortal() async {
    final uri = Uri.parse('https://www.brela.go.tz');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('BRELA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.business_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Usajili wa Biashara', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Business Registrations & Licensing Agency', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search
          const Text('Tafuta Jina la Biashara', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Mfano: Tajiri Technologies',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: _kSecondary),
              filled: true, fillColor: _kCardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _kPrimary, width: 2)),
            ),
          ),
          const SizedBox(height: 14),

          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isSearching ? null : _search,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSearching
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tafuta', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(fontSize: 13, color: Colors.red.shade700))),
                ],
              ),
            ),

          // Results
          if (_hasSearched && !_isSearching && _results.isEmpty && _error == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text('Hakuna biashara iliyopatikana', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                  ],
                ),
              ),
            ),

          ..._results.map((biz) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: biz.isRegistered
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                        : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            biz.businessName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: biz.isRegistered
                                ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            biz.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: biz.isRegistered ? const Color(0xFF4CAF50) : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (biz.registrationNumber != null)
                      _InfoRow(label: 'Nambari', value: biz.registrationNumber!),
                    if (biz.businessType != null)
                      _InfoRow(label: 'Aina', value: biz.businessType!),
                  ],
                ),
              )),
          const SizedBox(height: 20),

          // BRELA Portal link
          Material(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openBrelaPortal,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: _kPrimary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.open_in_new_rounded, size: 20, color: _kPrimary),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BRELA Portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                          Text('Sajili biashara yako mtandaoni', style: TextStyle(fontSize: 12, color: _kSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: _kSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary))),
        ],
      ),
    );
  }
}
