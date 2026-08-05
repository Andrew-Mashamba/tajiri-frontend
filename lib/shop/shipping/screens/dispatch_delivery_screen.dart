import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/shop_models.dart';
import '../models/delivery_models.dart';
import '../services/delivery_dispatch_service.dart';

// DESIGN.md tokens
const Color _kBg = Color(0xFFFAFAFA);
const Color _kSurface = Color(0xFFFFFFFF);
const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kDivider = Color(0xFFE0E0E0);

// ─── Dispatch Delivery Screen ─────────────────────────────────────────────
//
// Shows all provider quotes in a comparison card list.
// Seller selects a provider and taps "Dispatch" to send the delivery.
// Returns a DeliveryResult to the caller on success.

class DispatchDeliveryScreen extends StatefulWidget {
  final Order order;
  final int sellerId;
  final String sellerName;
  final String sellerPhone;
  final String sellerAddress;
  final String authToken;

  const DispatchDeliveryScreen({
    super.key,
    required this.order,
    required this.sellerId,
    required this.sellerName,
    required this.sellerPhone,
    required this.sellerAddress,
    required this.authToken,
  });

  @override
  State<DispatchDeliveryScreen> createState() => _DispatchDeliveryScreenState();
}

class _DispatchDeliveryScreenState extends State<DispatchDeliveryScreen> {
  final _service = DeliveryDispatchService.instance;

  List<DeliveryQuote> _quotes = [];
  bool _loadingQuotes = true;
  bool _dispatching = false;
  DeliveryProviderType? _selected;
  String? _error;

  // Weight / notes controllers
  final _weightController = TextEditingController(text: '1.0');
  final _notesController = TextEditingController();
  bool _showOptions = false;

