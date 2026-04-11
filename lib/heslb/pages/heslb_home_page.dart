// lib/heslb/pages/heslb_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/heslb_models.dart';
import '../services/heslb_service.dart';
import '../widgets/loan_progress_widget.dart';
import 'disbursements_page.dart';
import 'repayment_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class HeslbHomePage extends StatefulWidget {
  final int userId;
  const HeslbHomePage({super.key, required this.userId});
  @override
  State<HeslbHomePage> createState() => _HeslbHomePageState();
}

class _HeslbHomePageState extends State<HeslbHomePage> {
  bool _isSwahili = true;
  bool _isSearching = false;
  LoanStatus? _loan;
  final _appCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _appCtrl.dispose();
    super.dispose();
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _search() async {
    if (_appCtrl.text.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _loan = null;
    });
    final r = await HeslbService.getLoanStatus(_appCtrl.text.trim());
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      if (r.success) _loan = r.data;
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
          // Loan lookup
          Text(
            _isSwahili ? 'Angalia Hali ya Mkopo' : 'Check Loan Status',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _appCtrl,
                  decoration: InputDecoration(
                    hintText: _isSwahili
                        ? 'Namba ya maombi...'
                        : 'Application number...',
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
                onPressed: _isSearching ? null : _search,
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  minimumSize: const Size(48, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSearching
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search_rounded, size: 20),
              ),
            ],
          ),

          if (_loan != null) ...[
            const SizedBox(height: 16),
            LoanProgressWidget(loan: _loan!, isSwahili: _isSwahili),
          ],
          const SizedBox(height: 24),

          // Quick actions
          Text(
            _isSwahili ? 'Huduma' : 'Services',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionTile(
                icon: Icons.account_balance_wallet_rounded,
                label: _isSwahili ? 'Malipo' : 'Disbursements',
                onTap: () => _nav(const DisbursementsPage()),
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.payments_rounded,
                label: _isSwahili ? 'Lipa Mkopo' : 'Repay',
                onTap: () => _nav(const RepaymentPage()),
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
