import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/peer_endorsement.dart';
import '../services/peer_endorsement_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);
const Color _kAccent = Color(0xFF1B5E20);

/// Spec line 1108 — Avvo-style peer endorsements section. Renders on
/// partner_profile_page. Other partners (peers) can endorse this person's
/// expertise per skill. Hides quietly when there are none and the viewer
/// is the partner themselves (own profile).
class PeerEndorsementsSection extends StatefulWidget {
  final int endorseeUserId;
  final int? viewerUserId;
  final bool isOwnProfile;
  final List<String> skillCategories;
  const PeerEndorsementsSection({
    super.key,
    required this.endorseeUserId,
    required this.viewerUserId,
    required this.isOwnProfile,
    required this.skillCategories,
  });

  @override
  State<PeerEndorsementsSection> createState() => _PeerEndorsementsSectionState();
}

class _PeerEndorsementsSectionState extends State<PeerEndorsementsSection> {
  bool _loading = true;
  List<PeerEndorsement> _items = const [];

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await PeerEndorsementService.listForUser(widget.endorseeUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = res;
    });
  }

  Future<void> _endorse() async {
    final viewer = widget.viewerUserId;
    if (viewer == null) return;
    final categories = widget.skillCategories;
    if (categories.isEmpty) return;

    String selectedSkill = categories.first;
    final commentCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: Text(_isSwahili ? 'Mthibitishe' : 'Endorse'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButton<String>(
                  value: selectedSkill,
                  isExpanded: true,
                  items: categories
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setStateDialog(() => selectedSkill = v);
                  },
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentCtrl,
                  maxLength: 500,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: _isSwahili ? 'Maoni (hiari)' : 'Comment (optional)',
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                ),
                child: Text(_isSwahili ? 'Tuma' : 'Submit'),
              ),
            ],
          ),
        );
      },
    );
    commentCtrl.dispose();
    if (ok != true || !mounted) return;
    final success = await PeerEndorsementService.create(
      endorseeUserId: widget.endorseeUserId,
      endorserUserId: viewer,
      skillCategory: selectedSkill,
      comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
    );
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(
        success
            ? (_isSwahili ? 'Imethibitishwa' : 'Endorsement added')
            : (_isSwahili ? 'Imeshindikana' : 'Failed'),
      ),
    ));
    if (success) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    final canEndorse = !widget.isOwnProfile &&
        widget.viewerUserId != null &&
        widget.skillCategories.isNotEmpty;
    if (_items.isEmpty && !canEndorse) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                size: 14, color: _kPrimary),
            const SizedBox(width: 6),
            Text(
              _isSwahili
                  ? 'Mapendekezo ya wenzake (${_items.length})'
                  : 'Peer endorsements (${_items.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
              ),
            ),
            const Spacer(),
            if (canEndorse)
              TextButton.icon(
                onPressed: _endorse,
                icon: const Icon(Icons.add_rounded, size: 14, color: _kAccent),
                label: Text(
                  _isSwahili ? 'Mthibitishe' : 'Endorse',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _kAccent,
                  ),
                ),
                style: TextButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_items.isEmpty)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              _isSwahili
                  ? 'Bado hakuna mapendekezo.'
                  : 'No endorsements yet.',
              style: const TextStyle(fontSize: 11, color: _kSecondary),
            ),
          )
        else
          ..._items.take(5).map(_endorsementRow),
      ],
    );
  }

  Widget _endorsementRow(PeerEndorsement e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_rounded, size: 13, color: _kAccent),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${e.endorserName ?? 'Mshirika'} • ${e.skillCategory}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (e.comment != null && e.comment!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    e.comment!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _kPrimary,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
