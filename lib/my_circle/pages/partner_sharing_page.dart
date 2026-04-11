// lib/my_circle/pages/partner_sharing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/my_circle_models.dart';
import '../services/my_circle_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kPeriodRed = Color(0xFFEF5350);
const Color _kFertileGreen = Color(0xFF66BB6A);

class PartnerSharingPage extends StatefulWidget {
  final int userId;
  final bool isSwahili;
  const PartnerSharingPage({super.key, required this.userId, this.isSwahili = false});

  @override
  State<PartnerSharingPage> createState() => _PartnerSharingPageState();
}

class _PartnerSharingPageState extends State<PartnerSharingPage> {
  final MyCircleService _service = MyCircleService();
  bool _isLoading = true;

  // Owner mode data
  Map<String, dynamic>? _ownerStatus;

  // Partner mode data
  Map<String, dynamic>? _partnerViewData;

  // Invite code input
  final TextEditingController _codeController = TextEditingController();
  bool _isAccepting = false;

  bool get _sw => widget.isSwahili;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final statusFuture = _service.getPartnerStatus(widget.userId);
    final viewFuture = _service.viewPartnerCycle(widget.userId);
    final statusResult = await statusFuture;
    final viewResult = await viewFuture;
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _ownerStatus = statusResult.success ? statusResult.data : null;
      _partnerViewData = viewResult.success ? viewResult.data : null;
    });
  }

  Future<void> _invitePartner() async {
    final result = await _service.invitePartner(widget.userId);
    if (!mounted) return;
    if (result.success && result.data != null) {
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? (_sw ? 'Imeshindwa' : 'Failed'))),
      );
    }
  }

  Future<void> _revokeAccess() async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_sw ? 'Ondoa ufikivu?' : 'Revoke access?'),
        content: Text(_sw
            ? 'Mpenzi wako hataweza kuona tena data yako ya mzunguko.'
            : 'Your partner will no longer be able to see your cycle data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_sw ? 'Hapana' : 'Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_sw ? 'Ondoa' : 'Revoke', style: const TextStyle(color: _kPeriodRed)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await _service.revokePartnerAccess(widget.userId);
    if (!mounted) return;
    if (result.success) {
      messenger.showSnackBar(SnackBar(content: Text(_sw ? 'Ufikivu umeondolewa' : 'Access revoked')));
      _loadData();
    }
  }

  Future<void> _acceptInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _isAccepting = true);
    final messenger = ScaffoldMessenger.of(context);
    final result = await _service.acceptPartnerInvite(widget.userId, code);
    if (!mounted) return;
    setState(() => _isAccepting = false);

    if (result.success && result.data != null) {
      final ownerName = result.data!['owner_name'] ?? 'Partner';
      messenger.showSnackBar(
        SnackBar(content: Text(_sw ? 'Umeshirikiana na $ownerName' : 'Connected with $ownerName')),
      );
      _codeController.clear();
      _loadData();
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(result.message ?? (_sw ? 'Msimbo batili' : 'Invalid code'))),
      );
    }
  }

  Future<void> _updatePrivacy(String key, bool value) async {
    await _service.updatePartnerPrivacy(widget.userId, {key: value});
    if (mounted) _loadData();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_sw ? 'Msimbo umenakiliwa' : 'Code copied'), duration: const Duration(seconds: 1)),
    );
  }

  void _shareCode(String code) {
    SharePlus.instance.share(ShareParams(
      text: _sw
          ? 'Jiunge na mzunguko wangu kwenye TAJIRI! Tumia msimbo: $code'
          : 'Join my cycle on TAJIRI! Use code: $code',
    ));
  }

  void _sendViaTajiri(String code) {
    final message = _sw
        ? 'Jiunge na ufuatiliaji wa duru yangu kwenye TAJIRI! Tumia msimbo: $code\n\nWeka msimbo huu kwenye My Circle > Mpenzi.'
        : 'Join my cycle tracking on TAJIRI! Use code: $code\n\nEnter this code in your My Circle > Partner page.';
    Navigator.pushNamed(context, '/select-user-chat', arguments: {
      'prefillMessage': message,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _sw ? 'Shiriki na Mpenzi' : 'Partner Sharing',
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Owner section
                  _buildOwnerSection(),
                  const SizedBox(height: 24),
                  // Partner viewer section
                  _buildPartnerViewerSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildOwnerSection() {
    final status = _ownerStatus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _sw ? 'Shiriki data yako' : 'Share your data',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _sw ? 'Ruhusu mpenzi wako kuona mzunguko wako' : 'Let your partner see your cycle',
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
        const SizedBox(height: 12),

        if (status == null) ...[
          // No active share — show invite button
          _ActionCard(
            icon: Icons.person_add_rounded,
            title: _sw ? 'Mwamsha mpenzi' : 'Invite Partner',
            subtitle: _sw
                ? 'Tengeneza msimbo wa kualika mpenzi wako'
                : 'Generate a code to invite your partner',
            onTap: _invitePartner,
          ),
        ] else if (status['status'] == 'pending') ...[
          // Pending invite — show code
          _InviteCodeCard(
            code: status['invite_code'] ?? '',
            isSwahili: _sw,
            onCopy: () => _copyCode(status['invite_code'] ?? ''),
            onShare: () => _shareCode(status['invite_code'] ?? ''),
            onSendViaTajiri: () => _sendViaTajiri(status['invite_code'] ?? ''),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.cancel_rounded,
            title: _sw ? 'Futa mwaliko' : 'Cancel Invite',
            subtitle: _sw ? 'Ondoa msimbo wa mwaliko' : 'Remove the invite code',
            onTap: _revokeAccess,
            isDestructive: true,
          ),
        ] else if (status['status'] == 'accepted') ...[
          // Connected — show partner info
          _ConnectedPartnerCard(
            name: status['partner_name'] ?? (_sw ? 'Mpenzi' : 'Partner'),
            photoUrl: status['partner_photo'],
            isSwahili: _sw,
            onRevoke: _revokeAccess,
          ),
          const SizedBox(height: 16),

          // Privacy controls
          Text(
            _sw ? 'Faragha' : 'Privacy controls',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            _sw ? 'Chagua data ya kushiriki' : 'Choose what to share',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 8),
          _PrivacyToggle(
            icon: Icons.calendar_today_rounded,
            label: _sw ? 'Utabiri wa hedhi' : 'Period predictions',
            value: status['share_predictions'] == true,
            onChanged: (v) => _updatePrivacy('share_predictions', v),
          ),
          _PrivacyToggle(
            icon: Icons.favorite_rounded,
            label: _sw ? 'Dirisha la rutuba' : 'Fertile window',
            value: status['share_fertile'] == true,
            onChanged: (v) => _updatePrivacy('share_fertile', v),
          ),
          _PrivacyToggle(
            icon: Icons.healing_rounded,
            label: _sw ? 'Dalili' : 'Symptoms',
            value: status['share_symptoms'] == true,
            onChanged: (v) => _updatePrivacy('share_symptoms', v),
          ),
          _PrivacyToggle(
            icon: Icons.mood_rounded,
            label: _sw ? 'Hisia' : 'Mood',
            value: status['share_mood'] == true,
            onChanged: (v) => _updatePrivacy('share_mood', v),
          ),
        ],
      ],
    );
  }

  Widget _buildPartnerViewerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          _sw ? 'Data ya mpenzi' : "Partner's data",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _sw ? 'Angalia mzunguko wa mpenzi wako' : "View your partner's cycle",
          style: const TextStyle(fontSize: 12, color: _kSecondary),
        ),
        const SizedBox(height: 12),

        if (_partnerViewData != null) ...[
          _PartnerCycleView(data: _partnerViewData!, isSwahili: _sw),
        ] else ...[
          // Not connected as partner — show code entry
          _EnterCodeCard(
            controller: _codeController,
            isSwahili: _sw,
            isLoading: _isAccepting,
            onAccept: _acceptInvite,
          ),
        ],
      ],
    );
  }
}

