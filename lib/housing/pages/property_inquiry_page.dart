import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/listing_inquiry.dart';
import '../models/property_listing.dart';
import '../services/listing_inquiry_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kMuted = Color(0xFF9E9E9E);
const Color _kBorder = Color(0xFFEEEEEE);

/// Customer-facing inquiry composer per spec §9.3.
/// Three kinds: viewing / offer / question. Conditional fields per kind.
enum InquiryKindOption { viewing, offer, question }

extension on InquiryKindOption {
  InquiryKind get apiKind {
    switch (this) {
      case InquiryKindOption.viewing: return InquiryKind.viewing;
      case InquiryKindOption.offer: return InquiryKind.offer;
      case InquiryKindOption.question: return InquiryKind.question;
    }
  }
}

class PropertyInquiryPage extends StatefulWidget {
  final PropertyListing listing;
  final int customerUserId;
  final InquiryKindOption initialKind;
  final int? parentInquiryId; // for counter-offers

  const PropertyInquiryPage({
    super.key,
    required this.listing,
    required this.customerUserId,
    this.initialKind = InquiryKindOption.viewing,
    this.parentInquiryId,
  });

  @override
  State<PropertyInquiryPage> createState() => _PropertyInquiryPageState();
}

class _PropertyInquiryPageState extends State<PropertyInquiryPage> {
  late InquiryKindOption _kind;
  final _msgCtrl = TextEditingController();
  final _offerCtrl = TextEditingController();
  DateTime? _viewingAt;

  /// Spec line 941 — pre-qualification soft-asked at inquiry create.
  /// Move-in window, financing, working-with-agent.
  String? _prequalMoveIn; // immediate | within_3m | within_6m | flexible
  String? _prequalFinancing; // cash | mortgage_approved | mortgage_pending | unsure
  bool? _prequalAgent;

