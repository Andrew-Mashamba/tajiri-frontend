// lib/necta/pages/necta_home_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/necta_models.dart';
import '../services/necta_service.dart';
import '../widgets/result_card.dart';
import 'past_papers_page.dart';
import 'school_stats_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
class NectaHomePage extends StatefulWidget {
  final int userId;
  const NectaHomePage({super.key, required this.userId});
  @override
  State<NectaHomePage> createState() => _NectaHomePageState();
}

class _NectaHomePageState extends State<NectaHomePage> {
  bool _isSwahili = true;
  bool _isSearching = false;
  ExamResult? _result;
  final _candidateCtrl = TextEditingController();
  String _examType = 'csee';
  int _year = DateTime.now().year - 1;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
  }

  @override
  void dispose() {
    _candidateCtrl.dispose();
    super.dispose();
  }

  void _nav(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _search() async {
    if (_candidateCtrl.text.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _result = null;
    });
    final r = await NectaService.checkResults(
      candidateNumber: _candidateCtrl.text.trim(),
      examType: _examType,
      year: _year,
    );
    if (!mounted) return;
    setState(() {
      _isSearching = false;
      if (r.success) _result = r.data;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(r.message ?? 'Not found')));
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          // Results checker
          Text(
            _isSwahili ? 'Angalia Matokeo' : 'Check Results',
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _examType,
                  decoration: _dec(''),
                  items: ['csee', 'acsee', 'ftna', 'psle']
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t.toUpperCase())))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _examType = v ?? 'csee'),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  value: _year,
                  decoration: _dec(''),
                  items: List.generate(10, (i) => DateTime.now().year - i)
                      .map((y) =>
                          DropdownMenuItem(value: y, child: Text('$y')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _year = v ?? DateTime.now().year - 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _candidateCtrl,
                  decoration: _dec(_isSwahili
                      ? 'Namba ya mtahiniwa...'
                      : 'Candidate number...'),
                  textCapitalization: TextCapitalization.characters,
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

          if (_result != null) ...[
            const SizedBox(height: 16),
            ResultCard(result: _result!, isSwahili: _isSwahili),
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
                icon: Icons.description_rounded,
                label: _isSwahili ? 'Mitihani ya Zamani' : 'Past Papers',
                onTap: () => _nav(const PastPapersPage()),
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.bar_chart_rounded,
                label: _isSwahili ? 'Takwimu' : 'School Stats',
                onTap: () => _nav(const SchoolStatsPage()),
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
