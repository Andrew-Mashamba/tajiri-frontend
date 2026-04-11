// lib/lawyer/pages/lawyer_home_page.dart
import 'package:flutter/material.dart';
import '../models/lawyer_models.dart';
import '../services/lawyer_service.dart';
import '../widgets/lawyer_card.dart';
import '../widgets/consultation_card.dart';
import 'find_lawyer_page.dart';
import 'lawyer_profile_page.dart';
import 'my_consultations_page.dart';
import 'lawyer_registration_page.dart';
import 'consultation_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class LawyerHomePage extends StatefulWidget {
  final int userId;
  const LawyerHomePage({super.key, required this.userId});
  @override
  State<LawyerHomePage> createState() => _LawyerHomePageState();
}

class _LawyerHomePageState extends State<LawyerHomePage> {
  final LawyerService _service = LawyerService();

  List<Lawyer> _featuredLawyers = [];
  List<LegalConsultation> _upcomingConsultations = [];
  bool _isLoading = true;
  bool _isLawyer = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _service.findLawyers(onlineOnly: true, perPage: 5),
      _service.getMyConsultations(userId: widget.userId, status: 'upcoming'),
      _service.getMyLawyerProfile(widget.userId),
    ]);

    if (mounted) {
      final lawyersResult = results[0] as LawyerListResult<Lawyer>;
      final consultationsResult = results[1] as LawyerListResult<LegalConsultation>;
      final myLawyerResult = results[2] as LawyerResult<Lawyer>;

      setState(() {
        _isLoading = false;
        if (lawyersResult.success) _featuredLawyers = lawyersResult.items;
        if (consultationsResult.success) _upcomingConsultations = consultationsResult.items;
        _isLawyer = myLawyerResult.success && myLawyerResult.data != null;
      });
    }
  }

  void _openLawyer(Lawyer lawyer) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LawyerProfilePage(userId: widget.userId, lawyer: lawyer)),
    ).then((_) { if (mounted) _loadData(); });
  }

  void _joinConsultation(LegalConsultation consultation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConsultationPage(
          userId: widget.userId,
          consultation: consultation,
        ),
      ),
    ).then((_) { if (mounted) _loadData(); });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Legal help banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wakili Wangu',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Pata ushauri wa kisheria kutoka kwa mawakili waliothibitishwa.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Quick actions
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.search_rounded,
                  label: 'Tafuta Wakili',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => FindLawyerPage(userId: widget.userId)),
                  ).then((_) { if (mounted) _loadData(); }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month_rounded,
                  label: 'Mashauriano Yangu',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyConsultationsPage(userId: widget.userId)),
                  ).then((_) { if (mounted) _loadData(); }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: _isLawyer ? Icons.gavel_rounded : Icons.how_to_reg_rounded,
                  label: _isLawyer ? 'Akaunti ya Wakili' : 'Jiandikishe kama Wakili',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LawyerRegistrationPage(userId: widget.userId)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Specialties scroll
          const Text(
            'Taaluma za Kisheria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: LegalSpecialty.values.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FindLawyerPage(
                          userId: widget.userId,
                          initialSpecialty: s,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE0E0E0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(s.icon, size: 16, color: _kSecondary),
                          const SizedBox(width: 6),
                          Text(
                            s.displayName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Upcoming consultations
          if (_upcomingConsultations.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mashauriano Yajayo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MyConsultationsPage(userId: widget.userId)),
                  ),
                  child: const Text('Yote', style: TextStyle(fontSize: 13, color: _kSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._upcomingConsultations.take(3).map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ConsultationCard(
                    consultation: c,
                    onJoin: c.canJoin ? () => _joinConsultation(c) : null,
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Online lawyers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mawakili Wapatikanao', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FindLawyerPage(userId: widget.userId)),
                ),
                child: const Text('Angalia Wote', style: TextStyle(fontSize: 13, color: _kSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_featuredLawyers.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Icon(Icons.gavel_outlined, size: 48, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Hakuna mawakili mtandaoni kwa sasa', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                ],
              ),
            )
          else
            ..._featuredLawyers.map((law) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LawyerCard(lawyer: law, onTap: () => _openLawyer(law)),
                )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
              Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
