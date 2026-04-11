// lib/my_baby/pages/photo_journal_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class PhotoJournalPage extends StatefulWidget {
  final Baby baby;
  final int userId;

  const PhotoJournalPage({
    super.key,
    required this.baby,
    required this.userId,
  });

  @override
  State<PhotoJournalPage> createState() => _PhotoJournalPageState();
}

class _PhotoJournalPageState extends State<PhotoJournalPage> {
  final MyBabyService _service = MyBabyService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isUploading = false;
  String? _token;
  List<BabyPhoto> _photos = [];

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  // First moments milestone keys with labels
  static const List<_FirstMoment> _firstMoments = [
    _FirstMoment('first_smile', 'First Smile', 'Tabasamu la Kwanza'),
    _FirstMoment('first_bath', 'First Bath', 'Kuoga kwa Kwanza'),
    _FirstMoment('first_food', 'First Food', 'Chakula cha Kwanza'),
    _FirstMoment('first_tooth', 'First Tooth', 'Jino la Kwanza'),
    _FirstMoment('first_steps', 'First Steps', 'Hatua za Kwanza'),
    _FirstMoment('first_word', 'First Word', 'Neno la Kwanza'),
    _FirstMoment('first_birthday', 'First Birthday', 'Siku ya Kuzaliwa ya Kwanza'),
  ];

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await _service.getPhotos(_token!, widget.baby.id);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (result.success) _photos = result.items;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw
              ? 'Imeshindikana kupakia picha'
              : 'Failed to load photos')),
        );
      }
    }
  }

  Future<void> _pickAndUpload({
    required String type,
    int? monthNumber,
    String? milestoneKey,
  }) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: _kPrimary),
                title: Text(sw ? 'Kamera' : 'Camera',
                    style: const TextStyle(color: _kPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: _kPrimary),
                title: Text(sw ? 'Picha zilizohifadhiwa' : 'Gallery',
                    style: const TextStyle(color: _kPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final picked = await _picker.pickImage(
          source: source, maxWidth: 1920, imageQuality: 85);
      if (picked == null || !mounted) return;

      setState(() => _isUploading = true);

      final result = await _service.uploadPhoto(
        token: _token!,
        babyId: widget.baby.id,
        filePath: picked.path,
        type: type,
        monthNumber: monthNumber,
        milestoneKey: milestoneKey,
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(
                  sw ? 'Picha imehifadhiwa!' : 'Photo saved!')),
        );
        _loadPhotos();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa kuhifadhi' : 'Failed to save'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        messenger.showSnackBar(
          SnackBar(
              content:
                  Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  void _sharePhoto(BabyPhoto photo) {
    final sw = _sw;
    final ageLabel = widget.baby.ageLabelLocalized(isSwahili: sw);
    final caption = photo.caption ?? (sw ? 'Kumbukumbu ya mtoto' : 'Baby memory');

    // Build a designed text card with baby info
    final buffer = StringBuffer();
    buffer.writeln(sw
        ? '\uD83C\uDF89 ${widget.baby.name} ana $ageLabel!'
        : '\uD83C\uDF89 ${widget.baby.name} is $ageLabel old!');
    if (widget.baby.birthWeightGrams != null) {
      final bwKg = (widget.baby.birthWeightGrams! / 1000).toStringAsFixed(2);
      buffer.writeln(sw
          ? '\uD83D\uDCCF Uzito wa kuzaliwa: ${bwKg}kg'
          : '\uD83D\uDCCF Birth weight: ${bwKg}kg');
    }
    buffer.writeln('\uD83D\uDCF7 $caption');
    buffer.writeln('');
    buffer.writeln(sw ? '-- Kutoka TAJIRI' : '-- Sent from TAJIRI');

    SharePlus.instance.share(ShareParams(
      text: buffer.toString(),
      uri: Uri.tryParse(photo.displayUrl),
    ));
  }

  bool _hasMonthlyPhoto(int month) {
    return _photos.any(
        (p) => p.type == 'monthly' && p.monthNumber == month);
  }

  BabyPhoto? _getMilestonePhoto(String key) {
    final matches = _photos
        .where((p) => p.type == 'milestone' && p.caption == key)
        .toList();
    return matches.isNotEmpty ? matches.first : null;
  }

  Map<int, List<BabyPhoto>> get _photosByMonth {
    final map = <int, List<BabyPhoto>>{};
    for (final photo in _photos) {
      final key = photo.createdAt.year * 12 + photo.createdAt.month;
      map.putIfAbsent(key, () => []).add(photo);
    }
    // Sort by key descending (newest first)
    final sorted = Map.fromEntries(
        map.entries.toList()..sort((a, b) => b.key.compareTo(a.key)));
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;
    final currentMonth = widget.baby.ageInMonths;

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
          sw ? 'Picha' : 'Photos',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : Stack(
              children: [
                RefreshIndicator(
                  onRefresh: _loadPhotos,
                  color: _kPrimary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Monthly prompt
                      if (!_hasMonthlyPhoto(currentMonth))
                        _buildMonthlyPrompt(sw, currentMonth),
                      const SizedBox(height: 20),

                      // First moments grid
                      _buildFirstMomentsSection(sw),
                      const SizedBox(height: 20),

                      // Photo timeline
                      _buildPhotoTimeline(sw),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (_isUploading)
                  Container(
                    color: Colors.black26,
                    child: const Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildMonthlyPrompt(bool sw, int monthAge) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.camera_alt_rounded,
              size: 36, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 12),
          Text(
            sw
                ? '${widget.baby.name} ana miezi $monthAge!'
                : '${widget.baby.name} is $monthAge months!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sw ? 'Piga picha ya kumbukumbu!' : 'Take a photo to remember!',
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _pickAndUpload(
                type: 'monthly',
                monthNumber: monthAge,
              ),
              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
              label: Text(
                sw ? 'Piga picha' : 'Take photo',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFirstMomentsSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Wakati wa Kwanza' : 'First Moments',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.85,
          ),
          itemCount: _firstMoments.length,
          itemBuilder: (_, i) {
            final moment = _firstMoments[i];
            final photo = _getMilestonePhoto(moment.key);
            return _FirstMomentCard(
              label: sw ? moment.swLabel : moment.enLabel,
              photo: photo,
              onTap: photo == null
                  ? () => _pickAndUpload(
                        type: 'milestone',
                        milestoneKey: moment.key,
                      )
                  : () => _sharePhoto(photo),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPhotoTimeline(bool sw) {
    final grouped = _photosByMonth;
    if (grouped.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.photo_library_outlined,
                size: 32, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              sw
                  ? 'Bado hakuna picha zilizohifadhiwa'
                  : 'No photos saved yet',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Ratiba ya Picha' : 'Photo Timeline',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        ...grouped.entries.map((entry) {
          final year = entry.key ~/ 12;
          final month = entry.key % 12;
          final monthLabel =
              DateFormat.yMMMM().format(DateTime(year, month));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 6),
                child: Text(
                  monthLabel,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kSecondary),
                ),
              ),
              ...entry.value.map((photo) => _PhotoTimelineItem(
                    photo: photo,
                    isSwahili: sw,
                    onLongPress: () => _sharePhoto(photo),
                  )),
            ],
          );
        }),
      ],
    );
  }
}

// ─── First Moment Data ───────────────────────────────────────────

class _FirstMoment {
  final String key;
  final String enLabel;
  final String swLabel;
  const _FirstMoment(this.key, this.enLabel, this.swLabel);
}

// ─── First Moment Card ───────────────────────────────────────────

class _FirstMomentCard extends StatelessWidget {
  final String label;
  final BabyPhoto? photo;
  final VoidCallback onTap;

  const _FirstMomentCard({
    required this.label,
    this.photo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: photo != null
                  ? Image.network(
                      photo!.displayUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade100,
                        child: Icon(Icons.broken_image_rounded,
                            color: Colors.grey.shade300),
                      ),
                    )
                  : Container(
                      color: _kPrimary.withValues(alpha: 0.04),
                      child: Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 28,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 6),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo Timeline Item ─────────────────────────────────────────

class _PhotoTimelineItem extends StatelessWidget {
  final BabyPhoto photo;
  final bool isSwahili;
  final VoidCallback onLongPress;

  const _PhotoTimelineItem({
    required this.photo,
    required this.isSwahili,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('d MMM yyyy, HH:mm').format(photo.createdAt);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                photo.displayUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(Icons.broken_image_rounded,
                        size: 32, color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (photo.caption != null &&
                      photo.caption!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        photo.caption!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _kPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                            fontSize: 11, color: _kSecondary),
                      ),
                      const Spacer(),
                      Text(
                        isSwahili
                            ? 'Bonyeza kwa muda kushiriki'
                            : 'Long press to share',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
