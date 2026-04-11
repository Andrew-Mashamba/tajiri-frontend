// lib/my_pregnancy/pages/anc_schedule_page.dart
import 'package:flutter/material.dart';
import '../models/my_pregnancy_models.dart';
import '../services/my_pregnancy_service.dart';
import '../../services/local_storage_service.dart';
import 'danger_signs_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AncSchedulePage extends StatefulWidget {
  final Pregnancy pregnancy;
  final List<AncVisit> visits;

  const AncSchedulePage({
    super.key,
    required this.pregnancy,
    this.visits = const [],
  });

  @override
  State<AncSchedulePage> createState() => _AncSchedulePageState();
}

class _AncSchedulePageState extends State<AncSchedulePage> {
  final MyPregnancyService _service = MyPregnancyService();
  late List<AncVisit> _visits;
  bool _isLoading = false;

  String? get _token =>
      LocalStorageService.instanceSync?.getAuthToken();

  bool get _sw =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  void initState() {
    super.initState();
    _visits = List.from(widget.visits);
    if (_visits.isEmpty) _loadVisits();
  }

  Future<void> _loadVisits() async {
    setState(() => _isLoading = true);
    try {
      final result =
          await _service.getAncSchedule(widget.pregnancy.id, token: _token);
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result.success) _visits = result.items;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sw
                ? 'Imeshindwa kupakia ratiba: $e'
                : 'Failed to load schedule: $e'),
          ),
        );
      }
    }
  }

  Future<void> _showMarkDoneDialog(AncVisit visit) async {
    final sw = _sw;
    final facilityController = TextEditingController();
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            sw
                ? 'Kamilisha Kliniki ya ${visit.visitNumber}'
                : 'Complete Visit ${visit.visitNumber}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: facilityController,
                decoration: InputDecoration(
                  labelText: sw ? 'Jina la Hospitali' : 'Hospital Name',
                  hintText: sw
                      ? 'Mfano: Muhimbili National Hospital'
                      : 'e.g. Muhimbili National Hospital',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: sw ? 'Maelezo (si lazima)' : 'Notes (optional)',
                  hintText: sw
                      ? 'Matokeo ya vipimo, ushauri, n.k.'
                      : 'Test results, advice, etc.',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(sw ? 'Ghairi' : 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              child: Text(sw ? 'Kamilisha' : 'Complete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _markVisitDone(
        visit,
        facility: facilityController.text.trim().isEmpty
            ? null
            : facilityController.text.trim(),
        notes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );
    }
  }

  Future<void> _markVisitDone(AncVisit visit,
      {String? facility, String? notes}) async {
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    try {
      final result = await _service.markAncVisitDone(visit.id,
          facility: facility, notes: notes, token: _token);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(sw
                  ? 'Kliniki ya ${visit.visitNumber} imekamilika'
                  : 'Visit ${visit.visitNumber} completed')),
        );
        _loadVisits();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw
                      ? 'Imeshindwa kukamilisha kliniki'
                      : 'Failed to complete visit'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(sw
                ? 'Kosa: $e'
                : 'Error: $e')),
      );
    }
  }

  /// WHO-recommended ANC schedule descriptions
  Map<int, String> get _ancDescriptions {
    final sw = _sw;
    if (sw) {
      return const {
        1: 'Kliniki ya kwanza (wiki 8-12). Vipimo vya damu, mkojo, shinikizo la damu, na ultrasound ya kwanza.',
        2: 'Kliniki ya pili (wiki 20). Ultrasound ya anatomy scan. Kukagua ukuaji wa mtoto.',
        3: 'Kliniki ya tatu (wiki 26). Kipimo cha sukari ya damu (glucose test). Chanjo ya tetanus.',
        4: 'Kliniki ya nne (wiki 30). Kukagua nafasi ya mtoto. Kupima damu tena.',
        5: 'Kliniki ya tano (wiki 34). Kukagua ukuaji wa mtoto na afya ya mama.',
        6: 'Kliniki ya sita (wiki 36). Kukagua kama mtoto amegeuka kichwa chini. Maandalizi ya kuzaa.',
        7: 'Kliniki ya saba (wiki 38). Kukagua dalili za kuzaa. Kuhakikisha mpango wa hospitali.',
        8: 'Kliniki ya nane (wiki 40). Kliniki ya mwisho. Kukagua kama kujifungua kumechelewa.',
      };
    } else {
      return const {
        1: 'First visit (week 8-12). Blood tests, urine, blood pressure, and first ultrasound.',
        2: 'Second visit (week 20). Anatomy scan ultrasound. Check baby growth.',
        3: 'Third visit (week 26). Glucose tolerance test. Tetanus vaccination.',
        4: 'Fourth visit (week 30). Check baby position. Repeat blood tests.',
        5: 'Fifth visit (week 34). Check baby growth and mother\'s health.',
        6: 'Sixth visit (week 36). Check if baby is head down. Birth preparations.',
        7: 'Seventh visit (week 38). Check for labor signs. Confirm hospital plan.',
        8: 'Eighth visit (week 40). Final visit. Check if delivery is overdue.',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final doneCount = _visits.where((v) => v.isDone).length;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Ratiba ya Kliniki (ANC)' : 'ANC Schedule',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadVisits,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                children: [
                  // Progress
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$doneCount / 8',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          sw ? 'Kliniki Zimekamilika' : 'Visits Completed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: doneCount / 8,
                            minHeight: 6,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 18, color: _kSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sw
                                ? 'WHO inapendekeza kliniki 8 wakati wa ujauzito. Usikose hata moja!'
                                : 'WHO recommends 8 visits during pregnancy. Do not miss any!',
                            style: const TextStyle(
                                fontSize: 12, color: _kSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Visit list
                  if (_visits.isNotEmpty)
                    ..._visits.map((visit) =>
                        _AncVisitCard(
                          visit: visit,
                          description: _ancDescriptions[visit.visitNumber],
                          isSwahili: sw,
                          onMarkDone: visit.isDone
                              ? null
                              : () => _showMarkDoneDialog(visit),
                        ))
                  else
                    // Show default 8 visits
                    ...List.generate(8, (i) {
                      final visitNum = i + 1;
                      return _AncVisitCard(
                        visit: AncVisit(
                          id: 0,
                          visitNumber: visitNum,
                        ),
                        description: _ancDescriptions[visitNum],
                        isSwahili: sw,
                        onMarkDone: null,
                      );
                    }),

                  const SizedBox(height: 16),

                  // Danger signs
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DangerSignsPage()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_rounded,
                              color: Colors.red.shade700, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sw ? 'Dalili za Hatari' : 'Danger Signs',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                                Text(
                                  sw
                                      ? 'Jifunze dalili ambazo zinahitaji kwenda hospitali mara moja'
                                      : 'Learn signs that require going to the hospital immediately',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.red.shade700),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Link to Doctor module
                  GestureDetector(
                    onTap: () {
                      try {
                        Navigator.pushNamed(context, '/doctor');
                      } catch (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_sw
                                ? 'Huduma hii itapatikana hivi karibuni'
                                : 'This service will be available soon'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _kCardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_rounded,
                              size: 22, color: _kPrimary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sw
                                      ? 'Wasiliana na Daktari'
                                      : 'Contact Doctor',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _kPrimary,
                                  ),
                                ),
                                Text(
                                  sw
                                      ? 'Pata ushauri wa daktari wa uzazi kupitia simu au video'
                                      : 'Get advice from an obstetrician via phone or video',
                                  style: const TextStyle(
                                      fontSize: 11, color: _kSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: _kSecondary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _AncVisitCard extends StatelessWidget {
  final AncVisit visit;
  final String? description;
  final VoidCallback? onMarkDone;
  final bool isSwahili;

  const _AncVisitCard({
    required this.visit,
    this.description,
    this.onMarkDone,
    this.isSwahili = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = visit.isDone;
    final isOverdue = visit.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? _kPrimary.withValues(alpha: 0.3)
              : isOverdue
                  ? Colors.red.shade300
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? _kPrimary.withValues(alpha: 0.1)
                      : isOverdue
                          ? Colors.red.shade50
                          : _kPrimary.withValues(alpha: 0.08),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 18, color: _kPrimary)
                      : Text(
                          '${visit.visitNumber}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isOverdue ? Colors.red : _kPrimary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili
                          ? 'Kliniki ya ${visit.visitNumber}'
                          : 'Visit ${visit.visitNumber}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (visit.scheduledDate != null)
                      Text(
                        _formatDate(visit.scheduledDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : _kSecondary,
                        ),
                      ),
                    if (isDone && visit.completedDate != null)
                      Text(
                        '${isSwahili ? "Imekamilika" : "Completed"}: ${_formatDate(visit.completedDate!)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: _kSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              if (isOverdue && !isDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSwahili ? 'Imechelewa' : 'Overdue',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              if (!isDone && onMarkDone != null)
                SizedBox(
                  height: 32,
                  child: TextButton(
                    onPressed: onMarkDone,
                    style: TextButton.styleFrom(
                      foregroundColor: _kPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    child: Text(
                      isSwahili ? 'Kamilisha' : 'Complete',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: const TextStyle(
                  fontSize: 12, color: _kSecondary, height: 1.4),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (visit.facility != null && visit.facility!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_rounded,
                    size: 12, color: _kSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    visit.facility!,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          if (visit.notes != null && visit.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              visit.notes!,
              style: const TextStyle(
                  fontSize: 11,
                  color: _kSecondary,
                  fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
