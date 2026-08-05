import 'package:flutter/material.dart';
import '../../data/repositories/shop_repository.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key, this.productId, this.currentUserId});

  final int? productId;
  final int? currentUserId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ShopRepository _repo = ShopRepository.instance;
  final TextEditingController _reviewController = TextEditingController();

  int _selectedRating = 0;
  bool _submitting = false;
  String? _errorMessage;

  static const List<String> _ratingLabels = [
    '',
    'Terrible',
    'Poor',
    'Okay',
    'Good',
    'Excellent',
  ];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _selectedRating > 0 && _reviewController.text.trim().length >= 10;

  Future<void> _submit() async {
    final text = _reviewController.text.trim();
    if (_selectedRating == 0) {
      setState(() => _errorMessage = 'Please select a star rating.');
      return;
    }
    if (text.length < 10) {
      setState(() => _errorMessage = 'Review must be at least 10 characters.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _repo.createReview(
        productId: widget.productId ?? 0,
        userId: widget.currentUserId ?? 0,
        rating: _selectedRating,
        comment: text,
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: _kText,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _submitting = false;
          _errorMessage = result.message ?? 'Failed to submit review. Please try again.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Write a Review',
          style: TextStyle(color: _kText, fontWeight: FontWeight.w600),
        ),
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        foregroundColor: _kText,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.productId != null) ...[
                _buildProductCard(),
                const SizedBox(height: 20),
              ],
              _buildRatingSection(),
              const SizedBox(height: 24),
              _buildReviewField(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildError(),
              ],
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: _kSecondary, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productId != null ? 'Product #${widget.productId}' : 'Your Purchase',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Share your experience with this product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'How would you rate this product?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= _selectedRating;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = star;
                    _errorMessage = null;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    filled ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 44,
                    color: filled ? _kText : const Color(0xFFCCCCCC),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedRating > 0
                ? Text(
                    _ratingLabels[_selectedRating],
                    key: ValueKey(_selectedRating),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _kText,
                    ),
                  )
                : const Text(
                    'Tap a star to rate',
                    key: ValueKey('placeholder'),
                    style: TextStyle(fontSize: 14, color: _kSecondary),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Review',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kText),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _reviewController,
            maxLines: 6,
            minLines: 3,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_errorMessage != null) {
                setState(() => _errorMessage = null);
              }
            },
            decoration: InputDecoration(
              hintText:
                  'Tell others what you liked or disliked about this product. Be specific and helpful.',
              hintStyle: const TextStyle(color: _kSecondary, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              counterStyle: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Minimum 10 characters required.',
          style: TextStyle(fontSize: 12, color: _kSecondary),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFCC0000)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Color(0xFFCC0000)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: (_submitting || !_isValid) ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: _kText,
          disabledBackgroundColor: const Color(0xFFCCCCCC),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Submit Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
