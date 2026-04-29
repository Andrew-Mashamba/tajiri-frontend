import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/message_service.dart';
import '../../tajirika/services/partner_product_service.dart';
import '../models/customer_order.dart';
import '../models/partner_review.dart';
import '../services/image_similarity_service.dart';
import '../services/partner_review_service.dart';

/// Spec line 1099 — per-source aspect dimensions. Each source surfaces a
/// curated set of 2–3 dimension keys that customers rate on a 1-5 scale.
/// Returned bilingual labels by [_dimensionLabel].
const Map<CustomerOrderSource, List<String>> _kDimensionKeysBySource = {
  CustomerOrderSource.serviceRequest: ['quality', 'timeliness', 'value'],
  CustomerOrderSource.garageBooking: ['diagnostic', 'quality', 'communication'],
  CustomerOrderSource.appointment: ['result', 'hygiene', 'professionalism'],
  CustomerOrderSource.consultation: ['knowledge', 'empathy', 'follow_up'],
  CustomerOrderSource.engagement: ['quality', 'communication', 'timeliness'],
  CustomerOrderSource.listingInquiry: ['accuracy', 'responsiveness'],
  CustomerOrderSource.eventBooking: ['punctuality', 'set_quality', 'energy'],
  CustomerOrderSource.partnerProduct: ['accuracy', 'packaging', 'lead_time'],
  CustomerOrderSource.chefListing: ['taste', 'portion', 'freshness'],
  CustomerOrderSource.chefProduct: ['taste', 'portion', 'freshness'],
};

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kStarOn = Color(0xFFFFB300);
const Color _kStarOff = Color(0xFFE0E0E0);

/// Spec §11 line 1060 — shared customer rating page used across all 10 sources.
class RatePartnerPage extends StatefulWidget {
  final int reviewerUserId;
  final CustomerOrderSource source;
  final int sourceId;
  /// Optional preview pieces shown at top of the page.
  final String? partnerName;
  /// Spec line 1093 — passed through to enable direct chat-thread resolution
  /// for the F11 anti-troll handoff when a low-rating review is left.
  final int? partnerUserId;
  final String? itemTitle;
  final PartnerReview? existing;

  const RatePartnerPage({
    super.key,
    required this.reviewerUserId,
    required this.source,
    required this.sourceId,
    this.partnerName,
    this.partnerUserId,
    this.itemTitle,
    this.existing,
  });

  @override
  State<RatePartnerPage> createState() => _RatePartnerPageState();
}

