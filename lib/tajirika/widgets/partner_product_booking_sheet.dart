import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/tajirika_models.dart';
import '../services/partner_product_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kError = Color(0xFFE53935);

/// Order sheet shared across all consumer verticals (food, mafundi, events,
/// skincare, hair_nails, fitness, housing). Cluster-specific copy is passed in
/// via [confirmCtaSwahili]. Returns the new order id on success, null on cancel.
Future<int?> showPartnerProductBookingSheet({
  required BuildContext context,
  required PartnerProduct product,
  required int buyerUserId,
  required String confirmCtaSwahili,
  String? defaultDeliveryAddress,
}) async {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _kBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _BookingSheet(
      product: product,
      buyerUserId: buyerUserId,
      confirmCtaSwahili: confirmCtaSwahili,
      defaultDeliveryAddress: defaultDeliveryAddress,
    ),
  );
}

class _BookingSheet extends StatefulWidget {
  final PartnerProduct product;
  final int buyerUserId;
  final String confirmCtaSwahili;
  final String? defaultDeliveryAddress;

  const _BookingSheet({
    required this.product,
    required this.buyerUserId,
    required this.confirmCtaSwahili,
    this.defaultDeliveryAddress,
  });

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  late int _quantity;
  late String _mode;
  late TextEditingController _addressController;
  late TextEditingController _notesController;
  PartnerProductVariant? _variant;
  DateTime? _requestedFor;
  bool _submitting = false;
  String? _error;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _quantity = widget.product.minQuantity > 0 ? widget.product.minQuantity : 1;
    _mode = widget.product.allowedModes.first;
    _addressController = TextEditingController(
      text: widget.defaultDeliveryAddress ?? '',
    );
    _notesController = TextEditingController();
    if (widget.product.variants.isNotEmpty) {
      _variant = widget.product.variants.first;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _unitPrice =>
      _variant?.priceTzs ?? widget.product.basePriceTzs;

  int get _deliveryFee {
    if (_mode != 'delivery') return 0;
    final perKm = widget.product.deliveryFeePerKmTzs ?? 0;
    final radius = widget.product.deliveryRadiusKm ?? 1;
    return perKm * radius;
  }

  int get _total => (_unitPrice * _quantity) + _deliveryFee;

  int get _effectiveLeadHours =>
      _variant?.leadTimeHours ?? widget.product.leadTimeHours;

  String _fmtTzs(int v) {
    final s = v.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return 'TSh ${buf.toString()}';
  }

  Future<void> _pickRequestedFor() async {
    final now = DateTime.now();
    final earliest = now.add(Duration(hours: _effectiveLeadHours));
    final initial = _requestedFor ?? earliest;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(earliest) ? earliest : initial,
      firstDate: earliest,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (pickedTime == null || !mounted) return;
    setState(() {
      _requestedFor = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    final sw = _isSwahili;
    if (_mode == 'delivery' && _addressController.text.trim().isEmpty) {
      setState(() => _error = sw
          ? 'Tafadhali andika anwani ya kufikishwa'
          : 'Please enter a delivery address');
      return;
    }
    if (_requestedFor == null) {
      setState(() =>
          _error = sw ? 'Chagua tarehe na muda' : 'Pick a date and time');
      return;
    }
    final earliest = DateTime.now().add(Duration(hours: _effectiveLeadHours));
    if (_requestedFor!.isBefore(earliest)) {
      setState(() {
        _error = sw
            ? 'Muda lazima uwe angalau saa $_effectiveLeadHours kutoka sasa'
            : 'Time must be at least $_effectiveLeadHours hours from now';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    final res = await PartnerProductService.placeOrder(
      productId: widget.product.id,
      userId: widget.buyerUserId,
      quantity: _quantity,
      deliveryMode: _mode,
      deliveryAddress: _mode == 'delivery'
          ? _addressController.text.trim()
          : null,
      requestedFor: _requestedFor,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      variantId: _variant?.id,
    );
    if (!mounted) return;
    if (res.success) {
      Navigator.of(context).pop(res.orderId);
    } else {
      setState(() {
        _submitting = false;
        _error = res.message ??
            (_isSwahili ? 'Imeshindikana. Jaribu tena' : 'Failed. Try again');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modes = widget.product.allowedModes;
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: _kBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              widget.product.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _fmtTzs(_unitPrice),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _kAccent,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.product.variants.isNotEmpty) ...[
              _label(_isSwahili ? 'Aina' : 'Variant'),
              _variantPicker(),
              const SizedBox(height: 12),
            ],
            _label(_isSwahili ? 'Idadi' : 'Quantity'),
            _quantityStepper(),
            const SizedBox(height: 12),
            if (modes.length > 1) ...[
              _label(_isSwahili ? 'Hali ya kupokea' : 'Receive as'),
              _modePicker(modes),
              const SizedBox(height: 12),
            ],
            if (_mode == 'delivery') ...[
              _label(_isSwahili
                  ? 'Anwani ya kufikishwa'
                  : 'Delivery address'),
              _textField(
                controller: _addressController,
                hint: _isSwahili
                    ? 'Mfano: Mikocheni, Kinondoni, Dar es Salaam'
                    : 'e.g. Mikocheni, Kinondoni, Dar es Salaam',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],
            _label(_isSwahili
                ? 'Tarehe na muda (lead-time saa $_effectiveLeadHours)'
                : 'Date & time (lead-time ${_effectiveLeadHours}h)'),
            _datePickerField(),
            const SizedBox(height: 12),
            _label(_isSwahili
                ? 'Maelezo ya ziada (hiari)'
                : 'Additional notes (optional)'),
            _textField(
              controller: _notesController,
              hint: _isSwahili
                  ? 'Mfano: Bila karanga, fungashia kama zawadi'
                  : 'e.g. No nuts, gift-wrap please',
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _totalBreakdown(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kError.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: _kError),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      '${widget.confirmCtaSwahili} — ${_fmtTzs(_total)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kSecondary,
          ),
        ),
      );

  Widget _variantPicker() {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.product.variants.map((v) {
        final selected = _variant?.id == v.id;
        return InkWell(
          onTap: () => setState(() => _variant = v),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              border: Border.all(
                color: selected ? _kPrimary : _kBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${v.labelSwahili} • ${_fmtTzs(v.priceTzs)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _quantityStepper() {
    final maxQty = 10;
    final minQty = widget.product.minQuantity > 0 ? widget.product.minQuantity : 1;
    return Container(
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove_rounded, color: _kPrimary),
            onPressed: _quantity <= minQty
                ? null
                : () => setState(() => _quantity--),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _kPrimary),
            onPressed: _quantity >= maxQty
                ? null
                : () => setState(() => _quantity++),
          ),
        ],
      ),
    );
  }

  Widget _modePicker(List<String> modes) {
    final sw = _isSwahili;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: modes.map((m) {
        final selected = _mode == m;
        final label = switch (m) {
          'pickup' => sw ? 'Nichukue' : 'Pickup',
          'delivery' => sw ? 'Niletewe' : 'Delivery',
          'digital' => sw ? 'Kidijitali' : 'Digital',
          _ => m,
        };
        return InkWell(
          onTap: () => setState(() => _mode = m),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : _kCardBg,
              border: Border.all(
                color: selected ? _kPrimary : _kBorder,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : _kPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13, color: _kPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: _kSecondary),
        filled: true,
        fillColor: _kCardBg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: _kPrimary),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _datePickerField() {
    final d = _requestedFor;
    final text = d == null
        ? (_isSwahili ? 'Chagua tarehe na muda' : 'Pick date and time')
        : '${d.day}/${d.month}/${d.year} • ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: _pickRequestedFor,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: _kCardBg,
          border: Border.all(color: _kBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_rounded, size: 16, color: _kSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: d == null ? _kSecondary : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalBreakdown() {
    final sw = _isSwahili;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kCardBg,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _row(sw ? 'Kiasi cha bidhaa' : 'Items subtotal',
              _fmtTzs(_unitPrice * _quantity)),
          if (_deliveryFee > 0) ...[
            const SizedBox(height: 4),
            _row(sw ? 'Gharama ya kufikishwa' : 'Delivery fee',
                _fmtTzs(_deliveryFee)),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1, color: _kBorder),
          ),
          _row(sw ? 'Jumla' : 'Total', _fmtTzs(_total), bold: true),
        ],
      ),
    );
  }

  Widget _row(String left, String right, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: TextStyle(
              fontSize: 12,
              color: bold ? _kPrimary : _kSecondary,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          right,
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            color: bold ? _kAccent : _kPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
