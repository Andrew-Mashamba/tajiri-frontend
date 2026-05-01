import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/wave_h_services.dart';

/// Spec F10 #96 — Per-stop reviews on multi-day tours.
class PerStopReviewSheet extends StatefulWidget {
  final int userId;
  final int eventBookingId;
  final int stopIndex;
  final String stopTitle;
  const PerStopReviewSheet({
    super.key,
    required this.userId,
    required this.eventBookingId,
    required this.stopIndex,
    required this.stopTitle,
  });

  static Future<bool> show(
    BuildContext context, {
    required int userId,
    required int eventBookingId,
    required int stopIndex,
    required String stopTitle,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PerStopReviewSheet(
          userId: userId,
          eventBookingId: eventBookingId,
          stopIndex: stopIndex,
          stopTitle: stopTitle,
        ),
      ),
    );
    return saved == true;
  }

  @override
  State<PerStopReviewSheet> createState() => _PerStopReviewSheetState();
}

class _PerStopReviewSheetState extends State<PerStopReviewSheet> {
  int _stars = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final id = await TourStopReviewsService.add(
      userId: widget.userId,
      eventBookingId: widget.eventBookingId,
      stopIndex: widget.stopIndex,
      stars: _stars,
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context, id != null);
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSw ? 'Tathmini' : 'Review',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.stopTitle,
            style: const TextStyle(fontSize: 13, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final filled = i < _stars;
              return IconButton(
                onPressed: () => setState(() => _stars = i + 1),
                icon: Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 32,
                  color: filled
                      ? const Color(0xFFFFC107)
                      : const Color(0xFF999999),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: isSw ? 'Maoni (hiari)' : 'Comment (optional)',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting
                  ? (isSw ? 'Inatuma…' : 'Sending…')
                  : (isSw ? 'Tuma' : 'Submit')),
            ),
          ),
        ],
      ),
    );
  }
}
