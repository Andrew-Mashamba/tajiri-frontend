import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/partner_canned_message.dart';
import '../services/partner_canned_message_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 308 — voice-note + canned-message library for partner replies.
/// Tap to insert pre-recorded greeting / "On my way" / "Send more photos"
/// messages directly into the chat compose field.
class CannedMessagePicker extends StatefulWidget {
  final int partnerUserId;
  /// Called when the partner picks a canned message body to insert.
  final void Function(String body) onPick;
  const CannedMessagePicker({
    super.key,
    required this.partnerUserId,
    required this.onPick,
  });

  /// Convenience: launch as a bottom sheet that returns the picked body.
  static Future<String?> showAsSheet({
    required BuildContext context,
    required int partnerUserId,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(12),
        child: CannedMessagePicker(
          partnerUserId: partnerUserId,
          onPick: (body) => Navigator.pop(context, body),
        ),
      ),
    );
  }

  @override
  State<CannedMessagePicker> createState() => _CannedMessagePickerState();
}

class _CannedMessagePickerState extends State<CannedMessagePicker> {
  bool _loading = true;
  List<PartnerCannedMessage> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res =
        await PartnerCannedMessageService.listForPartner(widget.partnerUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  Future<void> _addNew() async {
    final labelCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isSwahili ? 'Ujumbe Mpya' : 'New canned message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelCtrl,
              decoration: InputDecoration(
                labelText: _isSwahili ? 'Lebo' : 'Label',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyCtrl,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _isSwahili ? 'Maandishi' : 'Message body',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_isSwahili ? 'Funga' : 'Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_isSwahili ? 'Hifadhi' : 'Save'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) {
      labelCtrl.dispose();
      bodyCtrl.dispose();
      return;
    }
    final created = await PartnerCannedMessageService.create(
      partnerUserId: widget.partnerUserId,
      label: labelCtrl.text.trim(),
      body: bodyCtrl.text.trim(),
    );
    labelCtrl.dispose();
    bodyCtrl.dispose();
    if (created != null) _load();
  }

  Future<void> _remove(PartnerCannedMessage m) async {
    final ok = await PartnerCannedMessageService.delete(m.id);
    if (ok) _load();
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 18, color: _kPrimary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isSw ? 'Majibu ya haraka' : 'Canned replies',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _kPrimary,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_rounded, color: _kPrimary),
              tooltip: isSw ? 'Ongeza' : 'Add',
              onPressed: _addNew,
            ),
          ],
        ),
        const Divider(height: 1, color: _kBorder),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              isSw
                  ? 'Hakuna jibu la haraka. Bonyeza + ili kuongeza.'
                  : 'No canned replies. Tap + to add one.',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (_, i) {
                final m = _items[i];
                return ListTile(
                  dense: true,
                  title: Text(
                    m.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                  subtitle: Text(
                    m.body,
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 16, color: Color(0xFFB71C1C)),
                    onPressed: () => _remove(m),
                  ),
                  onTap: () => widget.onPick(m.body),
                );
              },
            ),
          ),
      ],
    );
  }
}
