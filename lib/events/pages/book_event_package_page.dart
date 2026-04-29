import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../../tajirika/models/tajirika_models.dart';
import '../../tajirika/widgets/slot_picker.dart';
import '../models/event_booking.dart';
import '../services/event_booking_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Customer-side date-locked deposit-required event package booking (spec §10.3).
/// `book_safari_page.dart` extends this layout with itinerary + travelers.
class BookEventPackagePage extends StatefulWidget {
  final int customerUserId;
  /// Optional preset partner_product (when launched from a package detail page).
  final PartnerProduct? package;
  /// Required when no [package] is preset (e.g. bypass via direct deeplink).
  final int? partnerUserId;
  final int? partnerId;
  final String? partnerName;
  final String? skillCategory;
  final EventKind initialKind;

  const BookEventPackagePage({
    super.key,
    required this.customerUserId,
    this.package,
    this.partnerUserId,
    this.partnerId,
    this.partnerName,
    this.skillCategory,
    this.initialKind = EventKind.wedding,
  });

  @override
  State<BookEventPackagePage> createState() => BookEventPackagePageState<BookEventPackagePage>();
}

class BookEventPackagePageState<T extends BookEventPackagePage> extends State<T> {
  int _step = 0;

  late EventKind _kind;
  final _titleCtrl = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  final _addressCtrl = TextEditingController();
  int _partySize = 1;
  late int _basePrice;
  final List<_AddOnDraft> _addOns = [];
  int _depositPct = 50;
  /// Spec line 1042 — DJ/MC song requests collected on the booking flow.
  final List<_SongRequestDraft> _songRequests = [];

  bool _submitting = false;
  String? _submitError;

  bool get isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  /// Subclass override hook — return true once safari-specific
  /// (itinerary + travelers) intake has been collected.
  bool get isSafariReady => true;

  /// Subclass override hook — provide itinerary days at submit.
  List<ItineraryDay>? get safariItinerary => null;

  /// Subclass override hook — provide travelers at submit.
  List<Traveler>? get safariTravelers => null;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _basePrice = widget.package?.basePriceTzs ?? 0;
    if (widget.package != null) {
      _titleCtrl.text = widget.package!.title;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    for (final a in _addOns) {
      a.dispose();
    }
    for (final s in _songRequests) {
      s.dispose();
    }
    super.dispose();
  }

  bool get _isDjOrMcEvent {
    final s = (widget.package?.skillCategory?.name
            ?? widget.package?.skillCategoryRaw
            ?? widget.skillCategory ?? '')
        .toLowerCase();
    return s == 'djing' || s == 'dj' || s == 'mc';
  }

  int get _addOnSum => _addOns.fold<int>(0, (s, a) {
        final qty = int.tryParse(a.qtyCtrl.text.trim()) ?? 0;
        final price = int.tryParse(a.priceCtrl.text.replaceAll(',', '').trim()) ?? 0;
        return s + qty * price;
      });

