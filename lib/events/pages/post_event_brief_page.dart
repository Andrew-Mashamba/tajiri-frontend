import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/event_quote_request_service.dart';
import 'event_brief_detail_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kFieldBg = Colors.white;
const Color _kBorder = Color(0xFFE0E0E0);

/// Customer-side "post a brief" page for the event quote-bidding (RFQ) flow.
///
/// The customer describes the event; the request goes live; matched partners
/// (by skill_category) bid within the auction window. The customer reviews
/// bids on [EventBriefDetailPage] and awards one. Spec line 1018.
class PostEventBriefPage extends StatefulWidget {
  final int customerUserId;
  final String? presetSkillCategory;

  const PostEventBriefPage({
    super.key,
    required this.customerUserId,
    this.presetSkillCategory,
  });

  @override
  State<PostEventBriefPage> createState() => _PostEventBriefPageState();
}

/// Skills that meaningfully participate in the event-quote flow. Limited to
/// the spec's "events / travel / MC / DJ / safari" cluster — partners outside
/// these skills don't see open briefs. Order matters: most common first.
const List<_SkillOption> _skillOptions = [
  _SkillOption(value: 'djing', sw: 'DJ', en: 'DJ'),
  _SkillOption(value: 'mc', sw: 'Mtangazaji (MC)', en: 'MC / Host'),
  _SkillOption(value: 'photography', sw: 'Mpiga picha', en: 'Photographer'),
  _SkillOption(value: 'videography', sw: 'Mpiga video', en: 'Videographer'),
  _SkillOption(value: 'eventPlanning', sw: 'Mpangaji wa hafla', en: 'Event planner'),
  _SkillOption(value: 'catering', sw: 'Upishi wa hafla', en: 'Catering'),
  _SkillOption(value: 'baking', sw: 'Keki na keki za harusi', en: 'Cakes'),
  _SkillOption(value: 'makeup', sw: 'Make-up', en: 'Make-up artist'),
  _SkillOption(value: 'tourGuide', sw: 'Mwongozaji wa safari', en: 'Tour guide'),
  _SkillOption(value: 'travelAgent', sw: 'Wakala wa safari', en: 'Travel agent'),
  _SkillOption(value: 'safariOperator', sw: 'Opareta wa safari', en: 'Safari operator'),
];

const List<_KindOption> _kindOptions = [
  _KindOption(value: 'wedding', sw: 'Harusi', en: 'Wedding'),
  _KindOption(value: 'birthday', sw: 'Sherehe ya kuzaliwa', en: 'Birthday'),
  _KindOption(value: 'corporate', sw: 'Hafla ya kampuni', en: 'Corporate'),
  _KindOption(value: 'graduation', sw: 'Mahafali', en: 'Graduation'),
  _KindOption(value: 'safari', sw: 'Safari ya kitalii', en: 'Safari'),
  _KindOption(value: 'other', sw: 'Nyingine', en: 'Other'),
];

class _SkillOption {
  final String value, sw, en;
  const _SkillOption({required this.value, required this.sw, required this.en});
}

class _KindOption {
  final String value, sw, en;
  const _KindOption({required this.value, required this.sw, required this.en});
}

class _PostEventBriefPageState extends State<PostEventBriefPage> {
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _budgetMinCtrl = TextEditingController();
  final _budgetMaxCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String? _skill;
  String _kind = 'wedding';
  DateTime? _startsAt;
  DateTime? _endsAt;
  int _partySize = 50;
  int _auctionHours = 24;

  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _skill = widget.presetSkillCategory;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _budgetMinCtrl.dispose();
    _budgetMaxCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? true;

  bool get _isFormValid =>
      _skill != null &&
      _titleCtrl.text.trim().length >= 3 &&
      _startsAt != null &&
      _startsAt!.isAfter(DateTime.now()) &&
      _partySize > 0 &&
      _budgetIsValid;

