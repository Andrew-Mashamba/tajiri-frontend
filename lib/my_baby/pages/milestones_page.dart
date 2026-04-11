// lib/my_baby/pages/milestones_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

// ─── Local Milestone Data ────────────────────────────────────────

enum MilestoneCategory { motor, language, social, cognitive }

class _LocalMilestone {
  final int month;
  final String titleEn;
  final String titleSw;
  final MilestoneCategory category;

  const _LocalMilestone({
    required this.month,
    required this.titleEn,
    required this.titleSw,
    required this.category,
  });

  String title(bool sw) => sw ? titleSw : titleEn;

  IconData get categoryIcon {
    switch (category) {
      case MilestoneCategory.motor:
        return Icons.directions_run_rounded;
      case MilestoneCategory.language:
        return Icons.record_voice_over_rounded;
      case MilestoneCategory.social:
        return Icons.emoji_emotions_rounded;
      case MilestoneCategory.cognitive:
        return Icons.psychology_rounded;
    }
  }

  String categoryLabel(bool sw) {
    switch (category) {
      case MilestoneCategory.motor:
        return sw ? 'Mwili' : 'Motor';
      case MilestoneCategory.language:
        return sw ? 'Lugha' : 'Language';
      case MilestoneCategory.social:
        return sw ? 'Jamii' : 'Social';
      case MilestoneCategory.cognitive:
        return sw ? 'Akili' : 'Cognitive';
    }
  }
}

