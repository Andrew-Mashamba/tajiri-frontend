// lib/government/pages/nhif_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/government_models.dart';
import '../services/government_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class NhifPage extends StatefulWidget {
  final int userId;
  const NhifPage({super.key, required this.userId});
  @override
  State<NhifPage> createState() => _NhifPageState();
}

class _NhifPageState extends State<NhifPage> {
  final GovernmentService _service = GovernmentService();
  final _memberController = TextEditingController();

  NhifInfo? _result;
  bool _isSearching = false;
  String? _error;

  @override
  void dispose() {
    _memberController.dispose();
    super.dispose();
  }

  Future<void> _lookup() async {
    final number = _memberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingiza nambari ya mwanachama')),
      );
      return;
    }

    setState(() { _isSearching = true; _error = null; _result = null; });

    final result = await _service.lookupNhif(
      userId: widget.userId,
      memberNumber: number,
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

  Future<void> _openNhifPortal() async {
    final uri = Uri.parse('https://www.nhif.or.tz');
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
        title: const Text('NHIF', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mfuko wa Taifa wa Bima ya Afya', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                      Text('National Health Insurance Fund', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Search
          const Text('Nambari ya Mwanachama', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _memberController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
              hintText: 'NHIF Member Number',
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
                  : const Text('Angalia Hali', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 20),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
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
                  color: _result!.isActive
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: _result!.isActive ? const Color(0xFF4CAF50) : Colors.red,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _result!.isActive ? 'Bima Hai' : 'Hali: ${_result!.status}',
                        style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600,
                          color: _result!.isActive ? const Color(0xFF4CAF50) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  if (_result!.memberName != null) _InfoRow(label: 'Jina', value: _result!.memberName!),
                  _InfoRow(label: 'Nambari', value: _result!.memberNumber),
                  if (_result!.packageType != null) _InfoRow(label: 'Kifurushi', value: _result!.packageType!),
                  _InfoRow(label: 'Wategemezi', value: '${_result!.dependants}'),
                  if (_result!.expiresAt != null)
                    _InfoRow(
                      label: 'Inaisha',
                      value: '${_result!.expiresAt!.day}/${_result!.expiresAt!.month}/${_result!.expiresAt!.year}',
                    ),
                  if (_result!.isExpired) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded, size: 16, color: Colors.red.shade700),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Bima yako imeisha muda. Tafadhali fanya upya.',
                              style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // NHIF Portal link
          Material(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openNhifPortal,
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
                          Text('NHIF Portal', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
                          Text('Fungua tovuti ya NHIF', style: TextStyle(fontSize: 12, color: _kSecondary)),
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
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontSize: 13, color: _kSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary))),
        ],
      ),
    );
  }
}
