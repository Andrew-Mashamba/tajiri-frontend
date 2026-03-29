import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/ad_service.dart';
import '../../services/local_storage_service.dart';

class CreateAdCampaignScreen extends StatefulWidget {
  const CreateAdCampaignScreen({super.key});

  @override
  State<CreateAdCampaignScreen> createState() => _CreateAdCampaignScreenState();
}

class _CreateAdCampaignScreenState extends State<CreateAdCampaignScreen> {
  final _pageController = PageController();
  int _currentStep = 0;
  bool _submitting = false;
  String? _token;

  // Step 1: Campaign Type
  String _campaignType = 'cpm';

  // Step 2: Creative
  String _format = 'image';
  File? _mediaFile;
  final _headlineController = TextEditingController();
  final _bodyTextController = TextEditingController();
  String _ctaType = 'learn_more';
  final _ctaUrlController = TextEditingController();

  // Step 3: Targeting
  String? _location;
  RangeValues _ageRange = const RangeValues(18, 55);
  String _gender = 'all';

  // Step 4: Placements
  final Map<String, bool> _placements = {
    'feed': true,
    'stories': false,
    'music': false,
    'search': false,
    'marketplace': false,
    'clips': false,
    'video_preroll': false,
    'conversations': false,
    'comments': false,
    'live_stream': false,
    'hashtag': false,
  };

  // Step 5: Budget
  final _titleController = TextEditingController();
  final _dailyBudgetController = TextEditingController();
  final _totalBudgetController = TextEditingController();
  final _bidController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  final _formKey = GlobalKey<FormState>();

  static const _ctaTypes = [
    'learn_more',
    'shop_now',
    'sign_up',
    'download',
    'contact_us',
    'watch_more',
    'listen_now',
    'book_now',
  ];

  static const _locations = [
    'dar_es_salaam',
    'dodoma',
    'arusha',
    'mwanza',
    'mbeya',
    'morogoro',
    'tanga',
    'zanzibar',
    'nchi_nzima',
  ];

  @override
  void initState() {
    super.initState();
    _initToken();
  }

  Future<void> _initToken() async {
    final storage = await LocalStorageService.getInstance();
    _token = storage.getAuthToken();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headlineController.dispose();
    _bodyTextController.dispose();
    _ctaUrlController.dispose();
    _titleController.dispose();
    _dailyBudgetController.dispose();
    _totalBudgetController.dispose();
    _bidController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final picked = _format == 'video'
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null && mounted) {
      setState(() => _mediaFile = File(picked.path));
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : (_endDate ?? now.add(const Duration(days: 7))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (_token == null || _submitting) return;
    setState(() => _submitting = true);

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      // 1. Create campaign
      final selectedPlacements = _placements.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final targeting = <String, dynamic>{};
      if (_location != null) targeting['location'] = _location;
      targeting['age_min'] = _ageRange.start.round();
      targeting['age_max'] = _ageRange.end.round();
      if (_gender != 'all') targeting['gender'] = _gender;

      final campaignData = {
        'title': _titleController.text.trim(),
        'campaign_type': _campaignType,
        'daily_budget': double.tryParse(_dailyBudgetController.text) ?? 0,
        'total_budget': double.tryParse(_totalBudgetController.text) ?? 0,
        'bid_amount': double.tryParse(_bidController.text) ?? 0,
        'start_date': _startDate.toIso8601String().split('T').first,
        if (_endDate != null)
          'end_date': _endDate!.toIso8601String().split('T').first,
        'targeting': targeting,
        'placements': selectedPlacements,
      };

      final campaign = await AdService.createCampaign(_token, campaignData);
      if (campaign == null) {
        messenger.showSnackBar(const SnackBar(content: Text('Failed to create campaign')));
        if (mounted) setState(() => _submitting = false);
        return;
      }

      // 2. Upload creative
      final creativeData = {
        'format': _format,
        'headline': _headlineController.text.trim(),
        'body_text': _bodyTextController.text.trim(),
        'cta_type': _ctaType,
        'cta_url': _ctaUrlController.text.trim(),
      };

      await AdService.uploadCreative(
        _token,
        campaign.id,
        creativeData,
        mediaFile: _mediaFile,
      );

      // 3. Submit for review
      await AdService.submitCampaign(_token, campaign.id);

      messenger.showSnackBar(SnackBar(content: Text('${campaign.title} submitted!')));
      nav.pop(true);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stepTitles = [
      s.ainaNyaKampeni,
      s.tangazoLako,
      s.walengwa,
      s.maeneo,
      s.bajetiNaRatiba,
      s.kagua,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.tengenezaKampeni,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: List.generate(6, (i) {
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= _currentStep
                                ? (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A))
                                : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentStep + 1} / 6 — ${stepTitles[_currentStep]}',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCampaignTypeStep(s, isDark),
                  _buildCreativeStep(s, isDark),
                  _buildTargetingStep(s, isDark),
                  _buildPlacementsStep(s, isDark),
                  _buildBudgetStep(s, isDark),
                  _buildReviewStep(s, isDark),
                ],
              ),
            ),

