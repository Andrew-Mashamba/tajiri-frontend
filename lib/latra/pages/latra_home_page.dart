// lib/latra/pages/latra_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/latra_models.dart';
import '../services/latra_service.dart';
import '../widgets/fare_result_widget.dart';
import 'complaint_form_page.dart';
import 'operator_directory_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class LatraHomePage extends StatefulWidget {
  final int userId;
  const LatraHomePage({super.key, required this.userId});
  @override
  State<LatraHomePage> createState() => _LatraHomePageState();
}

class _LatraHomePageState extends State<LatraHomePage> {
  bool _isSwahili = true;
  bool _isChecking = false;
  FareResult? _fareResult;
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  String _vehicleType = 'daladala';

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _checkFare() async {
    if (_originCtrl.text.trim().isEmpty || _destCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _isChecking = true;
      _fareResult = null;
    });
    final result = await LatraService.checkFare(
      origin: _originCtrl.text.trim(),
      destination: _destCtrl.text.trim(),
      vehicleType: _vehicleType,
    );
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (result.success) _fareResult = result.data;
    });
    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')));
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
          // Fare checker
          Text(
            _isSwahili ? 'Angalia Bei ya Usafiri' : 'Check Fare',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _originCtrl,
            decoration: _dec(_isSwahili ? 'Mahali pa kuanzia' : 'Origin'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _destCtrl,
            decoration: _dec(_isSwahili ? 'Unapoenda' : 'Destination'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _vehicleType,
            decoration: _dec(''),
            items: ['daladala', 'bajaji', 'bodaboda', 'bus']
                .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t[0].toUpperCase() + t.substring(1))))
                .toList(),
            onChanged: (v) =>
                setState(() => _vehicleType = v ?? 'daladala'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _isChecking ? null : _checkFare,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isChecking
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_isSwahili ? 'Angalia Bei' : 'Check Fare'),
          ),
          if (_fareResult != null) ...[
            const SizedBox(height: 12),
            FareResultWidget(fare: _fareResult!, isSwahili: _isSwahili),
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
                icon: Icons.report_rounded,
                label: _isSwahili ? 'Lalamiko' : 'Complaint',
                onTap: () => _nav(const ComplaintFormPage()),
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.badge_rounded,
                label: _isSwahili ? 'Waendeshaji' : 'Operators',
                onTap: () => _nav(const OperatorDirectoryPage()),
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