// ─── Action Card ──────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? _kPeriodRed : _kPrimary;
    return Material(
      color: _kCardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(subtitle, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invite Code Card ─────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final bool isSwahili;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback? onSendViaTajiri;

  const _InviteCodeCard({
    required this.code,
    required this.isSwahili,
    required this.onCopy,
    required this.onShare,
    this.onSendViaTajiri,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            isSwahili ? 'Msimbo wa mwaliko' : 'Invite code',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Mpe mpenzi wako msimbo huu'
                : 'Give this code to your partner',
            style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(isSwahili ? 'Nakili' : 'Copy', style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(isSwahili ? 'Shiriki' : 'Share', style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
          if (onSendViaTajiri != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSendViaTajiri,
                icon: const Icon(Icons.message_rounded, size: 16),
                label: Text(isSwahili ? 'Tuma kwa TAJIRI' : 'Send via TAJIRI', style: const TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(0, 44),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Connected Partner Card ───────────────────────────────────

class _ConnectedPartnerCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final bool isSwahili;
  final VoidCallback onRevoke;

  const _ConnectedPartnerCard({
    required this.name,
    this.photoUrl,
    required this.isSwahili,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kFertileGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null ? const Icon(Icons.person_rounded, color: _kSecondary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: _kFertileGreen, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSwahili ? 'Imeunganishwa' : 'Connected',
                      style: const TextStyle(fontSize: 11, color: _kFertileGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: onRevoke,
              style: TextButton.styleFrom(
                foregroundColor: _kPeriodRed,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(isSwahili ? 'Ondoa' : 'Revoke', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Privacy Toggle ───────────────────────────────────────────

class _PrivacyToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacyToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _kPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            height: 28,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: _kPrimary,
              activeTrackColor: _kPrimary.withValues(alpha: 0.3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Enter Code Card ──────────────────────────────────────────

class _EnterCodeCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isSwahili;
  final bool isLoading;
  final VoidCallback onAccept;

  const _EnterCodeCard({
    required this.controller,
    required this.isSwahili,
    required this.isLoading,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Weka msimbo wa mwaliko' : 'Enter invite code',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            isSwahili
                ? 'Omba msimbo kutoka kwa mpenzi wako'
                : 'Ask your partner for their invite code',
            style: const TextStyle(fontSize: 11, color: _kSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'CRC-XXXXXXXX',
              hintStyle: TextStyle(color: _kSecondary.withValues(alpha: 0.5)),
              filled: true,
              fillColor: _kPrimary.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 1, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: isLoading ? null : onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      isSwahili ? 'Kubali mwaliko' : 'Accept invite',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Partner Cycle View ───────────────────────────────────────

class _PartnerCycleView extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isSwahili;

  const _PartnerCycleView({required this.data, required this.isSwahili});

  String _fmtDate(String? dateStr) {
    if (dateStr == null) return '--';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return DateFormat('d MMM').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = data['owner_name'] ?? (isSwahili ? 'Mpenzi' : 'Partner');
    final ownerPhoto = data['owner_photo'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Partner header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                backgroundImage: ownerPhoto != null ? NetworkImage(ownerPhoto) : null,
                child: ownerPhoto == null
                    ? const Icon(Icons.person_rounded, color: Colors.white54, size: 20)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? 'Mzunguko wa $ownerName' : "$ownerName's Cycle",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isSwahili ? 'Data iliyoshirikiwa' : 'Shared data',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kFertileGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: _kFertileGreen, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                      isSwahili ? 'Hai' : 'Live',
                      style: const TextStyle(fontSize: 10, color: _kFertileGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Prediction data
        if (data.containsKey('next_period_date') || data.containsKey('cycle_length')) ...[
          _DataRow(
            icon: Icons.water_drop_rounded,
            iconColor: _kPeriodRed,
            label: isSwahili ? 'Hedhi ijayo' : 'Next period',
            value: _fmtDate(data['next_period_date'] as String?),
          ),
          if (data['cycle_length'] != null)
            _DataRow(
              icon: Icons.loop_rounded,
              iconColor: _kPrimary,
              label: isSwahili ? 'Urefu wa duru' : 'Cycle length',
              value: '${data['cycle_length']} ${isSwahili ? 'siku' : 'days'}',
            ),
        ],

        // Fertile window
        if (data.containsKey('fertile_window_start')) ...[
          _DataRow(
            icon: Icons.favorite_rounded,
            iconColor: _kFertileGreen,
            label: isSwahili ? 'Dirisha la rutuba' : 'Fertile window',
            value: '${_fmtDate(data['fertile_window_start'] as String?)} - ${_fmtDate(data['fertile_window_end'] as String?)}',
          ),
          if (data['ovulation_date'] != null)
            _DataRow(
              icon: Icons.egg_rounded,
              iconColor: const Color(0xFF42A5F5),
              label: isSwahili ? 'Ovulesheni' : 'Ovulation',
              value: _fmtDate(data['ovulation_date'] as String?),
            ),
        ],

        // Recent symptoms
        if (data['recent_symptoms'] != null) ...[
          const SizedBox(height: 8),
          Text(
            isSwahili ? 'Dalili za hivi karibuni' : 'Recent symptoms',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 6),
          ..._buildSymptomsList(data['recent_symptoms'] as List),
        ],

        // Recent moods
        if (data['recent_moods'] != null) ...[
          const SizedBox(height: 8),
          Text(
            isSwahili ? 'Hisia za hivi karibuni' : 'Recent moods',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
          ),
          const SizedBox(height: 6),
          ..._buildMoodsList(data['recent_moods'] as List),
        ],

        // If nothing shared
        if (!data.containsKey('next_period_date') &&
            !data.containsKey('fertile_window_start') &&
            data['recent_symptoms'] == null &&
            data['recent_moods'] == null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isSwahili
                    ? 'Mpenzi wako hajashiriki data yoyote bado'
                    : 'Your partner has not shared any data yet',
                style: const TextStyle(fontSize: 13, color: _kSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildSymptomsList(List symptoms) {
    final items = <Widget>[];
    for (final entry in symptoms.take(7)) {
      final map = entry is Map ? entry : {};
      final date = map['date'] ?? '';
      final syms = map['symptoms'];
      final symList = syms is List ? syms.map((s) => '$s').join(', ') : '$syms';
      if (symList.isEmpty || symList == 'null') continue;
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(date is String ? _fmtDate(date) : '--', style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Expanded(child: Text(symList, style: const TextStyle(fontSize: 12, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
    }
    return items;
  }

  List<Widget> _buildMoodsList(List moods) {
    final items = <Widget>[];
    for (final entry in moods.take(7)) {
      final map = entry is Map ? entry : {};
      final date = map['date'] ?? '';
      final mood = map['mood'] ?? '';
      final moodObj = Mood.fromString(mood is String ? mood : null);
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(date is String ? _fmtDate(date) : '--', style: const TextStyle(fontSize: 11, color: _kSecondary, fontWeight: FontWeight.w500)),
              const SizedBox(width: 8),
              Text(moodObj != null ? '${moodObj.emoji} ${moodObj.displayName(isSwahili)}' : '$mood', style: const TextStyle(fontSize: 12, color: _kPrimary)),
            ],
          ),
        ),
      );
    }
    return items;
  }
}

// ─── Data Row ─────────────────────────────────────────────────

class _DataRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _DataRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
