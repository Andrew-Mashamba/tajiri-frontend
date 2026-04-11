// lib/government/pages/tra_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/government_models.dart';
import '../services/government_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class TraPage extends StatefulWidget {
  final int userId;
  const TraPage({super.key, required this.userId});
  @override
  State<TraPage> createState() => _TraPageState();
}

class _TraPageState extends State<TraPage> {
  final GovernmentService _service = GovernmentService();
  final _tinController = TextEditingController();

  TinInfo? _result;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _tinController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final number = _tinController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya TIN')),
      );
      return;
    }

    setState(() { _isSearching = true; _error = null; _result = null; });

    final result = await _service.lookupTin(
      userId: widget.userId,
      tinNumber: number,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result.success && result.data != null) {
          _result = result.data;
        } else {
          _error = result.message ?? 'Imeshindwa kutafuta';
        }
      });
    }
  }

  Future<void> _openTraPortal() async {
    final uri = Uri.parse('https://www.tra.go.tz');
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
        title: const Text('TRA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mamlaka ya Mapato Tanzania', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('Tanzania Revenue Authority', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // TIN Lookup
          const Text('Nambari ya TIN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _tinController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Mfano: 100-123-456',
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
              onPressed: _isSearching ? null : _lookup,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSearching
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Tafuta TIN', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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

          // Result
          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _result!.isCompliant
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.isCompliant ? Icons.verified_rounded : Icons.warning_rounded,
                        color: _result!.isCompliant ? const Color(0xFF4CAF50) : Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.isCompliant ? 'Amezingatia Kodi' : 'Hali: ${_result!.status}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _result!.isCompliant ? const Color(0xFF4CAF50) : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _InfoRow(label: 'TIN', value: _result!.number),
                  if (_result!.businessName != null) _InfoRow(label: 'Biashara', value: _result!.businessName!),
                  if (_result!.ownerName != null) _InfoRow(label: 'Mmiliki', value: _result!.ownerName!),
                  if (_result!.taxType != null) _InfoRow(label: 'Aina ya Kodi', value: _result!.taxType!),
                  _InfoRow(label: 'Hali', value: _result!.status),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // TRA Portal link
          Material(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openTraPortal,
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
                          Text('TRA Portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                          Text('Fungua tovuti ya TRA', style: TextStyle(fontSize: 12, color: _kSecondary)),
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
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
          ),
        ],
      ),
    );
  }
}
