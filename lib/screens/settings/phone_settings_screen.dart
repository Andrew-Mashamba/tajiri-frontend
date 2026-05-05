// lib/screens/settings/phone_settings_screen.dart
//
// Read-only display of the user's account phone number. Phone is the
// auth identity (Sanctum tokens are issued on User rows whose email is
// `{phone}@tajiri.local` — see ResolvesUserProfileFromSanctumUser).
// Changing the phone is a re-verification flow that doesn't exist yet
// in-app, so this screen explains the constraint instead of pretending
// to support edits.

import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/tajiri_app_bar.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kSurface = Colors.white;

class PhoneSettingsScreen extends StatefulWidget {
  final int currentUserId;
  const PhoneSettingsScreen({super.key, required this.currentUserId});

  @override
  State<PhoneSettingsScreen> createState() => _PhoneSettingsScreenState();
}

class _PhoneSettingsScreenState extends State<PhoneSettingsScreen> {
  String? _phone;
  bool _isVerified = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storage = await LocalStorageService.getInstance();
    final user = storage.getUser();
    if (!mounted) return;
    setState(() {
      _phone = user?.phoneNumber;
      _isVerified = user?.isPhoneVerified ?? false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context);
    final isSw = s?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: TajiriAppBar(title: s?.phoneNumber ?? 'Phone number'),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _kPrimary,
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildPhoneCard(isSw),
                  const SizedBox(height: 16),
                  _buildExplainerCard(isSw),
                ],
              ),
      ),
    );
  }

  Widget _buildPhoneCard(bool isSw) {
    final phone = _phone;
    final hasPhone = phone != null && phone.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.phone_outlined,
              size: 22,
              color: _kPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSw ? 'Namba yako ya simu' : 'Your phone number',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _kSecondary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhone
                      ? phone
                      : (isSw ? 'Hakuna namba' : 'No phone on file'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _isVerified
                      ? (isSw ? 'Imethibitishwa' : 'Verified')
                      : (isSw
                          ? 'Haijathibitishwa'
                          : 'Not verified'),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isVerified
                        ? const Color(0xFF2E7D32)
                        : _kTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainerCard(bool isSw) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: _kSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                isSw
                    ? 'Kubadili namba yako'
                    : 'Changing your number',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSw
                ? 'Namba yako ya simu ndio kitambulisho cha akaunti yako '
                    'kwenye TAJIRI. Kubadili namba kunahitaji uthibitisho '
                    'mpya na kunafanyika kupitia msaada wa wateja.'
                : 'Your phone number is your TAJIRI account identity. '
                    'Changing it requires re-verification and is handled '
                    'through customer support.',
            style: const TextStyle(
              fontSize: 13,
              color: _kSecondary,
              height: 1.4,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