            // Navigation
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _prevStep,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(s.back, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: _currentStep == 5
                          ? FilledButton(
                              onPressed: _submitting ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                                foregroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(s.wasilisha, maxLines: 1, overflow: TextOverflow.ellipsis),
                            )
                          : FilledButton(
                              onPressed: _nextStep,
                              style: FilledButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                                foregroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(s.next, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 1: Campaign Type
  Widget _buildCampaignTypeStep(AppStrings s, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _typeCard(
          title: s.cpm,
          subtitle: s.cpmDesc,
          selected: _campaignType == 'cpm',
          onTap: () => setState(() => _campaignType = 'cpm'),
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _typeCard(
          title: s.cpc,
          subtitle: s.cpcDesc,
          selected: _campaignType == 'cpc',
          onTap: () => setState(() => _campaignType = 'cpc'),
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _typeCard({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A))
                : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Step 2: Creative
  Widget _buildCreativeStep(AppStrings s, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Format selector
        Text(
          'Format',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _formatChip(s.umboPicha, 'image', isDark),
            const SizedBox(width: 8),
            _formatChip(s.umboVideo, 'video', isDark),
            const SizedBox(width: 8),
            _formatChip(s.umboNative, 'native', isDark),
          ],
        ),
        const SizedBox(height: 20),

        // Media upload
        if (_format != 'native') ...[
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickMedia,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
                ),
              ),
              child: _mediaFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_mediaFile!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_upload_rounded,
                            size: 40,
                            color: isDark ? const Color(0xFF555555) : const Color(0xFF999999),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _format == 'video' ? 'Upload Video' : 'Upload Image',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Headline
        TextFormField(
          controller: _headlineController,
          decoration: InputDecoration(
            labelText: s.kichwaChaTangazo,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLength: 90,
          maxLines: 1,
        ),
        const SizedBox(height: 12),

        // Body text
        TextFormField(
          controller: _bodyTextController,
          decoration: InputDecoration(
            labelText: s.maelezoYaTangazo,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLength: 150,
          maxLines: 3,
        ),
        const SizedBox(height: 12),

        // CTA type dropdown
        DropdownButtonFormField<String>(
          initialValue: _ctaType,
          decoration: InputDecoration(
            labelText: s.ainaCTA,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _ctaTypes.map((t) {
            return DropdownMenuItem(value: t, child: Text(t.replaceAll('_', ' ').toUpperCase()));
          }).toList(),
          onChanged: (v) => setState(() => _ctaType = v ?? 'learn_more'),
        ),
        const SizedBox(height: 12),

        // CTA URL
        TextFormField(
          controller: _ctaUrlController,
          decoration: InputDecoration(
            labelText: s.linkYaCTA,
            hintText: 'https://',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.url,
          maxLines: 1,
        ),
      ],
    );
  }

  Widget _formatChip(String label, String value, bool isDark) {
    final selected = _format == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _format = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A))
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA))
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Step 3: Targeting
  Widget _buildTargetingStep(AppStrings s, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Location
        DropdownButtonFormField<String>(
          initialValue: _location,
          decoration: InputDecoration(
            labelText: s.eneo,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _locations.map((loc) {
            return DropdownMenuItem(
              value: loc,
              child: Text(loc.replaceAll('_', ' ').split(' ').map((w) =>
                  w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w).join(' ')),
            );
          }).toList(),
          onChanged: (v) => setState(() => _location = v),
        ),
        const SizedBox(height: 24),

        // Age range
        Text(
          '${s.umriRange}: ${_ageRange.start.round()} - ${_ageRange.end.round()}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        RangeSlider(
          values: _ageRange,
          min: 13,
          max: 65,
          divisions: 52,
          labels: RangeLabels(
            _ageRange.start.round().toString(),
            _ageRange.end.round().toString(),
          ),
          onChanged: (v) => setState(() => _ageRange = v),
        ),
        const SizedBox(height: 24),

        // Gender
        Text(
          s.jinsia,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _genderChip(s.woteGender, 'all', isDark),
            const SizedBox(width: 8),
            _genderChip(s.meGender, 'male', isDark),
            const SizedBox(width: 8),
            _genderChip(s.keGender, 'female', isDark),
          ],
        ),
      ],
    );
  }

  Widget _genderChip(String label, String value, bool isDark) {
    final selected = _gender == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _gender = value),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A))
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected
                  ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAFAFA))
                  : null,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // Step 4: Placements
  Widget _buildPlacementsStep(AppStrings s, bool isDark) {
    final placementLabels = {
      'feed': 'Feed',
      'stories': 'Stories',
      'music': isSwahili(s) ? 'Muziki' : 'Music',
      'search': isSwahili(s) ? 'Tafuta' : 'Search',
      'marketplace': isSwahili(s) ? 'Duka' : 'Marketplace',
      'clips': 'Clips',
      'video_preroll': 'Video Pre-roll',
      'conversations': isSwahili(s) ? 'Mazungumzo' : 'Conversations',
      'comments': isSwahili(s) ? 'Maoni' : 'Comments',
      'live_stream': 'Live Stream',
      'hashtag': 'Hashtag',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _placements.keys.map((key) {
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: CheckboxListTile(
            title: Text(
              placementLabels[key] ?? key,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            value: _placements[key],
            onChanged: (v) => setState(() => _placements[key] = v ?? false),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        );
      }).toList(),
    );
  }

  bool isSwahili(AppStrings s) {
    try {
      return s.isSwahili;
    } catch (_) {
      return false;
    }
  }

  // Step 5: Budget
  Widget _buildBudgetStep(AppStrings s, bool isDark) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: s.jina,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Daily budget
          TextFormField(
            controller: _dailyBudgetController,
            decoration: InputDecoration(
              labelText: s.bajetiKwaiku,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              final val = double.tryParse(v ?? '') ?? 0;
              return val < 1000 ? 'Min 1,000 TZS' : null;
            },
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Total budget
          TextFormField(
            controller: _totalBudgetController,
            decoration: InputDecoration(
              labelText: s.bajetiJumla,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              final val = double.tryParse(v ?? '') ?? 0;
              return val < 5000 ? 'Min 5,000 TZS' : null;
            },
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Bid amount
          TextFormField(
            controller: _bidController,
            decoration: InputDecoration(
              labelText: s.kiasi,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            validator: (v) {
              final val = double.tryParse(v ?? '') ?? 0;
              return val < 1 ? 'Min 1 TZS' : null;
            },
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Start date
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.tarikhiKuanza, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${_startDate.day}/${_startDate.month}/${_startDate.year}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () => _selectDate(true),
          ),

          // End date
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(s.tarikhiKumalizika, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              _endDate != null
                  ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                  : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () => _selectDate(false),
          ),
        ],
      ),
    );
  }

  // Step 6: Review
  Widget _buildReviewStep(AppStrings s, bool isDark) {
    final selectedPlacements = _placements.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .join(', ');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _reviewRow(s.ainaNyaKampeni, _campaignType.toUpperCase(), isDark),
        _reviewRow(s.jina, _titleController.text, isDark),
        _reviewRow(s.kichwaChaTangazo, _headlineController.text, isDark),
        _reviewRow(s.ainaCTA, _ctaType.replaceAll('_', ' '), isDark),
        _reviewRow(s.linkYaCTA, _ctaUrlController.text, isDark),
        _reviewRow(s.eneo, _location?.replaceAll('_', ' ') ?? '—', isDark),
        _reviewRow(s.umriRange, '${_ageRange.start.round()} - ${_ageRange.end.round()}', isDark),
        _reviewRow(s.jinsia, _gender, isDark),
        _reviewRow(s.maeneo, selectedPlacements, isDark),
        _reviewRow(s.bajetiKwaiku, 'TZS ${_dailyBudgetController.text}', isDark),
        _reviewRow(s.bajetiJumla, 'TZS ${_totalBudgetController.text}', isDark),
        _reviewRow(s.kiasi, 'TZS ${_bidController.text}', isDark),
        _reviewRow(s.tarikhiKuanza, '${_startDate.day}/${_startDate.month}/${_startDate.year}', isDark),
        if (_endDate != null)
          _reviewRow(s.tarikhiKumalizika, '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}', isDark),

        if (_mediaFile != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_mediaFile!, height: 120, fit: BoxFit.cover),
          ),
        ],
      ],
    );
  }

  Widget _reviewRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF999999) : const Color(0xFF666666),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
