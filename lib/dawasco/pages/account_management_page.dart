// lib/dawasco/pages/account_management_page.dart
import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/dawasco_models.dart';
import '../services/dawasco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class AccountManagementPage extends StatefulWidget {
  final WaterAccount? account;
  const AccountManagementPage({super.key, this.account});
  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _meterCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.account?.ownerName ?? '');
    _phoneCtrl = TextEditingController(text: widget.account?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.account?.address ?? '');
    _meterCtrl = TextEditingController(text: widget.account?.meterNumber ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _meterCtrl.dispose();
    super.dispose();
  }

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? false;

  Future<void> _save() async {
    final sw = _sw;
    final accountNumber = widget.account?.accountNumber;
    if (accountNumber == null || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sw ? 'Hakuna namba ya akaunti' : 'No account number'),
      ));
      return;
    }
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await DawascoService.updateAccount(accountNumber, {
        'owner_name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'meter_number': _meterCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(
        result.success
            ? (sw ? 'Taarifa zimehifadhiwa' : 'Details saved successfully')
            : (result.message ?? (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save')),
      )));
      if (result.success) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(
        sw ? 'Hitilafu: $e' : 'Error: $e',
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text(sw ? 'Simamia Akaunti' : 'Account Management',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (widget.account != null)
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.account_circle_rounded, size: 24, color: _kPrimary),
              const SizedBox(width: 10),
              Text('A/C: ${widget.account!.accountNumber}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary,
                      letterSpacing: 1),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        _buildField(
          label: sw ? 'Jina la Mmiliki' : 'Owner Name',
          controller: _nameCtrl,
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 14),
        _buildField(
          label: sw ? 'Namba ya Simu' : 'Phone Number',
          controller: _phoneCtrl,
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        _buildField(
          label: sw ? 'Anwani' : 'Address',
          controller: _addressCtrl,
          icon: Icons.location_on_rounded,
          maxLines: 2,
        ),
        const SizedBox(height: 14),
        _buildField(
          label: sw ? 'Namba ya Mita' : 'Meter Number',
          controller: _meterCtrl,
          icon: Icons.speed_rounded,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _saving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(sw ? 'Hifadhi Mabadiliko' : 'Save Changes',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 20, color: _kSecondary),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kPrimary.withValues(alpha: 0.12)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: const TextStyle(fontSize: 14, color: _kPrimary),
      ),
    ]);
  }
}
