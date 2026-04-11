// lib/government/pages/nida_page.dart
import 'package:flutter/material.dart';
import '../models/government_models.dart';
import '../services/government_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class NidaPage extends StatefulWidget {
  final int userId;
  const NidaPage({super.key, required this.userId});
  @override
  State<NidaPage> createState() => _NidaPageState();
}

class _NidaPageState extends State<NidaPage> {
  final GovernmentService _service = GovernmentService();
  final _nidaController = TextEditingController();

  NidaInfo? _result;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _nidaController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final number = _nidaController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya NIDA')),
      );
      return;
    }

    setState(() { _isSearching = true; _error = null; _result = null; });

    final result = await _service.lookupNida(
      userId: widget.userId,
      nidaNumber: number,
    );

    if (mounted) {
      setState(() {
        _isSearching = false;
        if (result.success && result.data != null) {
          _result = result.data;
        } else {
          _error = result.message ?? 'Imeshindwa kuthibitisha';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0, scrolledUnderElevation: 1,
        title: const Text('NIDA', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kitambulisho cha Taifa', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text('National Identification Authority', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search field
          const Text('Nambari ya NIDA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _nidaController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: '19XXXXXXXXXX-XXXXX-XXXXX-XX',
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
                  : const Text('Thibitisha', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                  color: _result!.isVerified
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
                        _result!.isVerified ? Icons.verified_rounded : Icons.pending_rounded,
                        color: _result!.isVerified ? const Color(0xFF4CAF50) : Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.isVerified ? 'Imethibitishwa' : 'Hali: ${_result!.status}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _result!.isVerified ? const Color(0xFF4CAF50) : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_result!.fullName != null) _InfoRow(label: 'Jina', value: _result!.fullName!),
                  _InfoRow(label: 'Nambari', value: _result!.number),
                  if (_result!.dateOfBirth != null) _InfoRow(label: 'Tarehe ya Kuzaliwa', value: _result!.dateOfBirth!),
                  if (_result!.gender != null) _InfoRow(label: 'Jinsia', value: _result!.gender!),
                  _InfoRow(label: 'Hali', value: _result!.status),
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
