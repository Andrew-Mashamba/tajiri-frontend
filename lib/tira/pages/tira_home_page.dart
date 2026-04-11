// lib/tira/pages/tira_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/tira_models.dart';
import '../services/tira_service.dart';
import '../widgets/policy_card.dart';
import 'insurer_directory_page.dart';
import 'tira_complaint_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class TiraHomePage extends StatefulWidget {
  final int userId;
  const TiraHomePage({super.key, required this.userId});
  @override
  State<TiraHomePage> createState() => _TiraHomePageState();
}

class _TiraHomePageState extends State<TiraHomePage> {
  bool _isSwahili = true;
  bool _isVerifying = false;
  InsurancePolicy? _policy;
  final _policyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _policyCtrl.dispose();
    super.dispose();
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _verify() async {
    if (_policyCtrl.text.trim().isEmpty) return;
    setState(() {
      _isVerifying = true;
      _policy = null;
    });

    final r = await TiraService.verifyPolicy(_policyCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _isVerifying = false;
      if (r.success) _policy = r.data;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.message ?? 'Not found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
          // Policy verifier
          Text(
            _isSwahili ? 'Thibitisha Bima' : 'Verify Insurance',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _policyCtrl,
                  decoration: InputDecoration(
                    hintText: _isSwahili
                        ? 'Namba ya bima...'
                        : 'Policy number...',
                    hintStyle:
                        const TextStyle(color: _kSecondary, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isVerifying ? null : _verify,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search_rounded, size: 20),
              ),
            ],
          ),

          if (_policy != null) ...[
            const SizedBox(height: 12),
            PolicyCard(policy: _policy!, isSwahili: _isSwahili),
          ],
          const SizedBox(height: 24),

          // Services
          Text(
            _isSwahili ? 'Huduma' : 'Services',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionTile(
                icon: Icons.business_rounded,
                label: _isSwahili ? 'Bima Kampuni' : 'Insurers',
                onTap: () => _nav(const InsurerDirectoryPage()),
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.report_rounded,
                label: _isSwahili ? 'Lalamiko' : 'Complaint',
                onTap: () => _nav(const TiraComplaintPage()),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            Icon(icon, color: _kPrimary, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }
}
