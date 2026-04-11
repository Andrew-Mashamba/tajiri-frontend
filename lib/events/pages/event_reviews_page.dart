// lib/events/pages/event_reviews_page.dart
import 'package:flutter/material.dart';
import '../models/event_strings.dart';
import '../models/event_review.dart';
import '../services/event_wall_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class EventReviewsPage extends StatefulWidget {
  final int eventId;

  const EventReviewsPage({super.key, required this.eventId});

  @override
  State<EventReviewsPage> createState() => _EventReviewsPageState();
}

class _EventReviewsPageState extends State<EventReviewsPage> {
  final _wallService = EventWallService();
  final _reviewCtrl = TextEditingController();

  List<EventReview> _reviews = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _submitting = false;
  int _currentPage = 1;
  int _lastPage = 1;
  int _draftRating = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReviews({bool refresh = false}) async {
    if (refresh) setState(() { _currentPage = 1; _loading = true; });
    final result = await _wallService.getReviews(
      eventId: widget.eventId,
      page: _currentPage,
    );
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _lastPage = result.lastPage ?? 1;
        if (refresh || _currentPage == 1) {
          _reviews = result.items ?? [];
        } else {
          _reviews.addAll(result.items ?? []);
        }
        _loading = false;
        _loadingMore = false;
      });
    } else {
      setState(() { _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _submitReview() async {
    if (_draftRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Tafadhali chagua nyota' : 'Please select a rating'), backgroundColor: _kPrimary),
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await _wallService.submitReview(
      eventId: widget.eventId,
      rating: _draftRating,
      content: _reviewCtrl.text.trim().isNotEmpty ? _reviewCtrl.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.success) {
      _reviewCtrl.clear();
      setState(() => _draftRating = 0);
      await _loadReviews(refresh: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Maoni yametumwa!' : 'Review submitted!'), backgroundColor: _kPrimary),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (Localizations.localeOf(context).languageCode == 'sw' ? 'Imeshindwa' : 'Failed')), backgroundColor: _kPrimary),
      );
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification &&
        n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
        !_loadingMore && _currentPage < _lastPage) {
      setState(() { _currentPage++; _loadingMore = true; });
      _loadReviews();
    }
    return false;
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final strings = EventStrings(isSwahili: Localizations.localeOf(context).languageCode == 'sw');
    return Scaffold(
      backgroundColor: _kBg,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: RefreshIndicator(
                color: _kPrimary,
                onRefresh: () => _loadReviews(refresh: true),
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 16),
                  children: [
                    if (_reviews.isNotEmpty) _RatingSummary(
                      average: _averageRating,
                      count: _reviews.length,
                    ),
                    _SubmitReviewCard(
                      controller: _reviewCtrl,
                      rating: _draftRating,
                      submitting: _submitting,
                      onRatingChanged: (r) => setState(() => _draftRating = r),
                      onSubmit: _submitReview,
                    ),
                    if (_reviews.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.star_outline_rounded, size: 48, color: _kSecondary),
                          const SizedBox(height: 12),
                          Text(strings.noReviews,
                              style: const TextStyle(color: _kSecondary, fontSize: 14)),
                        ]),
                      )
                    else
                      ..._reviews.map((r) => _ReviewCard(review: r)),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(color: _kPrimary)),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double average;
  final int count;
  const _RatingSummary({required this.average, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(children: [
        Text(average.toStringAsFixed(1),
            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(width: 16),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StarRow(rating: average.round()),
          const SizedBox(height: 4),
          Text('$count ${count == 1 ? "maoni" : "maoni"}',
              style: const TextStyle(fontSize: 12, color: _kSecondary)),
        ]),
      ]),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  final double size;
  const _StarRow({required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(
      i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
      size: size,
      color: _kPrimary,
    )));
  }
}

class _SubmitReviewCard extends StatelessWidget {
  final TextEditingController controller;
  final int rating;
  final bool submitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  const _SubmitReviewCard({
    required this.controller,
    required this.rating,
    required this.submitting,
    required this.onRatingChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Tuma Maoni Yako' : 'Submit Your Review',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
          return GestureDetector(
            onTap: () => onRatingChanged(i + 1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 32,
                color: _kPrimary,
              ),
            ),
          );
        })),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          maxLines: 3,
          minLines: 2,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 14, color: _kPrimary),
          decoration: InputDecoration(
            hintText: Localizations.localeOf(context).languageCode == 'sw' ? 'Andika maoni yako (si lazima)...' : 'Write your review (optional)...',
            hintStyle: const TextStyle(color: _kSecondary, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _kPrimary),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: submitting ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: submitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(Localizations.localeOf(context).languageCode == 'sw' ? 'Tuma' : 'Submit', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final EventReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final author = review.user;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFE0E0E0),
            backgroundImage: author?.avatarUrl != null ? NetworkImage(author!.avatarUrl!) : null,
            child: author?.avatarUrl == null
                ? Text(author?.firstName.isNotEmpty == true ? author!.firstName[0] : '?',
                    style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              author?.fullName ?? 'User',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _kPrimary),
            ),
            Row(children: List.generate(5, (i) => Icon(
              i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 14,
              color: _kPrimary,
            ))),
          ])),
          Text(
            _formatDate(review.createdAt),
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
        ]),
        if (review.content != null && review.content!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.content!,
              style: const TextStyle(fontSize: 14, color: _kPrimary, height: 1.4)),
        ],
      ]),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