  bool _submitting = false;
  String? _submitError;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialKind;
    _offerCtrl.text = widget.listing.priceTzs.toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _offerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickViewing() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _viewingAt ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_viewingAt ?? now.add(const Duration(hours: 1))),
    );
    if (!mounted || time == null) return;
    setState(() => _viewingAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _submit() async {
    if (_kind == InquiryKindOption.viewing && _viewingAt == null) {
      _toast(_isSwahili ? 'Chagua tarehe ya kuona' : 'Pick a viewing date');
      return;
    }
    int? offer;
    if (_kind == InquiryKindOption.offer) {
      offer = int.tryParse(_offerCtrl.text.replaceAll(',', '').trim());
      if (offer == null || offer <= 0) {
        _toast(_isSwahili ? 'Andika bei sahihi' : 'Enter a valid offer price');
        return;
      }
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final res = await ListingInquiryService.create(
      listingId: widget.listing.id,
      customerUserId: widget.customerUserId,
      kind: _kind.apiKind,
      message: _msgCtrl.text.trim().isEmpty ? null : _msgCtrl.text.trim(),
      preferredViewingAt: _kind == InquiryKindOption.viewing ? _viewingAt : null,
      offerPriceTzs: offer,
      parentInquiryId: widget.parentInquiryId,
      prequalMoveIn: _prequalMoveIn,
      prequalFinancing: _prequalFinancing,
      prequalWorkingWithAgent: _prequalAgent,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success && res.inquiry != null) {
      _toast(_isSwahili
          ? 'Swali lako limefika kwa ${widget.listing.partnerName ?? "mshirika"}'
          : 'Inquiry sent to ${widget.listing.partnerName ?? "the agent"}');
      Navigator.of(context).pop(res.inquiry);
    } else {
      setState(() => _submitError = res.message ?? 'Failed');
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
          _isSwahili ? 'Tuma Swali' : 'Send Inquiry',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _listingPreview(),
            const SizedBox(height: 16),
            _section(
              title: _isSwahili ? 'Aina ya swali' : 'Inquiry type',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: InquiryKindOption.values.map((k) {
                  final selected = _kind == k;
                  return ChoiceChip(
                    label: Text(_kindLabel(k)),
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
            ),
            if (_kind == InquiryKindOption.viewing) ...[
              const SizedBox(height: 16),
              _section(
                title: _isSwahili ? 'Tarehe ya kuona' : 'Preferred viewing',
                child: OutlinedButton.icon(
                  onPressed: _pickViewing,
                  icon: const Icon(Icons.event_rounded, size: 16),
                  label: Text(_viewingAt == null
                      ? (_isSwahili ? 'Chagua tarehe na muda' : 'Pick date & time')
                      : DateFormat('EEE d MMM • HH:mm').format(_viewingAt!)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kPrimary,
                    side: const BorderSide(color: _kBorder),
                    minimumSize: const Size.fromHeight(44),
                  ),
                ),
              ),
            ],
            if (_kind == InquiryKindOption.offer) ...[
              const SizedBox(height: 16),
              _section(
                title: _isSwahili ? 'Bei unayotoa (TZS)' : 'Your offer (TZS)',
                child: TextField(
                  controller: _offerCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    helperText: _isSwahili
                        ? 'Bei iliyowekwa: TZS ${NumberFormat('#,##0', 'en_US').format(widget.listing.priceTzs)}'
                        : 'Listed price: TZS ${NumberFormat('#,##0', 'en_US').format(widget.listing.priceTzs)}',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _prequalSection(),
            const SizedBox(height: 16),
            _section(
              title: _isSwahili ? 'Ujumbe (hiari)' : 'Message (optional)',
              child: TextField(
                controller: _msgCtrl,
                minLines: 3,
                maxLines: 8,
                maxLength: 2000,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
            ),
            const SizedBox(height: 12),
            if (_submitError != null) ...[
              Text(_submitError!, style: const TextStyle(color: Color(0xFFB71C1C), fontSize: 12)),
              const SizedBox(height: 8),
            ],
            ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_isSwahili ? 'Tuma' : 'Send'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prequalSection() {
    final isSw = _isSwahili;
    final moveOpts = [
      ('immediate', isSw ? 'Sasa hivi' : 'Immediately'),
      ('within_3m', isSw ? 'Miezi 3' : '3 months'),
      ('within_6m', isSw ? 'Miezi 6' : '6 months'),
      ('flexible', isSw ? 'Si haraka' : 'Flexible'),
    ];
    final finOpts = [
      ('cash', isSw ? 'Pesa taslimu' : 'Cash'),
      ('mortgage_approved', isSw ? 'Mkopo umekubalika' : 'Mortgage approved'),
      ('mortgage_pending', isSw ? 'Naomba mkopo' : 'Mortgage pending'),
      ('unsure', isSw ? 'Sijaamua' : 'Unsure'),
    ];
    return _section(
      title: isSw ? 'Maandalizi (hiari)' : 'Quick pre-qualification (optional)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isSw ? 'Utahamia lini?' : 'Move-in?',
              style: const TextStyle(fontSize: 11, color: _kMuted)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: moveOpts.map((o) {
              final selected = _prequalMoveIn == o.$1;
              return ChoiceChip(
                label: Text(o.$2, style: const TextStyle(fontSize: 11)),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _prequalMoveIn = selected ? null : o.$1),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(isSw ? 'Hali ya kifedha?' : 'Financing?',
              style: const TextStyle(fontSize: 11, color: _kMuted)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: finOpts.map((o) {
              final selected = _prequalFinancing == o.$1;
              return ChoiceChip(
                label: Text(o.$2, style: const TextStyle(fontSize: 11)),
                selected: selected,
                onSelected: (_) => setState(
                    () => _prequalFinancing = selected ? null : o.$1),
                selectedColor: _kPrimary,
                labelStyle: TextStyle(
                  color: selected ? Colors.white : _kPrimary,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              isSw
                  ? 'Ninafanya kazi na wakala mwingine'
                  : 'Working with another agent',
              style: const TextStyle(fontSize: 12),
            ),
            value: _prequalAgent ?? false,
            onChanged: (v) => setState(() => _prequalAgent = v),
          ),
        ],
      ),
    );
  }

  Widget _listingPreview() {
    final l = widget.listing;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(l.propertyType.icon, size: 20, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.title,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
                Text(l.locationDisplay.isEmpty ? '—' : l.locationDisplay,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: _kMuted)),
              ],
            ),
          ),
          Text(
            'TZS ${NumberFormat('#,##0', 'en_US').format(l.priceTzs)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
        ],
      ),
    );
  }

  String _kindLabel(InquiryKindOption k) {
    switch (k) {
      case InquiryKindOption.viewing: return _isSwahili ? 'Ona' : 'Viewing';
      case InquiryKindOption.offer: return _isSwahili ? 'Toa Bei' : 'Make Offer';
      case InquiryKindOption.question: return _isSwahili ? 'Uliza Swali' : 'Ask Question';
    }
  }

  Widget _section({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