  int get _total => _basePrice + _addOnSum;
  int get _deposit => (_total * _depositPct / 100).round();
  int get _balance => _total - _deposit;

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 0),
    );
    if (!mounted || time == null) return;
    setState(() => _startsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _pickEnd() async {
    final base = _startsAt ?? DateTime.now().add(const Duration(days: 7));
    final date = await showDatePicker(
      context: context,
      initialDate: base.add(const Duration(hours: 6)),
      firstDate: base,
      lastDate: base.add(const Duration(days: 30)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 22, minute: 0),
    );
    if (!mounted || time == null) return;
    setState(() => _endsAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final partnerUid = widget.package?.partnerUserId ?? widget.partnerUserId;
    if (partnerUid == null) {
      _toast(isSwahili ? 'Mshirika hayupo' : 'No partner selected');
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      _toast(isSwahili ? 'Andika kichwa cha hafla' : 'Enter event title');
      return;
    }
    if (_startsAt == null) {
      _toast(isSwahili ? 'Chagua tarehe' : 'Pick a date');
      return;
    }
    if (_basePrice <= 0) {
      _toast(isSwahili ? 'Bei haiwezi kuwa sufuri' : 'Base price required');
      return;
    }
    if (!isSafariReady) return; // subclass guard
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final addOnsList = <EventAddOn>[];
    for (final a in _addOns) {
      final label = a.labelCtrl.text.trim();
      final qty = int.tryParse(a.qtyCtrl.text.trim());
      final price = int.tryParse(a.priceCtrl.text.replaceAll(',', '').trim());
      if (label.isEmpty || qty == null || qty <= 0 || price == null || price < 0) continue;
      addOnsList.add(EventAddOn(label: label, qty: qty, priceTzs: price));
    }
    final res = await EventBookingService.create(
      customerUserId: widget.customerUserId,
      partnerUserId: partnerUid,
      partnerId: widget.package?.partnerId ?? widget.partnerId,
      partnerProductId: widget.package?.id,
      skillCategory: widget.package?.skillCategory?.name
          ?? widget.package?.skillCategoryRaw
          ?? widget.skillCategory,
      eventKind: _kind,
      eventTitle: _titleCtrl.text.trim(),
      eventStartsAt: _startsAt!,
      eventEndsAt: _endsAt,
      eventAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      partySize: _partySize,
      basePriceTzs: _basePrice,
      addOns: addOnsList,
      depositPct: _depositPct,
      itinerary: safariItinerary,
      travelers: safariTravelers,
      songRequests: _songRequests
          .where((s) => s.titleCtrl.text.trim().isNotEmpty)
          .map((s) => <String, dynamic>{
                'title': s.titleCtrl.text.trim(),
                if (s.artistCtrl.text.trim().isNotEmpty) 'artist': s.artistCtrl.text.trim(),
                if (s.noteCtrl.text.trim().isNotEmpty) 'note': s.noteCtrl.text.trim(),
              })
          .toList(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.booking != null) {
      _toast(isSwahili
          ? 'Tarehe imewekwa kwa ${widget.package?.partnerName ?? widget.partnerName ?? "mshirika"}. Subiri kuhakikisha.'
          : 'Date placed with ${widget.package?.partnerName ?? widget.partnerName ?? "the partner"}. Awaiting confirmation.');
      Navigator.of(context).pop(res.booking);
    } else {
      setState(() => _submitError = res.message ?? 'Failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepCount = _stepCount();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSwahili ? 'Hifadhi Tarehe' : 'Lock the Date',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Stepper(
        currentStep: _step,
        type: StepperType.vertical,
        controlsBuilder: (ctx, details) {
          final isLast = _step >= stepCount - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (_step > 0)
                  TextButton(
                    onPressed: _submitting ? null : details.onStepCancel,
                    child: Text(isSwahili ? 'Rudi' : 'Back'),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : (isLast ? _submit : details.onStepContinue),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(isLast
                      ? (isSwahili ? 'Hifadhi Tarehe' : 'Lock the Date')
                      : (isSwahili ? 'Endelea' : 'Continue')),
                ),
              ],
            ),
          );
        },
        onStepContinue: () {
          if (_step < stepCount - 1) setState(() => _step++);
        },
        onStepCancel: () {
          if (_step > 0) setState(() => _step--);
        },
        steps: _steps(),
      ),
    );
  }

  int _stepCount() => 5 + extraSteps().length + (_isDjOrMcEvent ? 1 : 0);

  List<Step> _steps() {
    return [
      _stepBasics(),
      _stepDate(),
      _stepLocationParty(),
      _stepAddOnsPrice(),
      ...extraSteps(),
      if (_isDjOrMcEvent) _stepSongRequests(),
      _stepReview(),
    ];
  }

  /// Subclass override hook — extra steps inserted before review.
  List<Step> extraSteps() => const [];

  Step _stepSongRequests() {
    return Step(
      title: Text(isSwahili ? 'Nyimbo (DJ/MC)' : 'Song requests'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSwahili
                ? 'Andika nyimbo unazotaka zichezwe (hadi 200). Hiari.'
                : 'List songs you want played (up to 200). Optional.',
            style: const TextStyle(fontSize: 11, color: _kMuted),
          ),
          const SizedBox(height: 6),
          ..._songRequests.asMap().entries.map((e) {
            final i = e.key;
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: s.titleCtrl,
                      decoration: InputDecoration(
                        labelText: isSwahili ? 'Wimbo *' : 'Song *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: s.artistCtrl,
                      decoration: InputDecoration(
                        labelText: isSwahili ? 'Msanii' : 'Artist',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() {
                      s.dispose();
                      _songRequests.removeAt(i);
                    }),
                  ),
                ],
              ),
            );
          }),
          if (_songRequests.length < 200)
            OutlinedButton.icon(
              onPressed: () => setState(() => _songRequests.add(_SongRequestDraft())),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: Text(isSwahili ? 'Ongeza wimbo' : 'Add song'),
            ),
        ],
      ),
    );
  }

  Step _stepBasics() {
    return Step(
      title: Text(isSwahili ? 'Aina + jina la hafla' : 'Kind + title'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: EventKind.values.map((k) {
              final selected = _kind == k;
              return ChoiceChip(
                avatar: Icon(k.icon, size: 14, color: selected ? Colors.white : _kPrimary),
                label: Text(isSwahili ? k.labelSwahili : k.label),
                selected: selected,
                onSelected: (_) => setState(() => _kind = k),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            maxLength: 255,
            decoration: _input(isSwahili
                ? 'Mfano: Asha & John harusi'
                : 'e.g. Asha & John wedding'),
          ),
        ],
      ),
    );
  }

  Step _stepDate() {
    return Step(
      title: Text(isSwahili ? 'Tarehe + muda' : 'Date + time'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((widget.package?.partnerUserId ?? widget.partnerUserId) != null) ...[
            SlotPicker(
              partnerUserId:
                  (widget.package?.partnerUserId ?? widget.partnerUserId)!,
              skillCategory: widget.package?.skillCategory?.name
                  ?? widget.package?.skillCategoryRaw
                  ?? widget.skillCategory,
              selected: _startsAt,
              onSelected: (dt) => setState(() => _startsAt = dt),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStart,
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(_startsAt == null
                      ? (isSwahili ? 'Anza' : 'Start')
                      : DateFormat('EEE d MMM • HH:mm').format(_startsAt!)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEnd,
                  icon: const Icon(Icons.event_available_rounded, size: 16),
                  label: Text(_endsAt == null
                      ? (isSwahili ? 'Maliza (hiari)' : 'End (optional)')
                      : DateFormat('EEE d MMM • HH:mm').format(_endsAt!)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _stepLocationParty() {
    return Step(
      title: Text(isSwahili ? 'Mahali + watu' : 'Location + party size'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _addressCtrl,
            decoration: _input(isSwahili
                ? 'Anwani au sehemu ya hafla'
                : 'Address or venue'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(isSwahili ? 'Idadi ya watu' : 'Party size',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              const Spacer(),
              IconButton(
                onPressed: _partySize > 1 ? () => setState(() => _partySize--) : null,
                icon: const Icon(Icons.remove_circle_outline_rounded),
              ),
              Text('$_partySize',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
              IconButton(
                onPressed: () => setState(() => _partySize++),
                icon: const Icon(Icons.add_circle_outline_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Step _stepAddOnsPrice() {
    return Step(
      title: Text(isSwahili ? 'Bei + ziada' : 'Price + add-ons'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.package == null) ...[
            Text(isSwahili ? 'Bei ya msingi (TZS)' : 'Base price (TZS)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
            const SizedBox(height: 6),
            TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _input('e.g. 800000'),
              onChanged: (v) => setState(() {
                _basePrice = int.tryParse(v.trim()) ?? 0;
              }),
            ),
          ] else
            _kv(isSwahili ? 'Pakeji' : 'Package',
                '${widget.package!.title} — TZS ${_fmt(widget.package!.basePriceTzs)}'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(isSwahili ? 'Ziada (hiari)' : 'Add-ons (optional)',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _addOns.add(_AddOnDraft())),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(isSwahili ? 'Ongeza' : 'Add'),
                style: TextButton.styleFrom(foregroundColor: _kPrimary),
              ),
            ],
          ),
          ..._addOns.asMap().entries.map((e) => _addOnRow(e.key, e.value)),
          const SizedBox(height: 12),
          Text(isSwahili ? 'Amana (%)' : 'Deposit (%)',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
          Slider(
            value: _depositPct.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$_depositPct%',
            onChanged: (v) => setState(() => _depositPct = v.round()),
            activeColor: _kPrimary,
          ),
          const SizedBox(height: 8),
          _depositCard(),
        ],
      ),
    );
  }

  Widget _addOnRow(int index, _AddOnDraft a) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: a.labelCtrl,
                  decoration: _input(isSwahili ? 'Kichwa' : 'Label'),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    a.dispose();
                    _addOns.removeAt(index);
                  });
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: a.qtyCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(isSwahili ? 'Idadi' : 'Qty'),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: a.priceCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _input(isSwahili ? 'Bei kwa moja (TZS)' : 'Unit price (TZS)'),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _depositCard() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _kPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _moneyRow(isSwahili ? 'Jumla' : 'Total', _total),
          _moneyRow(isSwahili ? 'Amana ($_depositPct%)' : 'Deposit ($_depositPct%)', _deposit, bold: true),
          _moneyRow(isSwahili ? 'Salio (kabla ya hafla)' : 'Balance (pre-event)', _balance),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, int amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary)),
          ),
          Text(
            'TZS ${_fmt(amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: _kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Step _stepReview() {
    return Step(
      title: Text(isSwahili ? 'Hakiki' : 'Review'),
      isActive: _step >= 0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _kv(isSwahili ? 'Aina' : 'Kind', isSwahili ? _kind.labelSwahili : _kind.label),
          _kv(isSwahili ? 'Kichwa' : 'Title', _titleCtrl.text),
          _kv(isSwahili ? 'Tarehe' : 'When',
              _startsAt == null ? '—' : DateFormat('EEE d MMM • HH:mm').format(_startsAt!)),
          if (_addressCtrl.text.isNotEmpty)
            _kv(isSwahili ? 'Mahali' : 'Where', _addressCtrl.text),
          _kv(isSwahili ? 'Watu' : 'Party size', '$_partySize'),
          _kv(isSwahili ? 'Jumla' : 'Total', 'TZS ${_fmt(_total)}'),
          _kv(isSwahili ? 'Amana' : 'Deposit', 'TZS ${_fmt(_deposit)}'),
          if (_submitError != null) ...[
            const SizedBox(height: 8),
            Text(_submitError!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 12, color: _kMuted))),
          Expanded(
            child: Text(v,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _kBorder),
        ),
      );

  String _fmt(int v) => NumberFormat('#,##0', 'en_US').format(v);
}

class _AddOnDraft {
  final TextEditingController labelCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController(text: '1');
  final TextEditingController priceCtrl = TextEditingController();
  void dispose() {
    labelCtrl.dispose();
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

class _SongRequestDraft {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController artistCtrl = TextEditingController();
  final TextEditingController noteCtrl = TextEditingController();
  void dispose() {
    titleCtrl.dispose();
    artistCtrl.dispose();
    noteCtrl.dispose();
  }
}
