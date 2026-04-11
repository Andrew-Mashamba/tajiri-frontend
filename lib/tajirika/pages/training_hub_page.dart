import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/tajirika_models.dart';
import '../services/tajirika_service.dart';
import '../widgets/training_course_card.dart';
import 'partner_profile_page.dart';

class TrainingHubPage extends StatefulWidget {
  const TrainingHubPage({super.key});

  @override
  State<TrainingHubPage> createState() => _TrainingHubPageState();
}

class _TrainingHubPageState extends State<TrainingHubPage>
    with SingleTickerProviderStateMixin {
  static const Color _kBg = Color(0xFFFAFAFA);
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  late TabController _tabController;

  List<TrainingCourse> _courses = [];
  List<MentorshipMatch> _mentorships = [];
  bool _isLoading = true;
  String? _error;
  SkillCategory? _selectedCategory;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    _userId ??= storage.getUser()?.userId;
    return storage.getAuthToken();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _getToken();
      if (token == null || _userId == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Not authenticated';
        });
        return;
      }

      final results = await Future.wait([
        TajirikaService.getTrainingCourses(
          token,
          _userId!,
          category: _selectedCategory?.name,
        ),
        TajirikaService.getMentorshipMatches(token, _userId!),
      ]);

      if (!mounted) return;

      final courseResult = results[0] as TrainingListResult;
      final mentorResult = results[1] as List<MentorshipMatch>;

      if (courseResult.success) {
        setState(() {
          _courses = courseResult.courses;
          _mentorships = mentorResult;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = courseResult.message ?? 'Failed to load courses';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: $e';
      });
    }
  }

  List<TrainingCourse> get _availableCourses =>
      _courses.where((c) => c.progress == 0 && !c.isCompleted).toList();

  List<TrainingCourse> get _inProgressCourses =>
      _courses.where((c) => c.progress > 0 && !c.isCompleted).toList();

  List<TrainingCourse> get _completedCourses =>
      _courses.where((c) => c.isCompleted).toList();

  void _onCategoryChanged(SkillCategory? category) {
    setState(() => _selectedCategory = category);
    _loadData();
  }

  void _showCourseDetail(TrainingCourse course) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _CourseDetailSheet(
        course: course,
        isSwahili: isSwahili,
        onMarkComplete: () async {
          Navigator.pop(ctx);
          await _markCourseComplete(course, messenger);
        },
        onUpdateProgress: (progress) async {
          await _updateProgress(course, progress, messenger);
        },
      ),
    );
  }

  Future<void> _markCourseComplete(
    TrainingCourse course,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final token = await _getToken();
      if (token == null || _userId == null) return;

      final result = await TajirikaService.updateCourseProgress(
        token,
        _userId!,
        course.id,
        1.0,
      );
      if (!mounted) return;

      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppStringsScope.of(context)?.isSwahili == true
                  ? 'Kozi imekamilika!'
                  : 'Course completed!',
            ),
          ),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _updateProgress(
    TrainingCourse course,
    double progress,
    ScaffoldMessengerState messenger,
  ) async {
    try {
      final token = await _getToken();
      if (token == null || _userId == null) return;

      final result = await TajirikaService.updateCourseProgress(
        token,
        _userId!,
        course.id,
        progress,
      );
      if (!mounted) return;

      if (result.success) {
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(result.message ?? 'Failed to update')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSwahili = AppStringsScope.of(context)?.isSwahili ?? false;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        surfaceTintColor: _kBg,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
        ),
        title: Text(
          isSwahili ? 'Kituo cha Mafunzo' : 'Training Hub',
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _kPrimary,
          unselectedLabelColor: _kSecondary,
          indicatorColor: _kPrimary,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(text: isSwahili ? 'Zinazopatikana' : 'Available'),
            Tab(text: isSwahili ? 'Zinaendelea' : 'In Progress'),
            Tab(text: isSwahili ? 'Zilizokamilika' : 'Completed'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : _error != null
                ? _buildError(isSwahili)
                : Column(
                    children: [
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCourseList(_availableCourses, isSwahili),
                            _buildCourseList(_inProgressCourses, isSwahili),
                            _buildCourseList(_completedCourses, isSwahili),
                          ],
                        ),
                      ),
                      if (_mentorships.isNotEmpty)
                        _buildMentorshipSection(isSwahili),
                    ],
                  ),
      ),
    );
  }

  Widget _buildError(bool isSwahili) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
            const SizedBox(height: 16),
            Text(
              _error ?? '',
              style: const TextStyle(color: _kSecondary, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadData,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(
                isSwahili ? 'Jaribu tena' : 'Try again',
                style: const TextStyle(color: _kPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(bool isSwahili) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                isSwahili ? 'Zote' : 'All',
                style: TextStyle(
                  color: _selectedCategory == null ? Colors.white : _kPrimary,
                  fontSize: 12,
                ),
              ),
              selected: _selectedCategory == null,
              onSelected: (_) => _onCategoryChanged(null),
              selectedColor: _kPrimary,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: _selectedCategory == null ? _kPrimary : Colors.grey.shade300,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          ...SkillCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(
                  isSwahili ? cat.labelSwahili : cat.label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _kPrimary,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => _onCategoryChanged(isSelected ? null : cat),
                selectedColor: _kPrimary,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isSelected ? _kPrimary : Colors.grey.shade300,
                ),
                avatar: Icon(cat.icon, size: 14, color: isSelected ? Colors.white : _kSecondary),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseList(List<TrainingCourse> courses, bool isSwahili) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: _kPrimary,
      child: courses.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 12),
                _buildCategoryFilter(isSwahili),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school_rounded, size: 48, color: _kSecondary),
                        const SizedBox(height: 12),
                        Text(
                          isSwahili
                              ? 'Hakuna kozi kwa sasa'
                              : 'No courses found',
                          style: const TextStyle(color: _kSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              itemCount: courses.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: _buildCategoryFilter(isSwahili),
                  );
                }
                final course = courses[index - 1];
                return TrainingCourseCard(
                  course: course,
                  isSwahili: isSwahili,
                  onTap: () => _showCourseDetail(course),
                );
              },
            ),
    );
  }

  Widget _buildMentorshipSection(bool isSwahili) {
    final match = _mentorships.first;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: match.mentorPhoto != null
                ? NetworkImage(match.mentorPhoto!)
                : null,
            child: match.mentorPhoto == null
                ? const Icon(Icons.person_rounded, color: _kSecondary, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSwahili ? 'Mshauri Wako' : 'Your Mentor',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  match.mentorName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(match.mentorTier.icon, size: 12, color: match.mentorTier.color),
                    const SizedBox(width: 4),
                    Text(
                      isSwahili
                          ? match.mentorTier.labelSwahili
                          : match.mentorTier.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: match.mentorTier.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: match.status == 'active'
                            ? const Color(0xFF4CAF50).withOpacity(0.1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        match.status == 'active'
                            ? (isSwahili ? 'Hai' : 'Active')
                            : match.status,
                        style: TextStyle(
                          fontSize: 10,
                          color: match.status == 'active'
                              ? const Color(0xFF4CAF50)
                              : _kSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PartnerProfilePage(partnerId: match.mentorId),
                ),
              );
            },
            icon: const Icon(Icons.person_rounded, color: _kPrimary, size: 20),
            tooltip: isSwahili ? 'Tazama wasifu' : 'View profile',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
    );
  }
}

