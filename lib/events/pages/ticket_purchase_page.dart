// lib/events/pages/ticket_purchase_page.dart
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_enums.dart';
import '../models/event_strings.dart';
import '../models/event_ticket.dart';
import '../models/promo_code.dart';
import '../services/ticket_service.dart';
import '../../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class TicketPurchasePage extends StatefulWidget {
  final int userId;
  final Event event;

  const TicketPurchasePage({
    super.key,
    required this.userId,
    required this.event,
  });

  @override
  State<TicketPurchasePage> createState() => _TicketPurchasePageState();
}

class _TicketPurchasePageState extends State<TicketPurchasePage> {
  final TicketService _service = TicketService();
  final TextEditingController _promoController = TextEditingController();
  late EventStrings _strings;

  TicketTier? _selectedTier;
  int _quantity = 1;
  PaymentMethod _paymentMethod = PaymentMethod.mpesa;
  PromoValidation? _promoValidation;
  bool _isValidatingPromo = false;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    final lang = LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw';
    _strings = EventStrings(isSwahili: lang == 'sw');
    if (widget.event.ticketTiers.isNotEmpty) {
      _selectedTier = widget.event.ticketTiers.first;
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  double get _subtotal => (_selectedTier?.price ?? 0) * _quantity;

  double get _discount {
    if (_promoValidation == null || !_promoValidation!.isValid) return 0;
    final v = _promoValidation!;
    // Use pre-computed discountAmount from server, or fall back to promo calculation
    if (v.discountAmount != null) return v.discountAmount!;
    if (v.promo != null) return v.promo!.calculateDiscount(_subtotal);
    return 0;
  }

  double get _total => (_subtotal - _discount).clamp(0, double.infinity);

  Future<void> _validatePromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isValidatingPromo = true);
    final result = await _service.validatePromoCode(
      eventId: widget.event.id,
      code: code,
    );
    if (mounted) {
      setState(() {
        _isValidatingPromo = false;
        _promoValidation = result;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? (result.isValid
            ? (_strings.isSwahili ? 'Msimbo umekubaliwa!' : 'Code accepted!')
            : (_strings.isSwahili ? 'Msimbo hauko sahihi' : 'Invalid code'))),
        backgroundColor: result.isValid ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Future<void> _purchase() async {
    if (_selectedTier == null) return;
    setState(() => _isPurchasing = true);
    final result = await _service.purchaseTicket(
      eventId: widget.event.id,
      tierId: _selectedTier!.id,
      quantity: _quantity,
      paymentMethod: _paymentMethod,
      promoCode: (_promoValidation?.isValid == true) ? _promoController.text.trim() : null,
    );
    if (!mounted) return;
    setState(() => _isPurchasing = false);
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_strings.ticketPurchased),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context, result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.message ?? _strings.loadError),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiers = widget.event.ticketTiers;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_strings.buyTickets,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary)),
            Text(widget.event.name,
                style: const TextStyle(fontSize: 12, color: _kSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Tier Selection ──
          Text(_strings.selectTier,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          if (tiers.isEmpty)
            _sectionCard(child: Text(_strings.noEvents,
                style: const TextStyle(color: _kSecondary, fontSize: 14)))
          else
            _sectionCard(
              child: Column(
                children: tiers.map((tier) {
                  final selected = _selectedTier?.id == tier.id;
                  return RadioListTile<int>(
                    value: tier.id,
                    groupValue: _selectedTier?.id,
                    activeColor: _kPrimary,
                    contentPadding: EdgeInsets.zero,
                    title: Text(tier.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: _kPrimary,
                        )),
                    subtitle: Text(
                      tier.isFree
                          ? _strings.free
                          : _strings.formatPrice(tier.price, tier.currency),
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? _kPrimary : _kSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    secondary: tier.isSoldOut
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_strings.soldOut,
                                style: const TextStyle(fontSize: 11, color: _kSecondary)),
                          )
                        : null,
                    onChanged: tier.isSoldOut
                        ? null
                        : (_) => setState(() {
                              _selectedTier = tier;
                              _quantity = tier.minPerOrder;
                            }),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),

          // ── Quantity ──
          Text(_strings.quantity,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          _sectionCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_strings.quantity,
                    style: const TextStyle(fontSize: 14, color: _kSecondary)),
                Row(
                  children: [
                    _stepperButton(
                      icon: Icons.remove_rounded,
                      onTap: _quantity > (_selectedTier?.minPerOrder ?? 1)
                          ? () => setState(() => _quantity--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('$_quantity',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary)),
                    ),
                    _stepperButton(
                      icon: Icons.add_rounded,
                      onTap: _quantity < (_selectedTier?.maxPerOrder ?? 10)
                          ? () => setState(() => _quantity++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Promo Code ──
          Text(_strings.promoCode,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          _sectionCard(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: _strings.promoCode,
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      suffixIcon: _promoValidation?.isValid == true
                          ? const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20)
                          : null,
                    ),
                    style: const TextStyle(fontSize: 14, color: _kPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                _isValidatingPromo
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
                    : TextButton(
                        onPressed: _validatePromo,
                        style: TextButton.styleFrom(
                          foregroundColor: _kPrimary,
                          minimumSize: const Size(48, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(_strings.applyCode,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Payment Method ──
          Text(_strings.paymentMethod,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          _sectionCard(
            child: Column(
              children: [
                PaymentMethod.mpesa,
                PaymentMethod.tigoPesa,
                PaymentMethod.airtelMoney,
                PaymentMethod.wallet,
                PaymentMethod.card,
              ].map((method) {
                return RadioListTile<PaymentMethod>(
                  value: method,
                  groupValue: _paymentMethod,
                  activeColor: _kPrimary,
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(method.icon, size: 18, color: _kSecondary),
                      const SizedBox(width: 8),
                      Text(method.displayName,
                          style: const TextStyle(fontSize: 14, color: _kPrimary)),
                    ],
                  ),
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // ── Summary ──
          Text(_strings.total,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          _sectionCard(
            child: Column(
              children: [
                _summaryRow('Jumla Ndogo / Subtotal',
                    _strings.formatPrice(_subtotal, _selectedTier?.currency ?? 'TZS')),
                if (_discount > 0)
                  _summaryRow('Punguzo / Discount',
                      '- ${_strings.formatPrice(_discount, _selectedTier?.currency ?? 'TZS')}',
                      valueColor: Colors.green.shade700),
                const Divider(height: 20),
                _summaryRow(_strings.total,
                    _strings.formatPrice(_total, _selectedTier?.currency ?? 'TZS'),
                    bold: true),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isPurchasing || _selectedTier == null) ? null : _purchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isPurchasing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      '${_strings.buyTickets} · ${_strings.formatPrice(_total, _selectedTier?.currency ?? 'TZS')}',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget _stepperButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: onTap != null ? _kPrimary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? Colors.white : Colors.grey),
      ),
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 13,
                color: bold ? _kPrimary : _kSecondary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              )),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                color: valueColor ?? (bold ? _kPrimary : _kSecondary),
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              )),
        ],
      ),
    );
  }
}
