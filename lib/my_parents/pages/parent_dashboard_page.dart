// lib/my_parents/pages/parent_dashboard_page.dart
import 'package:flutter/material.dart';
import '../../doctor/doctor_module.dart';
import '../../l10n/app_strings_scope.dart';
import '../../pharmacy/pharmacy_module.dart';
import '../../services/local_storage_service.dart';
import '../models/my_parents_models.dart';
import '../services/my_parents_service.dart';
import 'appointments_page.dart';
import 'care_team_page.dart';
import 'financial_support_page.dart';
import 'health_monitor_page.dart';
import 'medication_manager_page.dart';
import 'insurance_page.dart';
import 'parent_emergency_card_page.dart';
import 'wellness_checkin_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBg = Color(0xFFFAFAFA);

class ParentDashboardPage extends StatefulWidget {
  final Parent parent;
  final int userId;

  const ParentDashboardPage({
    super.key,
    required this.parent,
    required this.userId,
  });

  @override
  State<ParentDashboardPage> createState() => _ParentDashboardPageState();
}

class _ParentDashboardPageState extends State<ParentDashboardPage> {
  final MyParentsService _service = MyParentsService();

  String? _token;
  bool _isLoading = true;

  // Dashboard data
  List<ParentMedication> _medications = [];
  List<ParentAppointment> _appointments = [];
  int _activeMedsCount = 0;
  int _adherenceToday = 0;
  int _totalDosesToday = 0;
  double _financialSupportThisMonth = 0;
  double _medicalExpensesThisMonth = 0;

  bool get _isSwahili =>
      AppStringsScope.of(context)?.isSwahili ?? false;

