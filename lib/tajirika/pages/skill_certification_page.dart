import 'dart:io';
import 'package:flutter/material.dart' hide Badge;
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/badge_chip.dart';
import '../widgets/skill_category_chip.dart';
import '../widgets/tier_badge.dart';
import '../widgets/tier_progress_bar.dart';

class SkillCertificationPage extends StatefulWidget {
  const SkillCertificationPage({super.key});

  @override
  State<SkillCertificationPage> createState() => _SkillCertificationPageState();
}

class _SkillCertificationPageState extends State<SkillCertificationPage> {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  bool _isLoading = true;
  TierProgress? _tierProgress;
  List<Badge> _badges = [];
  TajirikaPartner? _partner;

  // Skill test state
  SkillCategory? _selectedTestCategory;
  File? _selectedVideo;
  bool _isSubmittingTest = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      final results = await Future.wait([
        TajirikaService.getTierProgress(token, userId),
        TajirikaService.getBadges(token, userId),
        TajirikaService.getMyPartnerProfile(token, userId),
      ]);

      if (!mounted) return;
      setState(() {
        _tierProgress = results[0] as TierProgress;
        final badgeResult = results[1] as BadgeListResult;
        _badges = badgeResult.success ? badgeResult.badges : [];
        final partnerResult = results[2] as PartnerResult;
        _partner = partnerResult.success ? partnerResult.partner : null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          isSwahili ? 'Ujuzi na Vyeti' : 'Skills & Certification',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _kPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentTierCard(isSwahili),
                      const SizedBox(height: 16),
                      _buildTierProgressSection(isSwahili),
                      const SizedBox(height: 16),
                      _buildSkillsSection(isSwahili),
                      const SizedBox(height: 16),
                      _buildBadgesSection(isSwahili),
                      const SizedBox(height: 16),
                      _buildSkillTestSection(isSwahili),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentTierCard(bool isSwahili) {
    final tier = _tierProgress?.currentTier ?? PartnerTier.mwanafunzi;
    String description;
    switch (tier) {
      case PartnerTier.mwanafunzi:
        description = isSwahili
            ? 'Umesajiliwa, kitambulisho kimethibitishwa'
            : 'Registered, ID verified';
        break;
      case PartnerTier.mtaalamu:
        description = isSwahili
            ? 'Ujuzi umethibitishwa, leseni imethibitishwa'
            : 'Skills verified, license confirmed';
        break;
      case PartnerTier.bingwa:
        description = isSwahili
            ? 'Mtaalamu wa hali ya juu'
            : 'Top-tier expert';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TierBadge(tier: tier, fontSize: 16),
          const SizedBox(height: 12),
          Text(
            isSwahili ? tier.labelSwahili : tier.label,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressSection(bool isSwahili) {
    if (_tierProgress == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSwahili ? 'Maendeleo ya Kiwango' : 'Tier Progress',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _kPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TierProgressBar(
          progress: _tierProgress!,
          isSwahili: isSwahili,
        ),
      ],
    );
  }

  Widget _buildSkillsSection(bool isSwahili) {
    final skills = _partner?.skills ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isSwahili ? 'Ujuzi Wangu' : 'My Skills',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: TextButton.icon(
                  onPressed: () => _showEditSkillsSheet(isSwahili),
                  icon: const Icon(Icons.edit_rounded, size: 16, color: _kPrimary),
                  label: Text(
                    isSwahili ? 'Hariri' : 'Edit',
                    style: const TextStyle(color: _kPrimary, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (skills.isEmpty)
            Text(
              isSwahili
                  ? 'Bado hujachagua ujuzi wowote'
                  : 'No skills selected yet',
              style: const TextStyle(fontSize: 13, color: _kSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: skills
                  .map((skill) => SkillCategoryChip(
                        category: skill,
                        selected: true,
                        isSwahili: isSwahili,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _showEditSkillsSheet(bool isSwahili) {
    final selected = Set<SkillCategory>.from(_partner?.skills ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isSwahili ? 'Chagua Ujuzi' : 'Select Skills',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSwahili
                            ? 'Chagua ujuzi unaofanya kazi nao'
                            : 'Choose the skills you work with',
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: SkillCategory.values.map((cat) {
                              final isSelected = selected.contains(cat);
                              return SkillCategoryChip(
                                category: cat,
                                selected: isSelected,
                                isSwahili: isSwahili,
                                onTap: () {
                                  setSheetState(() {
                                    if (isSelected) {
                                      selected.remove(cat);
                                    } else {
                                      selected.add(cat);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => _saveSkills(ctx, selected.toList()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isSwahili ? 'Hifadhi' : 'Save',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _saveSkills(
    BuildContext sheetContext,
    List<SkillCategory> skills,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    Navigator.pop(sheetContext);

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      final result = await TajirikaService.updateSkills(
        token,
        userId,
        skills.map((s) => s.name).toList(),
      );

      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(isSwahili ? 'Ujuzi umehifadhiwa' : 'Skills saved'),
          ),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildBadgesSection(bool isSwahili) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Beji Zangu' : 'My Badges',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_badges.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 40,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSwahili
                          ? 'Bado huna beji yoyote'
                          : 'No badges earned yet',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _badges
                  .map((badge) => BadgeChip(
                        badge: badge,
                        isSwahili: isSwahili,
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSkillTestSection(bool isSwahili) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz_rounded, size: 20, color: _kPrimary),
              const SizedBox(width: 8),
              Text(
                isSwahili ? 'Fanya Mtihani wa Ujuzi' : 'Take a Skill Test',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Pakia video ya kazi yako ili kuthibitisha ujuzi wako'
                : 'Upload a video of your work to verify your skills',
            style: const TextStyle(fontSize: 13, color: _kSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<SkillCategory>(
            value: _selectedTestCategory,
            decoration: InputDecoration(
              labelText: isSwahili ? 'Chagua ujuzi' : 'Select skill',
              labelStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _kPrimary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
            items: SkillCategory.values.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(
                  isSwahili ? cat.labelSwahili : cat.label,
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              setState(() => _selectedTestCategory = val);
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _pickVideo,
              icon: Icon(
                _selectedVideo != null
                    ? Icons.check_circle_rounded
                    : Icons.videocam_rounded,
                size: 18,
                color: _kPrimary,
              ),
              label: Text(
                _selectedVideo != null
                    ? (isSwahili ? 'Video imechaguliwa' : 'Video selected')
                    : (isSwahili ? 'Chagua video' : 'Pick video'),
                style: const TextStyle(color: _kPrimary, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedTestCategory != null &&
                      _selectedVideo != null &&
                      !_isSubmittingTest
                  ? _submitSkillTest
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmittingTest
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isSwahili ? 'Wasilisha Mtihani' : 'Submit Test',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(source: ImageSource.gallery);
      if (video != null && mounted) {
        setState(() => _selectedVideo = File(video.path));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _submitSkillTest() async {
    if (_selectedTestCategory == null || _selectedVideo == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    setState(() => _isSubmittingTest = true);
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final userId = storage.getUser()?.userId;
      if (token == null || userId == null) return;

      final result = await TajirikaService.submitSkillTest(
        token,
        userId,
        _selectedTestCategory!.name,
        _selectedVideo!,
      );

      if (!mounted) return;
      setState(() => _isSubmittingTest = false);

      if (result.success) {
        setState(() {
          _selectedTestCategory = null;
          _selectedVideo = null;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              isSwahili
                  ? 'Mtihani umewasilishwa kikamilifu'
                  : 'Skill test submitted successfully',
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Error')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingTest = false);
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