const List<_LocalMilestone> _allMilestones = [
  // Month 1
  _LocalMilestone(month: 1, titleEn: 'Lifts head briefly', titleSw: 'Anainua kichwa kwa muda mfupi', category: MilestoneCategory.motor),
  _LocalMilestone(month: 1, titleEn: 'Responds to sounds', titleSw: 'Anajibu sauti', category: MilestoneCategory.cognitive),
  _LocalMilestone(month: 1, titleEn: 'Focuses on faces', titleSw: 'Anakazia macho kwenye nyuso', category: MilestoneCategory.social),
  // Month 2
  _LocalMilestone(month: 2, titleEn: 'Smiles socially', titleSw: 'Anatabasamu kwa watu', category: MilestoneCategory.social),
  _LocalMilestone(month: 2, titleEn: 'Coos and gurgles', titleSw: 'Anatoa sauti za kupendeza', category: MilestoneCategory.language),
  _LocalMilestone(month: 2, titleEn: 'Follows objects with eyes', titleSw: 'Anafuatilia vitu kwa macho', category: MilestoneCategory.cognitive),
  // Month 3
  _LocalMilestone(month: 3, titleEn: 'Holds head steady', titleSw: 'Anashikilia kichwa imara', category: MilestoneCategory.motor),
  _LocalMilestone(month: 3, titleEn: 'Laughs', titleSw: 'Anacheka', category: MilestoneCategory.social),
  _LocalMilestone(month: 3, titleEn: 'Recognizes familiar faces', titleSw: 'Anatambua nyuso zinazojulikana', category: MilestoneCategory.cognitive),
  // Month 4
  _LocalMilestone(month: 4, titleEn: 'Rolls from tummy to back', titleSw: 'Anajigeuza kutoka tumbo kwenda mgongo', category: MilestoneCategory.motor),
  _LocalMilestone(month: 4, titleEn: 'Babbles with expression', titleSw: 'Anapiga kelele kwa hisia', category: MilestoneCategory.language),
  _LocalMilestone(month: 4, titleEn: 'Reaches for toys', titleSw: 'Anafika vinyago', category: MilestoneCategory.motor),
  // Month 5
  _LocalMilestone(month: 5, titleEn: 'Rolls both ways', titleSw: 'Anajigeuza pande zote', category: MilestoneCategory.motor),
  _LocalMilestone(month: 5, titleEn: 'Recognizes own name', titleSw: 'Anatambua jina lake', category: MilestoneCategory.cognitive),
  _LocalMilestone(month: 5, titleEn: 'Puts objects in mouth', titleSw: 'Anaweka vitu mdomoni', category: MilestoneCategory.cognitive),
  // Month 6
  _LocalMilestone(month: 6, titleEn: 'Sits with support', titleSw: 'Anakaa kwa msaada', category: MilestoneCategory.motor),
  _LocalMilestone(month: 6, titleEn: 'Responds to own name', titleSw: 'Anajibu jina lake', category: MilestoneCategory.language),
  _LocalMilestone(month: 6, titleEn: 'Stranger anxiety begins', titleSw: 'Anaanza kuogopa wageni', category: MilestoneCategory.social),
  // Month 7
  _LocalMilestone(month: 7, titleEn: 'Sits without support', titleSw: 'Anakaa bila msaada', category: MilestoneCategory.motor),
  _LocalMilestone(month: 7, titleEn: 'Transfers objects between hands', titleSw: 'Anahamisha vitu kati ya mikono', category: MilestoneCategory.motor),
  _LocalMilestone(month: 7, titleEn: 'Babbles consonant sounds', titleSw: 'Anapiga sauti za konsonanti', category: MilestoneCategory.language),
  // Month 8
  _LocalMilestone(month: 8, titleEn: 'Crawls', titleSw: 'Anatambaa', category: MilestoneCategory.motor),
  _LocalMilestone(month: 8, titleEn: 'Says mama/dada', titleSw: 'Anasema mama/dada', category: MilestoneCategory.language),
  _LocalMilestone(month: 8, titleEn: 'Object permanence', titleSw: 'Anaelewa vitu havipotei', category: MilestoneCategory.cognitive),
  // Month 9
  _LocalMilestone(month: 9, titleEn: 'Pulls to stand', titleSw: 'Anajivuta kusimama', category: MilestoneCategory.motor),
  _LocalMilestone(month: 9, titleEn: 'Points at objects', titleSw: 'Anaonyesha vitu kwa kidole', category: MilestoneCategory.social),
  _LocalMilestone(month: 9, titleEn: 'Understands "no"', titleSw: 'Anaelewa "hapana"', category: MilestoneCategory.cognitive),
  // Month 10
  _LocalMilestone(month: 10, titleEn: 'Cruises along furniture', titleSw: 'Anatembea akishikilia fanicha', category: MilestoneCategory.motor),
  _LocalMilestone(month: 10, titleEn: 'Waves bye-bye', titleSw: 'Anapunga mkono kwaheri', category: MilestoneCategory.social),
  _LocalMilestone(month: 10, titleEn: 'Uses pincer grasp', titleSw: 'Anashika kwa vidole viwili', category: MilestoneCategory.motor),
  // Month 11
  _LocalMilestone(month: 11, titleEn: 'Stands alone briefly', titleSw: 'Anasimama peke yake kwa muda', category: MilestoneCategory.motor),
  _LocalMilestone(month: 11, titleEn: 'Says 1-2 words', titleSw: 'Anasema maneno 1-2', category: MilestoneCategory.language),
  _LocalMilestone(month: 11, titleEn: 'Imitates actions', titleSw: 'Anaiga vitendo', category: MilestoneCategory.social),
  // Month 12
  _LocalMilestone(month: 12, titleEn: 'Takes first steps', titleSw: 'Anapiga hatua za kwanza', category: MilestoneCategory.motor),
  _LocalMilestone(month: 12, titleEn: 'Says 2-3 words', titleSw: 'Anasema maneno 2-3', category: MilestoneCategory.language),
  _LocalMilestone(month: 12, titleEn: 'Follows simple instructions', titleSw: 'Anafuata maelekezo rahisi', category: MilestoneCategory.cognitive),
  _LocalMilestone(month: 12, titleEn: 'Pretend play begins', titleSw: 'Anaanza kucheza kwa kujifanya', category: MilestoneCategory.social),
];