  Parent get _parent => widget.parent;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final medsResult = await _service.getMedications(_token!, _parent.id);
      final apptsResult = await _service.getAppointments(_token!, _parent.id, status: 'upcoming');
      final supportResult = await _service.getSupportHistory(_token!, _parent.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (medsResult.success) {
            _medications = medsResult.items;
            _activeMedsCount = _medications.where((m) => m.isActive).length;
            // Simple adherence estimate: assume all meds with timeSlots
            _totalDosesToday = _medications
                .where((m) => m.isActive)
                .fold(0, (sum, m) => sum + (m.timeSlots.isNotEmpty ? m.timeSlots.length : 1));
            _adherenceToday = 0; // Will be updated from API if available
          }
          if (apptsResult.success) {
            _appointments = apptsResult.items;
          }
          if (supportResult.success) {
            final now = DateTime.now();
            for (final s in supportResult.items) {
              if (s.date.year == now.year && s.date.month == now.month) {
                if (s.type == 'medical') {
                  _medicalExpensesThisMonth += s.amount;
                } else {
                  _financialSupportThisMonth += s.amount;
                }
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isSwahili
              ? 'Imeshindikana kupakia taarifa'
              : 'Failed to load dashboard')),
        );
      }
    }
  }

  String _relationshipLabel(String r, bool sw) {
    switch (r) {
      case 'mother': return sw ? 'Mama' : 'Mother';
      case 'father': return sw ? 'Baba' : 'Father';
      case 'guardian': return sw ? 'Mlezi' : 'Guardian';
      case 'in_law': return sw ? 'Mkwe' : 'In-law';
      default: return r;
    }
  }

  String _livingSituationLabel(String? s, bool sw) {
    switch (s) {
      case 'alone': return sw ? 'Peke yake' : 'Living alone';
      case 'with_spouse': return sw ? 'Na mwenzi' : 'With spouse';
      case 'with_family': return sw ? 'Na familia' : 'With family';
      case 'care_facility': return sw ? 'Nyumba ya wazee' : 'Care facility';
      default: return sw ? 'Haijulikani' : 'Unknown';
    }
  }

  String _mobilityLabel(String? s, bool sw) {
    switch (s) {
      case 'independent': return sw ? 'Anajitegemea' : 'Independent';
      case 'uses_aid': return sw ? 'Anatumia msaada' : 'Uses aid';
      case 'wheelchair': return sw ? 'Kiti cha magurudumu' : 'Wheelchair';
      case 'bedridden': return sw ? 'Kitandani' : 'Bedridden';
      default: return sw ? 'Haijasajiliwa' : 'Not recorded';
    }
  }

  String _cognitiveLabel(String? s, bool sw) {
    switch (s) {
      case 'sharp': return sw ? 'Makini' : 'Sharp';
      case 'mild_forgetfulness': return sw ? 'Usahaulifu mdogo' : 'Mild forgetfulness';
      case 'needs_supervision': return sw ? 'Anahitaji usimamizi' : 'Needs supervision';
      default: return sw ? 'Haijasajiliwa' : 'Not recorded';
    }
  }

  // ─── Build sections ──────────────────────────────────────────

  Widget _buildParentInfoCard(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: _parent.photoUrl != null
                ? ClipOval(
                    child: Image.network(_parent.photoUrl!,
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.elderly_rounded, size: 28, color: _kPrimary)))
                : Icon(
                    _parent.gender == 'female'
                        ? Icons.elderly_woman_rounded
                        : Icons.elderly_rounded,
                    size: 28,
                    color: _kPrimary,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: Text(
                      _parent.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _relationshipLabel(_parent.relationship, sw),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _kPrimary),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  _parent.ageLabel(isSwahili: sw),
                  style: const TextStyle(fontSize: 13, color: _kSecondary),
                ),
                if (_parent.locationName != null && _parent.locationName!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _parent.locationName!,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_parent.livingSituation != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _livingSituationLabel(_parent.livingSituation, sw),
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileCard(bool sw) {
    final missing = <String>[];
    if (_parent.chronicConditions.isEmpty) {
      missing.add(sw ? 'magonjwa ya muda mrefu' : 'chronic conditions');
    }
    if (_parent.allergies.isEmpty) {
      missing.add(sw ? 'mzio' : 'allergies');
    }
    if (_parent.emergencyContacts.isEmpty) {
      missing.add(sw ? 'mawasiliano ya dharura' : 'emergency contacts');
    }
    if (missing.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.amber.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Wasifu haujakamilika' : 'Incomplete profile',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sw ? 'Bado hakuna' : 'Missing'}: ${missing.join(', ')}',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStatusCard(bool sw) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Hali ya Afya' : 'Health Status',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 10),

          // Chronic conditions as chips
          if (_parent.chronicConditions.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _parent.chronicConditions.map((c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(c, style: const TextStyle(fontSize: 12, color: _kPrimary)),
              )).toList(),
            ),
          if (_parent.chronicConditions.isEmpty)
            Text(
              sw ? 'Hakuna magonjwa yaliyosajiliwa' : 'No chronic conditions recorded',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            ),
          const SizedBox(height: 12),

          // Mobility + Cognitive badges
          Row(children: [
            _buildStatusBadge(
              icon: Icons.directions_walk_rounded,
              label: sw ? 'Uwezo wa Kutembea' : 'Mobility',
              value: _mobilityLabel(_parent.mobilityStatus, sw),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(
              icon: Icons.psychology_rounded,
              label: sw ? 'Akili' : 'Cognitive',
              value: _cognitiveLabel(_parent.cognitiveStatus, sw),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 16, color: _kSecondary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
            ]),
            const SizedBox(height: 4),
            Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationStatusCard(bool sw) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.medication_rounded, size: 20, color: _kPrimary),
            const SizedBox(width: 8),
            Text(
              sw ? 'Dawa' : 'Medications',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _buildMedStat(
              sw ? 'Dawa Zinazotumika' : 'Active Meds',
              '$_activeMedsCount',
            ),
            const SizedBox(width: 16),
            _buildMedStat(
              sw ? 'Utiifu Leo' : 'Adherence Today',
              '$_adherenceToday/$_totalDosesToday ${sw ? 'zimemezwa' : 'taken'}',
            ),
          ]),
          if (_medications.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Show next dose info from first active med with timeSlots
            ..._medications.where((m) => m.isActive).take(3).map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${m.name} — ${m.dosage}',
                    style: const TextStyle(fontSize: 13, color: _kPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (m.timeSlots.isNotEmpty)
                  Text(
                    m.timeSlots.first,
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                  ),
              ]),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildMedStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
          const SizedBox(height: 2),
          Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentsCard(bool sw) {
    if (_appointments.isEmpty) return const SizedBox.shrink();

    final next = _appointments.first;
    final daysUntil = next.date.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.event_rounded, size: 20, color: _kPrimary),
            const SizedBox(width: 8),
            Text(
              sw ? 'Miadi Inayokuja' : 'Upcoming Appointment',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (next.doctorName != null)
                    Text(next.doctorName!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (next.facility != null)
                    Text(next.facility!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (next.reason != null)
                    Text(next.reason!,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: daysUntil <= 3
                    ? Colors.red.shade50
                    : _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(children: [
                Text(
                  '$daysUntil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: daysUntil <= 3 ? Colors.red.shade700 : _kPrimary,
                  ),
                ),
                Text(
                  sw ? 'siku' : 'days',
                  style: TextStyle(
                    fontSize: 10,
                    color: daysUntil <= 3 ? Colors.red.shade600 : _kSecondary,
                  ),
                ),
              ]),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildWellnessCheckInCard(bool sw) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Je, ${_parent.name} yuko vipi leo?' : 'How is ${_parent.name} today?',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          // Mood emojis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMoodButton('happy', '😊', sw ? 'Furaha' : 'Happy'),
              _buildMoodButton('okay', '😐', sw ? 'Sawa' : 'Okay'),
              _buildMoodButton('sad', '😢', sw ? 'Huzuni' : 'Sad'),
              _buildMoodButton('unwell', '🤒', sw ? 'Mgonjwa' : 'Unwell'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String mood, String emoji, String label) {
    return GestureDetector(
      onTap: () => _submitQuickCheckIn(mood),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
        ],
      ),
    );
  }

  Future<void> _submitQuickCheckIn(String mood) async {
    if (_token == null) return;
    final sw = _isSwahili;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await _service.saveWellnessCheckIn(
        token: _token!,
        parentId: _parent.id,
        mood: mood,
      );
      if (result.success) {
        messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Hali imerekodishwa' : 'Check-in recorded')));
      } else {
        messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed'))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')));
    }
  }

  Widget _buildQuickActionsGrid(bool sw) {
    final actions = [
      _QuickAction(Icons.medication_rounded, sw ? 'Dawa' : 'Medications', 'medications'),
      _QuickAction(Icons.monitor_heart_rounded, sw ? 'Afya' : 'Health Log', 'health_log'),
      _QuickAction(Icons.event_rounded, sw ? 'Miadi' : 'Appointments', 'appointments'),
      _QuickAction(Icons.payments_rounded, sw ? 'Msaada' : 'Support', 'financial_support'),
      _QuickAction(Icons.badge_rounded, sw ? 'Kadi ya Dharura' : 'Emergency Card', 'emergency_card'),
      _QuickAction(Icons.health_and_safety_rounded, sw ? 'Bima' : 'Insurance', 'insurance'),
      _QuickAction(Icons.people_rounded, sw ? 'Timu ya Huduma' : 'Care Team', 'care_team'),
      _QuickAction(Icons.favorite_rounded, sw ? 'Hali ya Ustawi' : 'Wellness Log', 'wellness'),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Hatua za Haraka' : 'Quick Actions',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
            ),
            itemCount: actions.length,
            itemBuilder: (_, i) {
              final a = actions[i];
              return Material(
                color: _kCardBg,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _handleQuickAction(a.route),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(a.icon, size: 20, color: _kPrimary),
                      ),
                      const SizedBox(height: 6),
                      Text(a.label,
                        style: const TextStyle(fontSize: 12, color: _kPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleQuickAction(String route) {
    switch (route) {
      case 'medications':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MedicationManagerPage(parent: widget.parent),
        ));
        break;
      case 'health_log':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => HealthMonitorPage(parent: widget.parent),
        ));
        break;
      case 'appointments':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AppointmentsPage(parent: widget.parent),
        ));
        break;
      case 'financial_support':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => FinancialSupportPage(parent: widget.parent),
        ));
        break;
      case 'emergency_card':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ParentEmergencyCardPage(parent: widget.parent),
        ));
        break;
      case 'insurance':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => InsurancePage(parent: widget.parent),
        ));
        break;
      case 'care_team':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CareTeamPage(parent: widget.parent, userId: widget.userId),
        ));
        break;
      case 'wellness':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => WellnessCheckInPage(parent: widget.parent),
        ));
        break;
      case 'doctor':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DoctorModule(userId: widget.userId),
        ));
        break;
      case 'pharmacy':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PharmacyModule(userId: widget.userId),
        ));
        break;
      case 'shangazi':
        Navigator.pushNamed(context, '/chat/0');
        break;
      case 'shop':
        Navigator.pushNamed(context, '/shop');
        break;
      default:
        final sw = _isSwahili;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(sw ? 'Inakuja hivi karibuni' : 'Coming soon')),
        );
    }
  }

  Widget _buildHealthIntegrationsCard(bool sw) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Huduma za Afya' : 'Health Integrations',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildIntegrationTile(
              Icons.local_hospital_rounded,
              sw ? 'Pata Daktari' : 'Book Doctor',
              () => _handleQuickAction('doctor'),
            )),
            const SizedBox(width: 10),
            Expanded(child: _buildIntegrationTile(
              Icons.local_pharmacy_rounded,
              sw ? 'Agiza Dawa' : 'Order Medicine',
              () => _handleQuickAction('pharmacy'),
            )),
          ]),
          const SizedBox(height: 10),
          _buildIntegrationTile(
            Icons.shopping_bag_rounded,
            sw ? 'Nunua bidhaa za huduma ya wazee' : 'Shop elderly care products',
            () => _handleQuickAction('shop'),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationTile(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                style: const TextStyle(fontSize: 13, color: _kPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 16, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(bool sw) {
    final hasNhif = _parent.nhifNumber != null && _parent.nhifNumber!.isNotEmpty;
    return GestureDetector(
      onTap: () => _handleQuickAction('insurance'),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.health_and_safety_rounded, size: 20, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sw ? 'Bima ya Afya' : 'Health Insurance',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasNhif
                        ? 'NHIF: ${_parent.nhifNumber}'
                        : (sw ? 'Bonyeza kusimamia bima' : 'Tap to manage insurance'),
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildThisMonthCard(bool sw) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sw ? 'Mwezi Huu' : 'This Month',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _buildMonthStat(
              sw ? 'Msaada wa Kifedha' : 'Financial Support',
              'TZS ${_formatAmount(_financialSupportThisMonth)}',
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildMonthStat(
              sw ? 'Gharama za Matibabu' : 'Medical Expenses',
              'TZS ${_formatAmount(_medicalExpensesThisMonth)}',
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildMonthStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _kSecondary)),
        const SizedBox(height: 2),
        Text(value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildShangaziCard(bool sw) {
    return GestureDetector(
      onTap: () => _handleQuickAction('shangazi'),
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kPrimary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.psychology_rounded, size: 22, color: _kPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shangazi AI',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sw
                        ? 'Uliza Shangazi kuhusu kutunza wazazi'
                        : 'Ask Shangazi about caring for elderly parents',
                    style: const TextStyle(fontSize: 12, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _parent.name,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _buildParentInfoCard(sw),
                  _buildIncompleteProfileCard(sw),
                  _buildHealthStatusCard(sw),
                  _buildMedicationStatusCard(sw),
                  _buildUpcomingAppointmentsCard(sw),
                  _buildWellnessCheckInCard(sw),
                  _buildQuickActionsGrid(sw),
                  _buildHealthIntegrationsCard(sw),
                  _buildInsuranceCard(sw),
                  _buildThisMonthCard(sw),
                  _buildShangaziCard(sw),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final String route;
  const _QuickAction(this.icon, this.label, this.route);
}