  bool get _budgetIsValid {
    final min = int.tryParse(_budgetMinCtrl.text.trim());
    final max = int.tryParse(_budgetMaxCtrl.text.trim());
    if (min == null && max == null) return true; // budget is optional
    if (min != null && max != null) return max >= min;
    return true;
  }

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: _isSwahili ? 'Tarehe ya hafla' : 'Event date',
    );
    if (picked == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 16, minute: 0),
      helpText: _isSwahili ? 'Saa ya kuanza' : 'Start time',
    );
    if (time == null || !mounted) return;

    setState(() {
      _startsAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
      // Default ends_at to 4 hours after starts_at
      _endsAt = _startsAt!.add(const Duration(hours: 4));
    });
  }

  Future<void> _submit() async {
    if (!_isFormValid || _submitting) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    final result = await EventQuoteRequestService.create(
      customerUserId: widget.customerUserId,
      skillCategory: _skill!,
      eventKind: _kind,
      eventTitle: _titleCtrl.text.trim(),
      eventStartsAt: _startsAt!,
      eventEndsAt: _endsAt,
      eventAddress: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
      partySize: _partySize,
      budgetMinTzs: int.tryParse(_budgetMinCtrl.text.trim()),
      budgetMaxTzs: int.tryParse(_budgetMaxCtrl.text.trim()),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      auctionHours: _auctionHours,
    );

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _submitting = false;
        _errorMessage = _isSwahili
            ? 'Imeshindikana kutuma. Jaribu tena.'
            : 'Submission failed. Try again.';
      });
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EventBriefDetailPage(
          briefId: result.id,
          customerUserId: widget.customerUserId,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sw = _isSwahili;

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          sw ? 'Andika ombi la hafla' : 'Post a brief',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  _buildIntro(sw),
                  const SizedBox(height: 24),
                  _buildLabel(sw ? 'Aina ya huduma' : 'Skill needed', required: true),
                  const SizedBox(height: 8),
                  _buildSkillPicker(sw),
                  const SizedBox(height: 20),
                  _buildLabel(sw ? 'Aina ya hafla' : 'Event type', required: true),
                  const SizedBox(height: 8),
                  _buildKindPicker(sw),
                  const SizedBox(height: 20),
                  _buildLabel(sw ? 'Jina la hafla' : 'Event title', required: true),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _titleCtrl,
                    hint: sw ? 'Mfano: Harusi ya Asha & Juma' : 'e.g. Asha & John wedding',
                    maxLength: 160,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(sw ? 'Tarehe na saa' : 'Date and time', required: true),
                  const SizedBox(height: 6),
                  _buildDatePicker(sw),
                  const SizedBox(height: 20),
                  _buildLabel(sw ? 'Mahali' : 'Venue', required: false),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _addressCtrl,
                    hint: sw ? 'Mfano: Diamond Jubilee, Dar' : 'e.g. Diamond Jubilee, Dar',
                    maxLength: 240,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(sw ? 'Idadi ya wageni' : 'Number of guests', required: true),
                  const SizedBox(height: 6),
                  _buildPartySizeStepper(sw),
                  const SizedBox(height: 20),
                  _buildLabel(sw ? 'Bajeti (TZS)' : 'Budget (TZS)', required: false),
                  const SizedBox(height: 6),
                  _buildBudgetRange(sw),
                  const SizedBox(height: 20),
                  _buildLabel(
                    sw ? 'Maelezo zaidi (hiari)' : 'Additional details (optional)',
                    required: false,
                  ),
                  const SizedBox(height: 6),
                  _buildTextField(
                    controller: _descCtrl,
                    hint: sw
                        ? 'Mfano: Sherehe ya jadi, mavazi rasmi, muziki wa Bongo Flava'
                        : 'e.g. Traditional theme, formal dress, Bongo Flava music',
                    maxLength: 500,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  _buildAuctionWindow(sw),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFB00020), fontSize: 13),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildSubmitBar(sw),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro(bool sw) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBDEFB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF0D47A1), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              sw
                  ? 'Wahudumu wenye ujuzi watapokea ombi lako wakati wewe ungojea kwa masaa $_auctionHours. Utachagua mmoja mwishoni.'
                  : 'Matched partners will see your brief and submit bids over $_auctionHours hours. Pick one when bids come in.',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF0D47A1), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {required bool required}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary, letterSpacing: 0.3),
        children: required
            ? const [TextSpan(text: ' *', style: TextStyle(color: Color(0xFFE53935)))]
            : null,
      ),
    );
  }

  Widget _buildSkillPicker(bool sw) {
    return Container(
      decoration: _fieldDecoration(),
      child: DropdownButtonFormField<String>(
        initialValue: _skill,
        isExpanded: true,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          border: InputBorder.none,
        ),
        hint: Text(sw ? 'Chagua aina ya huduma' : 'Choose skill'),
        items: _skillOptions
            .map((o) => DropdownMenuItem(
                  value: o.value,
                  child: Text(sw ? o.sw : o.en),
                ))
            .toList(),
        onChanged: (v) => setState(() => _skill = v),
      ),
    );
  }

  Widget _buildKindPicker(bool sw) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _kindOptions.map((o) {
        final selected = _kind == o.value;
        return GestureDetector(
          onTap: () => setState(() => _kind = o.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? _kPrimary : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? _kPrimary : _kBorder),
            ),
            child: Text(
              sw ? o.sw : o.en,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.white : _kPrimary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int? maxLength,
    int maxLines = 1,
  }) {
    return Container(
      decoration: _fieldDecoration(),
      child: TextField(
        controller: controller,
        maxLength: maxLength,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool sw) {
    final fmt = DateFormat('EEE d MMM yyyy, HH:mm', sw ? 'sw' : 'en');
    return GestureDetector(
      onTap: _pickStart,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: _fieldDecoration(),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 18, color: _kSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _startsAt == null
                    ? (sw ? 'Chagua tarehe' : 'Pick a date')
                    : fmt.format(_startsAt!),
                style: TextStyle(
                  fontSize: 14,
                  color: _startsAt == null ? const Color(0xFFBBBBBB) : _kPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: _kSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildPartySizeStepper(bool sw) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: _fieldDecoration(),
      child: Row(
        children: [
          IconButton(
            onPressed: _partySize > 1 ? () => setState(() => _partySize -= 10) : null,
            icon: const Icon(Icons.remove_rounded),
            color: _kPrimary,
          ),
          Expanded(
            child: Text(
              sw ? '$_partySize wageni' : '$_partySize guests',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _kPrimary),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _partySize += 10),
            icon: const Icon(Icons.add_rounded),
            color: _kPrimary,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetRange(bool sw) {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: _fieldDecoration(),
            child: TextField(
              controller: _budgetMinCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'TZS ',
                hintText: sw ? 'Min' : 'Min',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('—', style: TextStyle(color: _kSecondary)),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: _fieldDecoration(),
            child: TextField(
              controller: _budgetMaxCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixText: 'TZS ',
                hintText: sw ? 'Max' : 'Max',
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuctionWindow(bool sw) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kFieldBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 18, color: _kSecondary),
              const SizedBox(width: 8),
              Text(
                sw ? 'Muda wa kupokea ofa' : 'Bid window',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [12, 24, 48, 72].map((h) {
              final selected = _auctionHours == h;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _auctionHours = h),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? _kPrimary : Colors.white,
                      border: Border.all(color: selected ? _kPrimary : _kBorder),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      sw ? '$h saa' : '$h h',
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : _kPrimary,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: _kFieldBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: _kBorder),
    );
  }

  Widget _buildSubmitBar(bool sw) {
    final enabled = _isFormValid && !_submitting;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, -2))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: enabled ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            disabledBackgroundColor: const Color(0xFFCCCCCC),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  sw ? 'Tuma ombi' : 'Post brief',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }
}