// Wonder Weeks leap weeks
const List<int> _leapWeeks = [5, 8, 12, 19, 26, 37, 46, 55, 64, 75];

// Play activities per age range
class _PlayActivity {
  final int minMonth;
  final int maxMonth;
  final String titleEn;
  final String titleSw;

  const _PlayActivity({
    required this.minMonth,
    required this.maxMonth,
    required this.titleEn,
    required this.titleSw,
  });

  String title(bool sw) => sw ? titleSw : titleEn;
}

const List<_PlayActivity> _playActivities = [
  _PlayActivity(minMonth: 0, maxMonth: 2, titleEn: 'Tummy time on a blanket', titleSw: 'Muda wa kulala kifudifudi kwenye blanketi'),
  _PlayActivity(minMonth: 0, maxMonth: 2, titleEn: 'Sing lullabies and talk softly', titleSw: 'Imba nyimbo za watoto na ongea taratibu'),
  _PlayActivity(minMonth: 0, maxMonth: 2, titleEn: 'High-contrast black & white cards', titleSw: 'Kadi za rangi nyeusi na nyeupe'),
  _PlayActivity(minMonth: 3, maxMonth: 5, titleEn: 'Rattle toys and shaking games', titleSw: 'Michezo ya vitu vinavyolia'),
  _PlayActivity(minMonth: 3, maxMonth: 5, titleEn: 'Mirror play — baby loves faces', titleSw: 'Kucheza na kioo — mtoto anapenda nyuso'),
  _PlayActivity(minMonth: 3, maxMonth: 5, titleEn: 'Gentle bouncing on your knee', titleSw: 'Kuchezea mtoto juu ya goti lako'),
  _PlayActivity(minMonth: 6, maxMonth: 8, titleEn: 'Peek-a-boo games', titleSw: 'Michezo ya kujificha na kuonekana'),
  _PlayActivity(minMonth: 6, maxMonth: 8, titleEn: 'Stacking cups and blocks', titleSw: 'Kupanga vikombe na vitalu'),
  _PlayActivity(minMonth: 6, maxMonth: 8, titleEn: 'Textured sensory play', titleSw: 'Kucheza na vitu vya hisia tofauti'),
  _PlayActivity(minMonth: 9, maxMonth: 12, titleEn: 'Ball rolling back and forth', titleSw: 'Kuviringisha mpira mbele na nyuma'),
  _PlayActivity(minMonth: 9, maxMonth: 12, titleEn: 'Simple shape sorters', titleSw: 'Vichezeo vya kupanga maumbo'),
  _PlayActivity(minMonth: 9, maxMonth: 12, titleEn: 'Read picture books together', titleSw: 'Soma vitabu vya picha pamoja'),
];

// ─── Page ─────────────────────────────────────────────────────────

class MilestonesPage extends StatefulWidget {
  final Baby baby;

  const MilestonesPage({super.key, required this.baby});

  @override
  State<MilestonesPage> createState() => _MilestonesPageState();
}

class _MilestonesPageState extends State<MilestonesPage> {
  final MyBabyService _service = MyBabyService();

