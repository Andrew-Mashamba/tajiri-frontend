// lib/my_faith/pages/faith_setup_page.dart
import 'package:flutter/material.dart';
import '../models/my_faith_models.dart';
import '../services/my_faith_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FaithSetupPage extends StatefulWidget {
  final int userId;
  final FaithProfile? existing;
  const FaithSetupPage({super.key, required this.userId, this.existing});
  @override
  State<FaithSetupPage> createState() => _FaithSetupPageState();
}

class _FaithSetupPageState extends State<FaithSetupPage> {
  int _step = 0;
  FaithSelection? _faith;
  String? _denomination;
  final _bioCtrl = TextEditingController();
  final _baptismCtrl = TextEditingController();
  bool _isLeader = false;
  final _leaderRoleCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _faith = e.faith;
      _denomination = e.denomination;
      _bioCtrl.text = e.faithBio ?? '';
      _baptismCtrl.text = e.baptismDate ?? '';
      _isLeader = e.isLeader;
      _leaderRoleCtrl.text = e.leaderRole ?? '';
    }
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _baptismCtrl.dispose();
    _leaderRoleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weka Imani', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Faith Setup', style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: _saving
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _buildStep(),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildFaithStep();
      case 1:
        return _buildDenominationStep();
      case 2:
        return _buildBioStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFaithStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Chagua imani yako',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Select your faith',
              style: TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 24),
          _OptionTile(
            icon: Icons.church_rounded,
            label: 'Ukristo / Christianity',
            selected: _faith == FaithSelection.christianity,
            onTap: () => setState(() => _faith = FaithSelection.christianity),
          ),
          const SizedBox(height: 12),
          _OptionTile(
            icon: Icons.mosque_rounded,
            label: 'Uislamu / Islam',
            selected: _faith == FaithSelection.islam,
            onTap: () => setState(() => _faith = FaithSelection.islam),
          ),
          const Spacer(),
          _buildNextButton(enabled: _faith != null, onTap: () => setState(() => _step = 1)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDenominationStep() {
    final options = _faith == FaithSelection.islam
        ? IslamicTradition.values.map((t) => t.label).toList()
        : ChristianDenomination.values.map((d) => d.label).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Dhehebu lako',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Your denomination',
              style: TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OptionTile(
                icon: Icons.group_rounded,
                label: options[i],
                selected: _denomination == options[i],
                onTap: () => setState(() => _denomination = options[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildNextButton(
            enabled: _denomination != null,
            onTap: () => setState(() => _step = 2),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Rudi / Back', style: TextStyle(color: _kSecondary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Maelezo ya Imani',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 4),
          const Text('Faith details', style: TextStyle(fontSize: 13, color: _kSecondary)),
          const SizedBox(height: 20),
          const Text('Hadithi ya imani yako / Faith bio',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'Andika kidogo kuhusu safari yako ya kiroho...',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tarehe ya ubatizo / Baptism date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _kPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _baptismCtrl,
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _kPrimary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isLeader,
                onChanged: (v) => setState(() => _isLeader = v ?? false),
                activeColor: _kPrimary,
              ),
              const Expanded(
                child: Text('Mimi ni kiongozi wa dini / I am a faith leader',
                    style: TextStyle(fontSize: 14, color: _kPrimary)),
              ),
            ],
          ),
          if (_isLeader) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _leaderRoleCtrl,
              decoration: InputDecoration(
                hintText: 'Mch. / Pastor / Imam / Shemasi...',
                hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kPrimary),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          _buildNextButton(enabled: true, label: 'Hifadhi / Save', onTap: _save),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _step = 1),
              child: const Text('Rudi / Back', style: TextStyle(color: _kSecondary, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton({required bool enabled, VoidCallback? onTap, String? label}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label ?? 'Endelea / Next',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final body = {
      'user_id': widget.userId,
      'faith': _faith == FaithSelection.islam ? 'islam' : 'christianity',
      'denomination': _denomination,
      'faith_bio': _bioCtrl.text.trim(),
      'baptism_date': _baptismCtrl.text.trim().isEmpty ? null : _baptismCtrl.text.trim(),
      'is_leader': _isLeader,
      'leader_role': _isLeader ? _leaderRoleCtrl.text.trim() : null,
    };
    final r = await MyFaithService.saveProfile(body);
    if (mounted) {
      setState(() => _saving = false);
      if (r.success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(r.message ?? 'Imeshindwa kuhifadhi / Failed to save')),
        );
      }
    }
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? _kPrimary : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: selected ? Colors.white : _kPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }
}
