// Invite Link management — create, copy, share and revoke invite links for conversations.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/guest_chat_service.dart';

const Color _kBackground = Color(0xFFFAFAFA);
const Color _kPrimaryText = Color(0xFF1A1A1A);
const Color _kSecondaryText = Color(0xFF666666);
const double _kMinTouchTarget = 48.0;

/// Shows as a bottom sheet from chat menu or group info.
class InviteLinkSheet extends StatefulWidget {
  final int conversationId;

  const InviteLinkSheet({super.key, required this.conversationId});

  @override
  State<InviteLinkSheet> createState() => _InviteLinkSheetState();
}

class _InviteLinkSheetState extends State<InviteLinkSheet> {
  List<InviteLink> _links = [];
  bool _loading = true;
  bool _creating = false;

  // Create-link options
  int _expiresInHours = 72;
  int? _maxUses;

  @override
  void initState() {
    super.initState();
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    setState(() => _loading = true);
    final links = await GuestChatService.getInviteLinks(widget.conversationId);
    if (mounted) {
      setState(() {
        _links = links.where((l) => !l.isExpired).toList();
        _loading = false;
      });
    }
  }

  Future<void> _createLink() async {
    setState(() => _creating = true);
    final link = await GuestChatService.createInviteLink(
      conversationId: widget.conversationId,
      expiresInHours: _expiresInHours,
      maxUses: _maxUses,
    );
    if (!mounted) return;
    setState(() => _creating = false);
    if (link != null) {
      setState(() => _links.insert(0, link));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiungo kimetengenezwa')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindikana kutengeneza kiungo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _revokeLink(InviteLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Futa kiungo?', style: TextStyle(color: _kPrimaryText)),
        content: const Text(
          'Wageni waliopo bado watabaki kwenye mazungumzo, lakini kiungo hiki hakitafanya kazi tena.',
          style: TextStyle(color: _kSecondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hapana', style: TextStyle(color: _kSecondaryText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Futa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await GuestChatService.revokeInviteLink(
      widget.conversationId,
      link.token,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _links.removeWhere((l) => l.token == link.token));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiungo kimefutwa')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Imeshindikana kufuta kiungo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyLink(InviteLink link) {
    Clipboard.setData(ClipboardData(text: link.url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kiungo kimenakiliwa')),
    );
  }

  void _shareLink(InviteLink link) {
    SharePlus.instance.share(
      ShareParams(
        text: 'Jiunge na mazungumzo yangu kwenye Tajiri: ${link.url}',
      ),
    );
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tengeneza kiungo kipya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _kPrimaryText,
                  ),
                ),
                const SizedBox(height: 20),
                // Expiry selection
                const Text(
                  'Muda wa kuisha',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kPrimaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _expiryChip(ctx, setSheetState, 'Saa 24', 24),
                    _expiryChip(ctx, setSheetState, 'Siku 3', 72),
                    _expiryChip(ctx, setSheetState, 'Siku 7', 168),
                  ],
                ),
                const SizedBox(height: 16),
                // Max uses selection
                const Text(
                  'Idadi ya matumizi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _kPrimaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _usesChip(ctx, setSheetState, 'Bila kikomo', null),
                    _usesChip(ctx, setSheetState, '1', 1),
                    _usesChip(ctx, setSheetState, '5', 5),
                    _usesChip(ctx, setSheetState, '10', 10),
                    _usesChip(ctx, setSheetState, '25', 25),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: _kMinTouchTarget,
                  child: ElevatedButton(
                    onPressed: _creating
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            _createLink();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimaryText,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _creating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tengeneza',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _expiryChip(
      BuildContext ctx, StateSetter setSheetState, String label, int hours) {
    final selected = _expiresInHours == hours;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _kPrimaryText.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? _kPrimaryText : _kSecondaryText,
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (val) {
        if (val) {
          _expiresInHours = hours;
          setSheetState(() {});
        }
      },
    );
  }

  Widget _usesChip(
      BuildContext ctx, StateSetter setSheetState, String label, int? uses) {
    final selected = _maxUses == uses;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: _kPrimaryText.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? _kPrimaryText : _kSecondaryText,
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (val) {
        if (val) {
          _maxUses = uses;
          setSheetState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: _kBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _kSecondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Viungo vya mwaliko',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _kPrimaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: _kMinTouchTarget,
                    height: _kMinTouchTarget,
                    child: IconButton(
                      onPressed: _showCreateOptions,
                      icon: const Icon(Icons.add_link_rounded,
                          color: _kPrimaryText),
                      tooltip: 'Kiungo kipya',
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Shiriki kiungo ili wageni wajiunga na mazungumzo bila akaunti',
                style: TextStyle(fontSize: 13, color: _kSecondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            // Links list
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(color: _kPrimaryText),
              )
            else if (_links.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Icon(Icons.link_off_rounded,
                        size: 48, color: _kSecondaryText),
                    const SizedBox(height: 12),
                    const Text(
                      'Hakuna viungo vilivyo hai',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _kPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Bonyeza + kutengeneza kiungo kipya',
                      style: TextStyle(fontSize: 13, color: _kSecondaryText),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: _kMinTouchTarget,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateOptions,
                        icon: const Icon(Icons.add_link_rounded, size: 20),
                        label: const Text('Tengeneza kiungo'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimaryText,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _links.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _buildLinkTile(_links[i]),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkTile(InviteLink link) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Link URL (truncated)
            Text(
              link.url,
              style: const TextStyle(
                fontSize: 13,
                color: _kPrimaryText,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Metadata row
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: _kSecondaryText),
                const SizedBox(width: 4),
                Text(
                  link.expiresLabel,
                  style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                ),
                const SizedBox(width: 12),
                Icon(Icons.people_outline_rounded,
                    size: 14, color: _kSecondaryText),
                const SizedBox(width: 4),
                Text(
                  link.usesLabel,
                  style: const TextStyle(fontSize: 12, color: _kSecondaryText),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              children: [
                _actionButton(
                  icon: Icons.copy_rounded,
                  label: 'Nakili',
                  onTap: () => _copyLink(link),
                ),
                const SizedBox(width: 8),
                _actionButton(
                  icon: Icons.share_rounded,
                  label: 'Shiriki',
                  onTap: () => _shareLink(link),
                ),
                const Spacer(),
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Futa',
                  onTap: () => _revokeLink(link),
                  isDestructive: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : _kPrimaryText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: _kMinTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.3)
                : _kPrimaryText.withValues(alpha: 0.15),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Convenience function to show the invite link sheet from any screen.
void showInviteLinkSheet(BuildContext context, int conversationId) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => InviteLinkSheet(conversationId: conversationId),
  );
}