  @override
  void initState() {
    super.initState();
    _fetchQuotes();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchQuotes() async {
    setState(() {
      _loadingQuotes = true;
      _error = null;
    });
    try {
      final quotes = await _service.getQuotes(
        orderId: widget.order.id,
        userId: widget.sellerId,
        token: widget.authToken,
        weightKg: double.tryParse(_weightController.text) ?? 1.0,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      if (!mounted) return;
      setState(() {
        _quotes = quotes;
        _loadingQuotes = false;
        final available = quotes.where((q) => q.available).toList();
        if (available.isNotEmpty) _selected = available.first.provider;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingQuotes = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _dispatch() async {
    if (_selected == null) return;
    HapticFeedback.lightImpact();
    setState(() => _dispatching = true);

    final result = await _service.dispatch(
      orderId: widget.order.id,
      userId: widget.sellerId,
      token: widget.authToken,
      provider: _selected!,
      weightKg: double.tryParse(_weightController.text) ?? 1.0,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;
    setState(() => _dispatching = false);

    if (result.success) {
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'Dispatch failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Dispatch Delivery',
          style: TextStyle(color: _kPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: _kSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: Icon(
              _showOptions ? Icons.tune_rounded : Icons.tune_outlined,
              color: _kPrimary,
            ),
            tooltip: 'Options',
            onPressed: () => setState(() => _showOptions = !_showOptions),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummary(),
                    const SizedBox(height: 16),
                    if (_showOptions) ...[
                      _buildOptions(),
                      const SizedBox(height: 16),
                    ],
                    _buildQuoteList(),
                    const SizedBox(height: 16),
                    _buildProviderInfoFooter(),
                  ],
                ),
              ),
            ),
            _buildDispatchButton(),
          ],
        ),
      ),
    );
  }

  // ─── Order Summary Card ──────────────────────────────────────────

  Widget _buildOrderSummary() {
    final order = widget.order;
    final buyer = order.buyer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long_rounded, size: 16, color: _kSecondary),
            const SizedBox(width: 8),
            Text(
              'Order #${order.orderNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const Spacer(),
            Text(order.totalFormatted,
                style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary)),
          ]),
          const SizedBox(height: 12),
          const Divider(color: _kDivider, height: 1),
          const SizedBox(height: 12),
          _locationRow(
            icon: Icons.storefront_rounded,
            label: 'Pickup',
            title: widget.sellerName,
            subtitle: widget.sellerAddress,
          ),
          const SizedBox(height: 10),
          _locationRow(
            icon: Icons.location_on_rounded,
            label: 'Drop-off',
            title: buyer?.fullName ?? 'Customer',
            subtitle: order.deliveryAddress ?? 'Address not provided',
          ),
        ],
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: _kPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: _kTertiary)),
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: _kPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Options (weight, notes) ─────────────────────────────────────

  Widget _buildOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Package Details',
              style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary, fontSize: 14)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('Weight (kg)', Icons.scale_rounded),
                onChanged: (_) => _fetchQuotes(),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            decoration: _inputDecoration('Delivery notes (optional)', Icons.edit_note_rounded),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kTertiary, fontSize: 13),
        prefixIcon: Icon(icon, size: 18, color: _kSecondary),
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  // ─── Quote List ──────────────────────────────────────────────────

  Widget _buildQuoteList() {
    if (_loadingQuotes) {
      return Column(
        children: [
          const Text('Getting quotes from all providers...',
              style: TextStyle(color: _kSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          ...List.generate(4, (_) => _buildQuoteShimmer()),
        ],
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _kSurface, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          const Icon(Icons.wifi_off_rounded, color: _kTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Could not load quotes', style: TextStyle(fontWeight: FontWeight.w600, color: _kPrimary)),
              Text(_error!, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
            ]),
          ),
          TextButton(onPressed: _fetchQuotes, child: const Text('Retry')),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select a Provider',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kPrimary, fontSize: 14)),
        const SizedBox(height: 10),
        ..._quotes.map((q) => _buildQuoteCard(q)),
      ],
    );
  }

  Widget _buildQuoteCard(DeliveryQuote quote) {
    final isSelected = _selected == quote.provider;
    final isAvailable = quote.available;

    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selected = quote.provider) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _kPrimary : _kDivider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Provider logo / icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isAvailable ? _kPrimary : _kDivider,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _providerIcon(quote.provider),
                size: 22,
                color: isAvailable ? Colors.white : _kTertiary,
              ),
            ),
            const SizedBox(width: 12),

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      quote.provider.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isAvailable ? _kPrimary : _kTertiary,
                        fontSize: 14,
                      ),
                    ),
                    if (!quote.provider.isAvailable) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Setup needed',
                            style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 2),
                  Text(
                    isAvailable
                        ? (quote.vehicleType ?? quote.provider.description)
                        : (quote.unavailableReason ?? quote.provider.description),
                    style: TextStyle(
                      fontSize: 12,
                      color: isAvailable ? _kSecondary : _kTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Price + ETA
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  quote.priceFormatted,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isAvailable ? _kPrimary : _kTertiary,
                  ),
                ),
                if (quote.available && quote.estimatedDuration != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    quote.etaFormatted,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ],
            ),

            // Selection indicator
            if (isAvailable) ...[
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isSelected ? _kPrimary : Colors.transparent,
                  border: Border.all(color: isSelected ? _kPrimary : _kDivider, width: 2),
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteShimmer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 72,
      decoration: BoxDecoration(color: _kDivider.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(14)),
    );
  }

  // ─── Provider info footer ────────────────────────────────────────

  Widget _buildProviderInfoFooter() {
    final unconfigured = _quotes.where((q) => !q.available && !q.provider.isAvailable).toList();
    if (unconfigured.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF9EC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${unconfigured.length} provider${unconfigured.length > 1 ? 's' : ''} need API setup. '
              'Configure them in DeliveryConfig to unlock quotes and dispatch.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Dispatch Button ─────────────────────────────────────────────

  Widget _buildDispatchButton() {
    final selectedQuote = _selected != null
        ? _quotes.where((q) => q.provider == _selected).firstOrNull
        : null;
    final label = selectedQuote != null
        ? 'Dispatch via ${selectedQuote.provider.displayName}'
        : 'Select a provider';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(top: BorderSide(color: _kDivider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selected != null && !_dispatching ? _dispatch : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kDivider,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _dispatching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    label,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Icons ───────────────────────────────────────────────────────

  IconData _providerIcon(DeliveryProviderType p) {
    switch (p) {
      case DeliveryProviderType.tajiri:
        return Icons.local_shipping_rounded;
      case DeliveryProviderType.sendy:
        return Icons.two_wheeler_rounded;
      case DeliveryProviderType.whatsapp:
        return Icons.chat_rounded;
      case DeliveryProviderType.piki:
        return Icons.directions_bike_rounded;
      case DeliveryProviderType.afriDelivery:
        return Icons.local_shipping_rounded;
      case DeliveryProviderType.lori:
        return Icons.fire_truck_rounded;
      case DeliveryProviderType.selfDelivery:
        return Icons.person_pin_circle_rounded;
    }
  }
}