  bool _isLoading = true;
  List<BabyMilestone> _serverMilestones = [];
  String? _token;
  String? _errorMessage;
  // Maps milestone titleEn -> photo URL
  final Map<String, String> _milestonePhotos = {};

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadMilestones();
  }

  Future<void> _loadMilestones() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.getMilestones(_token!, widget.baby.id);
      if (!mounted) return;

      if (result.success) {
        setState(() {
          _serverMilestones = result.items;
          _isLoading = false;
        });
        _loadMilestonePhotos();
      } else {
        setState(() {
          _errorMessage = result.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _isMilestoneDone(String titleEn) {
    return _serverMilestones.any(
      (m) => m.title == titleEn && m.isDone,
    );
  }

  BabyMilestone? _findServerMilestone(String titleEn) {
    try {
      return _serverMilestones.firstWhere((m) => m.title == titleEn);
    } catch (_) {
      return null;
    }
  }

  DateTime? _completedDate(String titleEn) {
    final m = _findServerMilestone(titleEn);
    return m?.completedDate;
  }

  bool _isDelayed(_LocalMilestone milestone) {
    final babyMonths = widget.baby.ageInMonths;
    return babyMonths >= milestone.month + 2 && !_isMilestoneDone(milestone.titleEn);
  }

  bool get _isInLeap {
    final weeks = widget.baby.ageInWeeks;
    // Consider within leap if within +/- 1 week of a leap week
    return _leapWeeks.any((lw) => (weeks - lw).abs() <= 1);
  }

  List<_PlayActivity> get _currentActivities {
    final months = widget.baby.ageInMonths;
    return _playActivities
        .where((a) => months >= a.minMonth && months <= a.maxMonth)
        .toList();
  }

  Future<void> _toggleMilestone(_LocalMilestone local) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final server = _findServerMilestone(local.titleEn);

    try {
      if (server != null && server.isDone) {
        final result = await _service.undoMilestone(_token!, server.id);
        if (!mounted) return;
        if (result.success) {
          messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Hatua imeondolewa' : 'Milestone undone'),
          ));
          _loadMilestones();
        } else {
          messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed')),
          ));
        }
      } else if (server != null) {
        final result = await _service.markMilestoneDone(_token!, server.id);
        if (!mounted) return;
        if (result.success) {
          messenger.showSnackBar(SnackBar(
            content: Text(sw ? 'Hongera! Hatua imekamilika!' : 'Milestone completed!'),
          ));
          _loadMilestones();
        } else {
          messenger.showSnackBar(SnackBar(
            content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed')),
          ));
        }
      } else {
        // No server milestone yet — inform user
        messenger.showSnackBar(SnackBar(
          content: Text(sw
              ? 'Hatua hii bado haijasajiliwa kwenye seva'
              : 'This milestone is not yet registered on server'),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred'),
      ));
    }
  }

  Future<void> _loadMilestonePhotos() async {
    if (_token == null) return;
    try {
      final result = await _service.getPhotos(
          _token!, widget.baby.id, type: 'milestone');
      if (!mounted) return;
      if (result.success) {
        final map = <String, String>{};
        for (final photo in result.items) {
          if (photo.caption != null && photo.caption!.isNotEmpty) {
            map[photo.caption!] = photo.displayUrl;
          }
        }
        if (map.isNotEmpty) {
          setState(() => _milestonePhotos.addAll(map));
        }
      }
    } catch (_) {}
  }

  Future<void> _pickMilestonePhoto(_LocalMilestone milestone) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      final result = await _service.uploadPhoto(
        token: _token!,
        babyId: widget.baby.id,
        filePath: picked.path,
        type: 'milestone',
        milestoneKey: milestone.titleEn,
        caption: milestone.titleEn,
      );
      if (!mounted) return;
      if (result.success && result.data != null) {
        setState(() {
          _milestonePhotos[milestone.titleEn] = result.data!.displayUrl;
        });
        messenger.showSnackBar(SnackBar(
          content: Text(sw ? 'Picha imehifadhiwa' : 'Photo saved'),
        ));
      } else {
        messenger.showSnackBar(SnackBar(
          content: Text(result.message ?? (sw ? 'Imeshindwa' : 'Failed')),
        ));
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final babyMonths = widget.baby.ageInMonths;

    // Group milestones by month
    final months = <int>{};
    for (final m in _allMilestones) {
      months.add(m.month);
    }
    final sortedMonths = months.toList()..sort();

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
          sw ? 'Hatua za Ukuaji' : 'Milestones',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kPrimary))
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _loadMilestones,
                            child: Text(sw ? 'Jaribu tena' : 'Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMilestones,
                    color: _kPrimary,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      children: [
                        // Baby age header
                        _buildAgeHeader(sw),
                        const SizedBox(height: 16),

                        // Developmental leap alert
                        if (_isInLeap) ...[
                          _buildLeapAlert(sw),
                          const SizedBox(height: 16),
                        ],

                        // Play activities for current age
                        if (_currentActivities.isNotEmpty) ...[
                          _buildPlayActivities(sw),
                          const SizedBox(height: 16),
                        ],

                        // Monthly milestone sections
                        ...sortedMonths.expand((month) {
                          final milestonesForMonth = _allMilestones
                              .where((m) => m.month == month)
                              .toList();
                          final delayed = milestonesForMonth
                              .where((m) => _isDelayed(m))
                              .toList();

                          return [
                            _buildMonthHeader(month, sw, babyMonths),
                            ...milestonesForMonth
                                .map((m) => _buildMilestoneItem(m, sw)),
                            if (delayed.isNotEmpty)
                              _buildDelayAlert(sw),
                            const SizedBox(height: 16),
                          ];
                        }),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildAgeHeader(bool sw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded,
                size: 24, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.baby.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.baby.ageLabelLocalized(isSwahili: sw),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_serverMilestones.where((m) => m.isDone).length} / ${_serverMilestones.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeapAlert(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_rounded,
              size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sw ? 'Mruko wa Kiakili!' : 'Mental Leap!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sw
                      ? 'Mtoto wako anaweza kuwa na wasiwasi - anafanya mruko wa kiakili!'
                      : 'Your baby may be fussy - a mental leap is happening!',
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayActivities(bool sw) {
    final activities = _currentActivities;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sports_esports_rounded,
                  size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                sw ? 'Michezo ya Umri Huu' : 'Play Activities',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...activities.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: const BoxDecoration(
                        color: _kSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        a.title(sw),
                        style:
                            const TextStyle(fontSize: 13, color: _kPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMonthHeader(int month, bool sw, int babyMonths) {
    final isCurrent = babyMonths == month;
    final isPast = babyMonths > month;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isCurrent
                  ? _kPrimary
                  : isPast
                      ? Colors.grey.shade300
                      : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              sw ? 'Mwezi wa $month' : 'Month $month',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isCurrent ? Colors.white : _kPrimary,
              ),
            ),
          ),
          if (isCurrent) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                sw ? 'Sasa' : 'Now',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
            ),
          ],
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMilestoneItem(_LocalMilestone milestone, bool sw) {
    final isDone = _isMilestoneDone(milestone.titleEn);
    final completed = _completedDate(milestone.titleEn);
    final delayed = _isDelayed(milestone);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: delayed && !isDone ? Colors.amber.shade50 : _kCardBg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _toggleMilestone(milestone),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? _kPrimary : Colors.transparent,
                    border: Border.all(
                      color: isDone ? _kPrimary : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                // Category icon
                Icon(milestone.categoryIcon, size: 18, color: _kSecondary),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title(sw),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (completed != null)
                        Text(
                          '${completed.day}/${completed.month}/${completed.year}',
                          style: const TextStyle(
                              fontSize: 10, color: _kSecondary),
                        ),
                    ],
                  ),
                ),
                // Milestone photo thumbnail
                if (_milestonePhotos.containsKey(milestone.titleEn))
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        _milestonePhotos[milestone.titleEn]!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, st) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                // Camera button
                GestureDetector(
                  onTap: () => _pickMilestonePhoto(milestone),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(Icons.camera_alt_rounded,
                        size: 16, color: Colors.grey.shade400),
                  ),
                ),
                // Category label
                Text(
                  milestone.categoryLabel(sw),
                  style: const TextStyle(fontSize: 10, color: _kSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDelayAlert(bool sw) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sw
                  ? 'Fikiria kuzungumza na daktari wako kuhusu hatua ambazo bado hazijakamilika.'
                  : 'Consider discussing with your doctor about uncompleted milestones.',
              style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
