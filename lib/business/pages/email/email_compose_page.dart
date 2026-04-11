// lib/business/pages/email/email_compose_page.dart
// Compose / Reply / Forward email screen with chip-based recipients,
// CC/BCC toggle, attachments, and auto-save draft on back.

import 'package:flutter/material.dart';
import 'email_mock_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class EmailComposePage extends StatefulWidget {
  final String fromAddress;
  final String fromName;

  /// Set for reply
  final MockEmail? replyTo;
  final bool replyAll;

  /// Set for forward
  final MockEmail? forwardEmail;

  /// Optional pre-fill fields for cross-module integration
  final String? initialTo;
  final String? initialSubject;
  final String? initialBody;

  const EmailComposePage({
    super.key,
    required this.fromAddress,
    required this.fromName,
    this.replyTo,
    this.replyAll = false,
    this.forwardEmail,
    this.initialTo,
    this.initialSubject,
    this.initialBody,
  });

  @override
  State<EmailComposePage> createState() => _EmailComposePageState();
}

class _EmailComposePageState extends State<EmailComposePage> {
  final _toCtrl = TextEditingController();
  final _ccCtrl = TextEditingController();
  final _bccCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  final _toFocus = FocusNode();
  final _ccFocus = FocusNode();
  final _bccFocus = FocusNode();
  final _subjectFocus = FocusNode();
  final _bodyFocus = FocusNode();

  List<String> _toChips = [];
  List<String> _ccChips = [];
  List<String> _bccChips = [];
  bool _showCcBcc = false;
  bool _isSending = false;

