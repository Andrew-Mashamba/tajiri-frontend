import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../config/api_config.dart';
import '../../../models/shop_models.dart';
import '../../../services/local_storage_service.dart';
import '../../../widgets/cached_media_image.dart';
import '../services/offer_service.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);
const Color _kGreen = Color(0xFF10B981);

final _tzsFmt = NumberFormat('#,##0', 'en_US');

String _formatTzs(double v) => 'TZS ${_tzsFmt.format(v)}';

/// Full-screen "Make an Offer" screen opened by buyers on a product.
class MakeOfferScreen extends StatefulWidget {
  final Product product;

  const MakeOfferScreen({super.key, required this.product});

  @override
  State<MakeOfferScreen> createState() => _MakeOfferScreenState();
}

class _MakeOfferScreenState extends State<MakeOfferScreen> {
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  final _priceFocus = FocusNode();

  double _offeredPrice = 0.0;
  bool _submitting = false;

  double get _minPrice => widget.product.price * 0.5;
  double get _savingsAmount => (_offeredPrice > 0 && _offeredPrice < widget.product.price)
      ? widget.product.price - _offeredPrice
      : 0.0;
  double get _savingsPercent => widget.product.price > 0
      ? (_savingsAmount / widget.product.price) * 100
      : 0.0;

  bool get _isValidPrice => _offeredPrice >= _minPrice && _offeredPrice > 0;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_onPriceChanged);
  }

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    _priceFocus.dispose();
    super.dispose();
  }

  void _onPriceChanged() {
    final raw = _priceController.text.replaceAll(RegExp(r'[^\d.]'), '');
    final v = double.tryParse(raw) ?? 0.0;
    if (v != _offeredPrice) {
      setState(() => _offeredPrice = v);
    }
  }

  Future<void> _sendOffer() async {
    if (!_isValidPrice || _submitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _submitting = true);

    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to make an offer')),
          );
        }
        setState(() => _submitting = false);
        return;
      }

      final success = await OfferService.makeOffer(
        widget.product.id,
        _offeredPrice,
        token,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );

      if (!mounted) return;
      setState(() => _submitting = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer sent! Seller has 24 hours to respond.'),
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send offer. Please try again.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final thumbnailUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : '';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Make an Offer',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        scrolledUnderElevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product preview card
              _buildProductCard(product, thumbnailUrl),
              const SizedBox(height: 24),

              // Price input
              _buildPriceSection(product),
              const SizedBox(height: 16),

              // Savings indicator
              if (_offeredPrice > 0) _buildSavingsIndicator(),

              const SizedBox(height: 24),

              // Message (optional)
              _buildMessageField(),
              const SizedBox(height: 32),

              // Send button
              _buildSendButton(),
              const SizedBox(height: 12),

              // Powered by Tajiri Pay note
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.lock_rounded, size: 13, color: _kTertiary),
                    SizedBox(width: 5),
                    Text(
                      'Payments powered by Tajiri Pay',
                      style: TextStyle(fontSize: 12, color: _kTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, String thumbnailUrl) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kDivider),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 70,
              height: 70,
              child: thumbnailUrl.isNotEmpty
                  ? CachedMediaImage(
                      imageUrl: ApiConfig.sanitizeUrl(thumbnailUrl),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: _kBg,
                      child: const Icon(Icons.image_outlined, color: _kTertiary),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    color: _kPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Listed at ${product.priceFormatted}',
                  style: const TextStyle(
                    color: _kSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Offer (TZS)',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _priceController,
          focusNode: _priceFocus,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            color: _kPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            hintText: 'e.g. ${_tzsFmt.format(_minPrice.toInt())}',
            hintStyle: const TextStyle(color: _kTertiary, fontSize: 18),
            prefixText: 'TZS ',
            prefixStyle: const TextStyle(
              color: _kSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            helperText: 'Min: ${_formatTzs(_minPrice)} (50% of listed price)',
            helperStyle: const TextStyle(color: _kTertiary, fontSize: 12),
            errorText: (_offeredPrice > 0 && _offeredPrice < _minPrice)
                ? 'Minimum offer is ${_formatTzs(_minPrice)}'
                : null,
            filled: true,
            fillColor: _kSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsIndicator() {
    if (_savingsAmount <= 0 || !_isValidPrice) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_rounded, color: _kGreen, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You save ${_savingsPercent.toStringAsFixed(1)}%  (${_formatTzs(_savingsAmount)})',
              style: const TextStyle(
                color: _kGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Message to seller (optional)',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 500,
          style: const TextStyle(color: _kPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'e.g. "Interested in buying if you can do this price…"',
            hintStyle: const TextStyle(color: _kTertiary, fontSize: 13),
            filled: true,
            fillColor: _kSurface,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kDivider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kPrimary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    final enabled = _isValidPrice && !_submitting;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: enabled ? _sendOffer : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kDivider,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isValidPrice
                    ? 'Send Offer · ${_formatTzs(_offeredPrice)}'
                    : 'Send Offer',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}