class _RatePartnerPageState extends State<RatePartnerPage> {
  int _stars = 0;
  final _commentCtrl = TextEditingController();
  final Set<ReviewTag> _tags = <ReviewTag>{};
  bool _anonymous = false;
  bool _submitting = false;
  bool _uploadingMedia = false;
  String? _error;
  /// Spec line 1099 — per-aspect dimension ratings. Key → 1-5 stars.
  final Map<String, int> _dimensions = <String, int>{};
  /// Spec line 1102 — photo+video review attachments (URLs after upload).
  final List<String> _mediaUrls = <String>[];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;
  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    if (ex != null) {
      _stars = ex.stars;
      _commentCtrl.text = ex.comment ?? '';
      _anonymous = ex.isAnonymous;
      for (final t in ex.tags) {
        final parsed = ReviewTag.fromString(t);
        if (parsed != null) _tags.add(parsed);
      }
      if (ex.dimensions != null) _dimensions.addAll(ex.dimensions!);
      _mediaUrls.addAll(ex.mediaUrls);
    }
  }

  String _dimensionLabel(String key) {
    final sw = _isSwahili;
    switch (key) {
      case 'quality':         return sw ? 'Ubora' : 'Quality';
      case 'timeliness':      return sw ? 'Wakati' : 'Timeliness';
      case 'value':           return sw ? 'Thamani' : 'Value';
      case 'diagnostic':      return sw ? 'Uchunguzi' : 'Diagnostic';
      case 'communication':   return sw ? 'Mawasiliano' : 'Communication';
      case 'result':          return sw ? 'Matokeo' : 'Result';
      case 'hygiene':         return sw ? 'Usafi' : 'Hygiene';
      case 'professionalism': return sw ? 'Utaalamu' : 'Professionalism';
      case 'knowledge':       return sw ? 'Maarifa' : 'Knowledge';
      case 'empathy':         return sw ? 'Huruma' : 'Empathy';
      case 'follow_up':       return sw ? 'Ufuatiliaji' : 'Follow-up';
      case 'accuracy':        return sw ? 'Usahihi' : 'Accuracy';
      case 'responsiveness':  return sw ? 'Mwitiko' : 'Responsiveness';
      case 'punctuality':     return sw ? 'Kufika kwa wakati' : 'Punctuality';
      case 'set_quality':     return sw ? 'Ubora wa onyesho' : 'Set quality';
      case 'energy':          return sw ? 'Nguvu' : 'Energy';
      case 'packaging':       return sw ? 'Ufungashaji' : 'Packaging';
      case 'lead_time':       return sw ? 'Muda wa kuandaa' : 'Lead time';
      case 'taste':           return sw ? 'Ladha' : 'Taste';
      case 'portion':         return sw ? 'Sehemu' : 'Portion';
      case 'freshness':       return sw ? 'Hali ya kufu' : 'Freshness';
      default:                return key;
    }
  }

  Future<void> _addMedia() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploadingMedia = true);
    final res = await PartnerProductService.uploadPhoto(
      userId: widget.reviewerUserId,
      file: File(picked.path),
    );
    if (!mounted) return;
    setState(() => _uploadingMedia = false);
    if (res.success && (res.photoUrl ?? '').isNotEmpty) {
      // Spec line 244 — image-similarity guard. Block obvious copy-paste fraud
      // before the photo lands in the customer's media list.
      final guard = await ImageSimilarityService.check(imageUrl: res.photoUrl!);
      if (!mounted) return;
      if (guard != null && guard.flagged) {
        _toast(_isSwahili
            ? 'Picha hii imeshatumika kwenye mapitio mengine. Chukua picha mpya.'
            : 'This photo looks identical to another review. Please take a fresh one.');
        return;
      }
      setState(() => _mediaUrls.add(res.photoUrl!));
    } else {
      _toast(res.message ?? (_isSwahili ? 'Imeshindikana kupakua' : 'Upload failed'));
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _submit() async {
    if (_stars < 1 || _stars > 5) {
      _toast(_isSwahili ? 'Chagua nyota (1–5)' : 'Pick stars (1–5)');
      return;
    }
    // Spec line 1102 — anti-troll cushion: ≤2-star reviews require a photo
    // proof before publishing. Forces the reviewer to substantiate harsh ratings.
    if (_stars <= 2 && _mediaUrls.isEmpty) {
      _toast(_isSwahili
          ? 'Maoni ya nyota 2 au chini ya hapo yanahitaji picha ya ushahidi.'
          : 'Reviews of 2★ or lower need a photo for proof.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final tagList = _tags.map((t) => t.apiValue).toList();
    final dimsToSend = _dimensions.isEmpty ? null : Map<String, int>.from(_dimensions);
    final mediaToSend = _mediaUrls.isEmpty ? null : List<String>.from(_mediaUrls);
    final res = _isEdit
        ? await PartnerReviewService.edit(
            id: widget.existing!.id,
            reviewerUserId: widget.reviewerUserId,
            stars: _stars,
            comment: _commentCtrl.text.trim(),
            tags: tagList,
            isAnonymous: _anonymous,
            dimensions: dimsToSend,
            mediaUrls: mediaToSend,
          )
        : await PartnerReviewService.rate(
            source: widget.source,
            sourceId: widget.sourceId,
            reviewerUserId: widget.reviewerUserId,
            stars: _stars,
            comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
            tags: tagList,
            isAnonymous: _anonymous,
            dimensions: dimsToSend,
            mediaUrls: mediaToSend,
          );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.review != null) {
      _toast(_isEdit
          ? (_isSwahili ? 'Maoni yamesasishwa' : 'Review updated')
          : (_isSwahili ? 'Asante! Maoni yamefika.' : 'Thanks! Review submitted.'));
      // Spec line 1093 — anti-troll Chat handoff for ≤3-star reviews so the
      // customer has a non-public path to surface concerns before they land
      // permanently on the partner's profile.
      if (_stars <= 3 && !_isEdit) {
        await _offerChatHandoff();
      }
      if (!mounted) return;
      Navigator.of(context).pop(res.review);
    } else {
      setState(() => _error = res.message ?? 'Failed');
    }
  }

  Future<void> _offerChatHandoff() async {
    final sw = _isSwahili;
    final partnerLabel = widget.partnerName ?? (sw ? 'mshirika' : 'the partner');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.forum_rounded, color: _kPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      sw
                          ? 'Pia tutumie ujumbe kwa $partnerLabel?'
                          : 'Also send a message to $partnerLabel?',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                sw
                    ? 'Wasiliana faragha ili upate ufafanuzi au suluhu kabla maoni yako kuonekana hadharani.'
                    : 'Message privately to ask questions or get a fix before your review goes public.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: _kPrimary,
                  minimumSize: const Size.fromHeight(44),
                ),
                icon: const Icon(Icons.chat_rounded, size: 18),
                label: Text(sw ? 'Tutumie ujumbe' : 'Send message'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(sw ? 'Hapana, asante' : 'No thanks',
                    style: const TextStyle(color: _kPrimary)),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    // Direct chat resolution via existing /conversations/private/{otherUserId}
    // endpoint (Conversation::getOrCreatePrivate). Falls back to /messages list
    // when partnerUserId isn't known to the caller.
    final otherUserId = widget.partnerUserId;
    if (otherUserId == null) {
      Navigator.of(context).pushNamed('/messages');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isSwahili
            ? 'Tafuta mazungumzo na $partnerLabel'
            : 'Find your thread with $partnerLabel'),
      ));
      return;
    }
    final res = await MessageService().getPrivateConversation(
      widget.reviewerUserId,
      otherUserId,
    );
    if (!mounted) return;
    if (res.success && res.conversation != null) {
      Navigator.of(context).pushNamed(
        '/chat/${res.conversation!.id}',
        arguments: res.conversation,
      );
    } else {
      Navigator.of(context).pushNamed('/messages');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          _isEdit
              ? (_isSwahili ? 'Hariri Maoni' : 'Edit Review')
              : (_isSwahili ? 'Toa Nyota' : 'Rate'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            if (widget.partnerName != null || widget.itemTitle != null)
              _previewCard(),
            if (widget.partnerName != null || widget.itemTitle != null)
              const SizedBox(height: 16),
            _starRow(),
            const SizedBox(height: 16),
            _dimensionsSection(),
            _mediaSection(),
            _section(
              title: _isSwahili ? 'Lebo' : 'Tags',
              subtitle: _isSwahili
                  ? 'Chagua zinazoendana na tukio (hiari)'
                  : 'Pick what fits (optional)',
              child: _tagWrap(),
            ),
            const SizedBox(height: 16),
            _section(
              title: _isSwahili ? 'Maoni' : 'Comment',
              subtitle: _isSwahili
                  ? 'Andika kidogo kuhusu uzoefu wako (hiari, hadi 500)'
                  : 'A few words about your experience (optional, 500 max)',
              child: TextField(
                controller: _commentCtrl,
                minLines: 3,
                maxLines: 8,
                maxLength: 500,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _anonymous,
              onChanged: (v) => setState(() => _anonymous = v),
              title: Text(
                _isSwahili ? 'Ficha jina langu' : 'Hide my name',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
              subtitle: Text(
                _isSwahili
                    ? 'Maoni yataonyeshwa kama "Mteja"'
                    : 'Posts as "Customer"',
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_isEdit
                  ? (_isSwahili ? 'Sasisha' : 'Update')
                  : (_isSwahili ? 'Tuma' : 'Submit')),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            if (_isEdit && widget.existing != null && !widget.existing!.canEdit) ...[
              const SizedBox(height: 8),
              Text(
                _isSwahili
                    ? 'Muda wa kuhariri umepita (saa 24)'
                    : 'Edit window (24h) has passed',
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.partnerName != null)
            Text(
              widget.partnerName!,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          if (widget.itemTitle != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.itemTitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: _kMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _starRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (i) {
          final filled = i < _stars;
          return GestureDetector(
            onTap: () => setState(() => _stars = i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: filled ? _kStarOn : _kStarOff,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _tagWrap() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: ReviewTag.values.map((t) {
        final selected = _tags.contains(t);
        return FilterChip(
          label: Text(_isSwahili ? t.labelSwahili : t.label),
          selected: selected,
          onSelected: (v) => setState(() {
            if (v) {
              _tags.add(t);
            } else {
              _tags.remove(t);
            }
          }),
          selectedColor: t.isPositive
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFEBEE),
          checkmarkColor: t.isPositive
              ? const Color(0xFF1B5E20)
              : const Color(0xFFB71C1C),
          labelStyle: TextStyle(
            fontSize: 11,
            color: selected
                ? (t.isPositive ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C))
                : _kPrimary,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget _dimensionsSection() {
    final keys = _kDimensionKeysBySource[widget.source];
    if (keys == null || keys.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _section(
        title: _isSwahili ? 'Vipengele' : 'Aspects',
        subtitle: _isSwahili
            ? 'Toa nyota kwa kila kipengele (hiari)'
            : 'Rate each aspect (optional)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: keys.map((k) => _dimensionRow(k)).toList(),
        ),
      ),
    );
  }

  Widget _dimensionRow(String key) {
    final selected = _dimensions[key] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              _dimensionLabel(key),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...List.generate(5, (i) {
            final filled = i < selected;
            return GestureDetector(
              onTap: () => setState(() {
                if (selected == i + 1) {
                  _dimensions.remove(key);
                } else {
                  _dimensions[key] = i + 1;
                }
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 22,
                  color: filled ? const Color(0xFFFFB300) : const Color(0xFFBDBDBD),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _mediaSection() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _section(
        title: _isSwahili ? 'Picha' : 'Photos',
        subtitle: _isSwahili
            ? 'Pakia hadi picha 10 zinazoonyesha kazi (hiari)'
            : 'Up to 10 photos showing the work (optional)',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ..._mediaUrls.map((url) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            url,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 70,
                              height: 70,
                              color: const Color(0xFFEEEEEE),
                              child: const Icon(Icons.broken_image_rounded),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _mediaUrls.remove(url)),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    )),
                if (_mediaUrls.length < 10)
                  GestureDetector(
                    onTap: _uploadingMedia ? null : _addMedia,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: const Color(0xFFBDBDBD), style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _uploadingMedia
                          ? const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.add_a_photo_rounded,
                              size: 24, color: Color(0xFF666666)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({required String title, String? subtitle, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: _kMuted)),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