  // Bilingual
  bool get _isSwahili => false;
  String get _sendLabel => _isSwahili ? 'Tuma' : 'Send';
  String get _composeTitle =>
      _isSwahili ? 'Barua Mpya' : 'New Email';
  String get _replyTitle => _isSwahili ? 'Jibu' : 'Reply';
  String get _forwardTitle =>
      _isSwahili ? 'Tuma Mbele' : 'Forward';
  String get _fromLabel => _isSwahili ? 'Kutoka' : 'From';
  String get _toLabel => _isSwahili ? 'Kwa' : 'To';
  String get _subjectLabel =>
      _isSwahili ? 'Mada' : 'Subject';
  String get _ccLabel => 'CC';
  String get _bodyHint => _isSwahili
      ? 'Andika ujumbe wako...'
      : 'Write your message...';
  String get _draftSaved =>
      _isSwahili ? 'Rasimu imehifadhiwa' : 'Draft saved';
  String get _sentSuccess =>
      _isSwahili ? 'Imetumwa' : 'Email sent';

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    if (widget.replyTo != null) {
      final re = widget.replyTo!;
      _toChips = [re.from];
      if (widget.replyAll && re.cc != null) {
        _ccChips = re.cc!
            .where((e) => e != widget.fromAddress)
            .toList();
        if (_ccChips.isNotEmpty) _showCcBcc = true;
      }
      _subjectCtrl.text =
          re.subject.startsWith('Re:') ? re.subject : 'Re: ${re.subject}';
      _bodyCtrl.text =
          '\n\n---\nOn ${_formatDate(re.date)}, ${re.fromName} <${re.from}> wrote:\n${re.body}';
    } else if (widget.forwardEmail != null) {
      final fw = widget.forwardEmail!;
      _subjectCtrl.text =
          fw.subject.startsWith('Fwd:') ? fw.subject : 'Fwd: ${fw.subject}';
      _bodyCtrl.text =
          '\n\n--- Forwarded message ---\nFrom: ${fw.fromName} <${fw.from}>\nDate: ${_formatDate(fw.date)}\nSubject: ${fw.subject}\n\n${fw.body}';
    } else {
      // Cross-module pre-fill (e.g. from invoices, quotes)
      if (widget.initialTo != null && widget.initialTo!.isNotEmpty) {
        _toChips = [widget.initialTo!];
      }
      if (widget.initialSubject != null) {
        _subjectCtrl.text = widget.initialSubject!;
      }
      if (widget.initialBody != null) {
        _bodyCtrl.text = widget.initialBody!;
      }
    }
  }

  @override
  void dispose() {
    _toCtrl.dispose();
    _ccCtrl.dispose();
    _bccCtrl.dispose();
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    _toFocus.dispose();
    _ccFocus.dispose();
    _bccFocus.dispose();
    _subjectFocus.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.replyTo != null) return _replyTitle;
    if (widget.forwardEmail != null) return _forwardTitle;
    return _composeTitle;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && _hasDraftContent()) {
          // Auto-save draft concept
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_draftSaved),
            backgroundColor: _kPrimary,
            duration: const Duration(seconds: 2),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: _kBackground,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(child: _buildForm()),
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kCardBg,
      foregroundColor: _kPrimary,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(_title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _kPrimary)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilledButton(
            onPressed:
                _isSending || _toChips.isEmpty ? null : _send,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              disabledBackgroundColor: _kPrimary.withValues(alpha: 0.3),
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(0, 36),
            ),
            child: _isSending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_sendLabel,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // From field
          _FieldRow(
            label: _fromLabel,
            child: Text(widget.fromAddress,
                style: const TextStyle(
                    fontSize: 14, color: _kSecondary)),
          ),
          const Divider(height: 0.5, color: Color(0xFFF0F0F0)),

          // To field
          _ChipField(
            label: _toLabel,
            chips: _toChips,
            controller: _toCtrl,
            focusNode: _toFocus,
            onAdd: (v) => setState(() => _toChips.add(v)),
            onRemove: (v) =>
                setState(() => _toChips.remove(v)),
            trailing: !_showCcBcc
                ? GestureDetector(
                    onTap: () =>
                        setState(() => _showCcBcc = true),
                    child: const Text('CC/BCC',
                        style: TextStyle(
                            fontSize: 12,
                            color: _kSecondary,
                            fontWeight: FontWeight.w500)),
                  )
                : null,
          ),
          const Divider(height: 0.5, color: Color(0xFFF0F0F0)),

          // CC / BCC
          if (_showCcBcc) ...[
            _ChipField(
              label: _ccLabel,
              chips: _ccChips,
              controller: _ccCtrl,
              focusNode: _ccFocus,
              onAdd: (v) => setState(() => _ccChips.add(v)),
              onRemove: (v) =>
                  setState(() => _ccChips.remove(v)),
            ),
            const Divider(height: 0.5, color: Color(0xFFF0F0F0)),
            _ChipField(
              label: 'BCC',
              chips: _bccChips,
              controller: _bccCtrl,
              focusNode: _bccFocus,
              onAdd: (v) =>
                  setState(() => _bccChips.add(v)),
              onRemove: (v) =>
                  setState(() => _bccChips.remove(v)),
            ),
            const Divider(height: 0.5, color: Color(0xFFF0F0F0)),
          ],

          // Subject
          _FieldRow(
            label: _subjectLabel,
            child: TextField(
              controller: _subjectCtrl,
              focusNode: _subjectFocus,
              style: const TextStyle(
                  fontSize: 14, color: _kPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Divider(height: 0.5, color: Color(0xFFF0F0F0)),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _bodyCtrl,
              focusNode: _bodyFocus,
              maxLines: null,
              minLines: 12,
              style: const TextStyle(
                  fontSize: 14, color: _kPrimary, height: 1.5),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: _bodyHint,
                hintStyle: const TextStyle(
                    fontSize: 14, color: _kSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      decoration: const BoxDecoration(
        color: _kCardBg,
        border: Border(
            top: BorderSide(color: Color(0xFFE8E8E8), width: 0.5)),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 4,
        bottom: MediaQuery.of(context).padding.bottom + 4,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, size: 22),
            color: _kSecondary,
            onPressed: () {
              // Attach file (mock)
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(_isSwahili
                      ? 'Chagua faili...'
                      : 'Pick a file...'),
                  backgroundColor: _kPrimary,
                  duration: const Duration(seconds: 1),
                ));
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.format_bold_rounded, size: 22),
            color: _kSecondary,
            tooltip: 'Bold',
            onPressed: () => _wrapSelection('**', '**'),
          ),
          IconButton(
            icon:
                const Icon(Icons.format_italic_rounded, size: 22),
            color: _kSecondary,
            tooltip: 'Italic',
            onPressed: () => _wrapSelection('_', '_'),
          ),
          IconButton(
            icon: const Icon(Icons.link_rounded, size: 22),
            color: _kSecondary,
            tooltip: 'Link',
            onPressed: () => _wrapSelection('[', '](url)'),
          ),
        ],
      ),
    );
  }

  void _wrapSelection(String prefix, String suffix) {
    final text = _bodyCtrl.text;
    final selection = _bodyCtrl.selection;
    if (!selection.isValid || selection.baseOffset < 0) {
      // No selection — insert at cursor or end
      final pos = selection.isValid && selection.baseOffset >= 0
          ? selection.baseOffset
          : text.length;
      final newText = text.substring(0, pos) + prefix + suffix + text.substring(pos);
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: pos + prefix.length),
      );
    } else {
      final selected = text.substring(selection.start, selection.end);
      final newText = text.substring(0, selection.start) +
          prefix +
          selected +
          suffix +
          text.substring(selection.end);
      _bodyCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
            offset: selection.start + prefix.length + selected.length + suffix.length),
      );
    }
    _bodyFocus.requestFocus();
  }

  bool _hasDraftContent() {
    return _toChips.isNotEmpty ||
        _subjectCtrl.text.trim().isNotEmpty ||
        _bodyCtrl.text.trim().isNotEmpty;
  }

  Future<void> _send() async {
    if (_toChips.isEmpty) return;
    setState(() => _isSending = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    EmailMockService.sendEmail(
      from: widget.fromAddress,
      fromName: widget.fromName,
      to: _toChips,
      cc: _ccChips.isNotEmpty ? _ccChips : null,
      subject: _subjectCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_sentSuccess),
        backgroundColor: _kPrimary,
        duration: const Duration(seconds: 2),
      ));
      Navigator.of(context).pop();
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Field row (label + child)
// ---------------------------------------------------------------------------

class _FieldRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _FieldRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCardBg,
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: _kSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip input field for recipients
// ---------------------------------------------------------------------------

class _ChipField extends StatelessWidget {
  final String label;
  final List<String> chips;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final Widget? trailing;

  const _ChipField({
    required this.label,
    required this.chips,
    required this.controller,
    required this.focusNode,
    required this.onAdd,
    required this.onRemove,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kCardBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 56,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    color: _kSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...chips.map((c) => InputChip(
                      label: Text(c,
                          style: const TextStyle(
                              fontSize: 12, color: _kPrimary)),
                      deleteIconColor: _kSecondary,
                      onDeleted: () => onRemove(c),
                      backgroundColor: _kBackground,
                      side: BorderSide.none,
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                    )),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                        fontSize: 13, color: _kPrimary),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (val) {
                      final trimmed = val.trim();
                      if (trimmed.isNotEmpty && trimmed.contains('@')) {
                        onAdd(trimmed);
                        controller.clear();
                        focusNode.requestFocus();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