class _CourseDetailSheet extends StatefulWidget {
  final TrainingCourse course;
  final bool isSwahili;
  final VoidCallback onMarkComplete;
  final Future<void> Function(double progress) onUpdateProgress;

  const _CourseDetailSheet({
    required this.course,
    required this.isSwahili,
    required this.onMarkComplete,
    required this.onUpdateProgress,
  });

  @override
  State<_CourseDetailSheet> createState() => _CourseDetailSheetState();
}

class _CourseDetailSheetState extends State<_CourseDetailSheet> {
  static const Color _kPrimary = Color(0xFF1A1A1A);
  static const Color _kSecondary = Color(0xFF666666);

  late double _sliderProgress;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _sliderProgress = widget.course.progress;
  }

  @override
  Widget build(BuildContext context) {
    final course = widget.course;
    final isSwahili = widget.isSwahili;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: course.displayThumbnail.isNotEmpty
                      ? Image.network(
                          course.displayThumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.play_circle_outline_rounded,
                              size: 48,
                              color: _kSecondary,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            size: 48,
                            color: _kSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Title
              Text(
                isSwahili && course.titleSwahili.isNotEmpty
                    ? course.titleSwahili
                    : course.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Duration + required badge
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: _kSecondary),
                  const SizedBox(width: 4),
                  Text(
                    course.durationText,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  if (course.isRequired) ...[
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kPrimary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isSwahili ? 'Lazima' : 'Required',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (course.category != null) ...[
                    const SizedBox(width: 12),
                    Icon(course.category!.icon, size: 14, color: _kSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        isSwahili
                            ? course.category!.labelSwahili
                            : course.category!.label,
                        style: const TextStyle(fontSize: 12, color: _kSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                isSwahili && course.descriptionSwahili.isNotEmpty
                    ? course.descriptionSwahili
                    : course.description,
                style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
              // Progress slider for in-progress
              if (course.progress > 0 && !course.isCompleted) ...[
                const SizedBox(height: 20),
                Text(
                  isSwahili ? 'Maendeleo' : 'Progress',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: _sliderProgress,
                        onChanged: (val) {
                          setState(() => _sliderProgress = val);
                        },
                        activeColor: _kPrimary,
                        inactiveColor: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(_sliderProgress * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
                if (_sliderProgress != course.progress)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              setState(() => _isSaving = true);
                              await widget.onUpdateProgress(_sliderProgress);
                              if (mounted) setState(() => _isSaving = false);
                            },
                      style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                      child: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kPrimary,
                              ),
                            )
                          : Text(
                              isSwahili ? 'Hifadhi' : 'Save',
                              style: const TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
              ],
              // Mark complete button
              if (course.progress >= 0.9 && !course.isCompleted) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onMarkComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSwahili ? 'Maliza Kozi' : 'Mark Complete',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              // Certificate link
              if (course.isCompleted && course.certificateUrl != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isSwahili
                                ? 'Inafungua cheti...'
                                : 'Opening certificate...',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded, size: 18, color: _kPrimary),
                    label: Text(
                      isSwahili ? 'Tazama Cheti' : 'View Certificate',
                      style: const TextStyle(
                        color: _kPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: const BorderSide(color: _kPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              // Completed badge
              if (course.isCompleted) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 6),
                    Text(
                      isSwahili ? 'Imekamilika' : 'Completed',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
