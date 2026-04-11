// lib/nida/pages/nida_home_page.dart
import 'package:flutter/material.dart';
import '../models/nida_models.dart';
import '../services/nida_service.dart';
import 'status_tracker_page.dart';
import 'office_finder_page.dart';
import 'document_checklist_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class NidaHomePage extends StatefulWidget {
  final int userId;
  const NidaHomePage({super.key, required this.userId});
  @override
  State<NidaHomePage> createState() => _NidaHomePageState();
}

class _NidaHomePageState extends State<NidaHomePage> {
  final _queryCtrl = TextEditingController();
  NidaApplication? _lastResult;
  bool _isChecking = false;
  String? _error;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _isChecking = true; _error = null; });
    final result = await NidaService.checkStatus(q);
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (result.success && result.data != null) {
        _lastResult = result.data;
        _error = null;
      } else {
        _error = result.message ?? 'Imeshindwa kuthibitisha';
        _lastResult = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.badge_rounded, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kitambulisho cha Taifa',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('National Identification Authority',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Status check
          const Text('Angalia Hali / Check Status',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  decoration: InputDecoration(
                    hintText: 'Nambari ya risiti au NIDA',
                    hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isChecking
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tafuta', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            _StatusCard(app: _lastResult!),
          ],
          const SizedBox(height: 24),

          // Quick actions
          const Text('Vitendo vya Haraka / Quick Actions',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _ActionTile(
                icon: Icons.timeline_rounded,
                label: 'Fuatilia\nHali',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => StatusTrackerPage(userId: widget.userId))),
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.location_on_rounded,
                label: 'Ofisi za\nNIDA',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const OfficeFinderPage())),
              ),
              const SizedBox(width: 10),
              _ActionTile(
                icon: Icons.checklist_rounded,
                label: 'Nyaraka\nZinazohitajika',
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DocumentChecklistPage())),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info cards
          _InfoCard(
            icon: Icons.report_problem_rounded,
            title: 'Ripoti Kitambulisho Kilichopotea',
            subtitle: 'Report lost or damaged NIDA card',
            onTap: () => _showLostDialog(),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.family_restroom_rounded,
            title: 'Usajili wa Familia',
            subtitle: 'Track family members\' NIDA status',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usajili wa Familia / Family registration - coming soon')),
              );
            },
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.help_outline_rounded,
            title: 'Maswali Yanayoulizwa Mara kwa Mara',
            subtitle: 'FAQ about NIDA registration process',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FAQ - coming soon')),
              );
            },
          ),
          const SizedBox(height: 32),
        ],
    );
  }

  void _showLostDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Ripoti Kitambulisho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Utaelekezwa kuripoti kitambulisho kilichopotea au kuharibiwa.\n\n'
          'You will be guided to report a lost or damaged ID card.',
          style: TextStyle(fontSize: 13, color: _kSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Sawa', style: TextStyle(color: _kPrimary)),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final NidaApplication app;
  const _StatusCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final stages = ['Usajili', 'Biometrics', 'Kuchapisha', 'Ofisini', 'Imekusanywa'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(app.receiptNumber,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: app.stageIndex >= 4 ? const Color(0xFF4CAF50) : _kPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stages[app.stageIndex.clamp(0, 4)],
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (i) {
              final active = i <= app.stageIndex;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: active ? _kPrimary : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          if (app.officeName != null) ...[
            const SizedBox(height: 8),
            Text('Ofisi: ${app.officeName}',
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 22, color: _kPrimary),
                ),
                const SizedBox(height: 8),
                Text(label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                  textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _InfoCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: _kPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
              const Icon(Icons.chevron_right_rounded, size: 20, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
