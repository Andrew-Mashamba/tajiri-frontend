// lib/my_baby/pages/caregiver_sharing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../models/my_baby_models.dart';
import '../services/my_baby_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);
const Color _kDanger = Color(0xFFEF5350);

class CaregiverSharingPage extends StatefulWidget {
  final Baby baby;
  final int userId;

  const CaregiverSharingPage({
    super.key,
    required this.baby,
    required this.userId,
  });

  @override
  State<CaregiverSharingPage> createState() => _CaregiverSharingPageState();
}

class _CaregiverSharingPageState extends State<CaregiverSharingPage> {
  final MyBabyService _service = MyBabyService();
  final TextEditingController _codeController = TextEditingController();

  bool _isLoading = true;
  bool _isInviting = false;
  bool _isAccepting = false;
  String _selectedRole = 'caregiver';
  String? _token;

  List<CaregiverShare> _caregivers = [];
  CaregiverShare? _pendingInvite;

  bool get _sw => AppStringsScope.of(context)?.isSwahili ?? true;

  @override
  void initState() {
    super.initState();
    _token = LocalStorageService.instanceSync?.getAuthToken();
    _loadData();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_token == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final result = await _service.listCaregivers(_token!, widget.baby.id);
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (result.success) {
          _caregivers = result.items
              .where((c) => c.status == 'accepted')
              .toList();
          final pending = result.items
              .where((c) =>
                  c.status == 'pending' &&
                  c.ownerUserId == widget.userId)
              .toList();
          _pendingInvite = pending.isNotEmpty ? pending.first : null;
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_sw
              ? 'Imeshindikana kupakia walezi'
              : 'Failed to load caregivers')),
        );
      }
    }
  }

  Future<void> _inviteCaregiver() async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isInviting = true);

    try {
      final result = await _service.inviteCaregiver(
        token: _token!,
        babyId: widget.baby.id,
        ownerUserId: widget.userId,
        role: _selectedRole,
      );
      if (!mounted) return;
      setState(() => _isInviting = false);

      if (result.success && result.data != null) {
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa kutengeneza mwaliko' : 'Failed to create invite'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isInviting = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _acceptInvite() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || _token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;
    setState(() => _isAccepting = true);

    try {
      final result = await _service.acceptInvite(
        token: _token!,
        inviteCode: code,
        caregiverUserId: widget.userId,
      );
      if (!mounted) return;
      setState(() => _isAccepting = false);

      if (result.success) {
        _codeController.clear();
        messenger.showSnackBar(
          SnackBar(
              content:
                  Text(sw ? 'Umeshirikiana!' : 'Connected successfully!')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Msimbo batili' : 'Invalid code'))),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAccepting = false);
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  Future<void> _revokeCaregiver(CaregiverShare caregiver) async {
    if (_token == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final sw = _sw;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sw ? 'Ondoa ufikivu?' : 'Revoke access?'),
        content: Text(sw
            ? 'Mlezi huyu hataweza kuona tena data ya mtoto.'
            : 'This caregiver will no longer see baby data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(sw ? 'Hapana' : 'Cancel',
                style: const TextStyle(color: _kSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(sw ? 'Ondoa' : 'Revoke',
                style: const TextStyle(color: _kDanger)),
          ),
        ],
      ),
    );
    if (confirmed != true || caregiver.id == null) return;

    try {
      final result =
          await _service.revokeCaregiver(_token!, caregiver.id!);
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
              content:
                  Text(sw ? 'Ufikivu umeondolewa' : 'Access revoked')),
        );
        _loadData();
      } else {
        messenger.showSnackBar(
          SnackBar(
              content: Text(result.message ??
                  (sw ? 'Imeshindwa' : 'Failed'))),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(sw ? 'Hitilafu imetokea' : 'An error occurred')),
        );
      }
    }
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_sw ? 'Msimbo umenakiliwa' : 'Code copied'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareCode(String code) {
    final sw = _sw;
    SharePlus.instance.share(ShareParams(
      text: sw
          ? 'Jiunge na ufuatiliaji wa mtoto wangu kwenye TAJIRI! Tumia msimbo: $code'
          : 'Join my baby tracking on TAJIRI! Use code: $code',
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sw = _sw;

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          sw ? 'Walezi' : 'Caregivers',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _kPrimary,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Invite section ────────────────────────
                  _buildInviteSection(sw),
                  const SizedBox(height: 24),

                  // ── Connected caregivers ──────────────────
                  _buildCaregiversList(sw),
                  const SizedBox(height: 24),

                  // ── Accept invite section ─────────────────
                  _buildAcceptSection(sw),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildInviteSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Alika mlezi' : 'Invite Caregiver',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          sw
              ? 'Shiriki data ya mtoto na mlezi mwingine'
              : 'Share baby data with another caregiver',
          style: const TextStyle(fontSize: 12, color: _kSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),

        // Role selector
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sw ? 'Chagua jukumu' : 'Select role',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary),
              ),
              const SizedBox(height: 10),
              _RoleOption(
                label: sw
                    ? 'Mlezi (anaweza kuandika)'
                    : 'Caregiver (can log)',
                subtitle: sw
                    ? 'Anaweza kuongeza rekodi za kulisha, usingizi, nepi'
                    : 'Can add feeding, sleep, diaper records',
                isSelected: _selectedRole == 'caregiver',
                onTap: () => setState(() => _selectedRole = 'caregiver'),
              ),
              const SizedBox(height: 8),
              _RoleOption(
                label: sw
                    ? 'Mtazamaji (kusoma tu)'
                    : 'Viewer (read only)',
                subtitle: sw
                    ? 'Anaweza kuona data tu, hawezi kuandika'
                    : 'Can view data only, cannot log entries',
                isSelected: _selectedRole == 'viewer',
                onTap: () => setState(() => _selectedRole = 'viewer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (_pendingInvite != null) ...[
          // Show pending invite code
          _InviteCodeCard(
            code: _pendingInvite!.inviteCode,
            isSwahili: sw,
            onCopy: () => _copyCode(_pendingInvite!.inviteCode),
            onShare: () => _shareCode(_pendingInvite!.inviteCode),
          ),
        ] else ...[
          // Show invite button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _isInviting ? null : _inviteCaregiver,
              icon: _isInviting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add_rounded, size: 18),
              label: Text(
                sw ? 'Tengeneza msimbo wa mwaliko' : 'Generate invite code',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                disabledBackgroundColor: _kPrimary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCaregiversList(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sw ? 'Walezi walioshirikishwa' : 'Connected caregivers',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 8),
        if (_caregivers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.people_outline_rounded,
                    size: 32, color: Colors.grey.shade300),
                const SizedBox(height: 8),
                Text(
                  sw
                      ? 'Bado hakuna walezi walioshirikishwa'
                      : 'No caregivers connected yet',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        else
          ..._caregivers.map((c) => _CaregiverTile(
                caregiver: c,
                isSwahili: sw,
                onRevoke: () => _revokeCaregiver(c),
              )),
      ],
    );
  }

  Widget _buildAcceptSection(bool sw) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 16),
        Text(
          sw ? 'Una msimbo wa mwaliko?' : 'Have an invite code?',
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          sw
              ? 'Weka msimbo uliopewa na mzazi mwingine'
              : 'Enter a code received from another parent',
          style: const TextStyle(fontSize: 12, color: _kSecondary),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kCardBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: sw ? 'Weka msimbo hapa' : 'Enter code here',
                  hintStyle:
                      TextStyle(color: _kSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: _kPrimary.withValues(alpha: 0.04),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isAccepting ? null : _acceptInvite,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kPrimary,
                    disabledBackgroundColor:
                        _kPrimary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isAccepting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(
                          sw ? 'Kubali mwaliko' : 'Accept invite',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Role Option ─────────────────────────────────────────────────

class _RoleOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? _kPrimary.withValues(alpha: 0.06)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _kPrimary : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _kPrimary : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style:
                          const TextStyle(fontSize: 11, color: _kSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Invite Code Card ────────────────────────────────────────────

class _InviteCodeCard extends StatelessWidget {
  final String code;
  final bool isSwahili;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _InviteCodeCard({
    required this.code,
    required this.isSwahili,
    required this.onCopy,
    required this.onShare,
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
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.6)),
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
                ? 'Mpe mlezi msimbo huu'
                : 'Give this code to the caregiver',
            style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(isSwahili ? 'Nakili' : 'Copy',
                      style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShare,
                  icon: const Icon(Icons.share_rounded, size: 16),
                  label: Text(isSwahili ? 'Shiriki' : 'Share',
                      style: const TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: const Size(0, 44),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Caregiver Tile ──────────────────────────────────────────────

class _CaregiverTile extends StatelessWidget {
  final CaregiverShare caregiver;
  final bool isSwahili;
  final VoidCallback onRevoke;

  const _CaregiverTile({
    required this.caregiver,
    required this.isSwahili,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final roleBadge = caregiver.role == 'viewer'
        ? (isSwahili ? 'Mtazamaji' : 'Viewer')
        : (isSwahili ? 'Mlezi' : 'Caregiver');
    final name =
        caregiver.caregiverName ?? (isSwahili ? 'Mlezi' : 'Caregiver');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _kPrimary.withValues(alpha: 0.08),
            backgroundImage: caregiver.caregiverPhoto != null
                ? NetworkImage(caregiver.caregiverPhoto!)
                : null,
            child: caregiver.caregiverPhoto == null
                ? const Icon(Icons.person_rounded,
                    color: _kSecondary, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    roleBadge,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _kSecondary),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: TextButton(
              onPressed: onRevoke,
              style: TextButton.styleFrom(
                foregroundColor: _kDanger,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(
                isSwahili ? 'Ondoa' : 'Revoke',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
