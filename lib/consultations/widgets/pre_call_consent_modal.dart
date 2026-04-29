import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/consultation_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBorder = Color(0xFFEEEEEE);

/// Spec line 736 — explicit consent screens before video call.
/// Screens: location sharing, recording consent, Rx delivery consent.
/// Persists to consultations.consent_screens_signed + consent_receipts.
/// Returns true when all consents are captured.
class PreCallConsentModal extends StatefulWidget {
  final int consultationId;
  final int userId;

  const PreCallConsentModal({
    super.key,
    required this.consultationId,
    required this.userId,
  });

  static Future<bool> show(BuildContext context, {
    required int consultationId,
    required int userId,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PreCallConsentModal(
        consultationId: consultationId,
        userId: userId,
      ),
    );
    return result == true;
  }

  @override
  State<PreCallConsentModal> createState() => _PreCallConsentModalState();
}

class _ConsentScreen {
  final String id;
  final String titleSw;
  final String titleEn;
  final String bodySw;
  final String bodyEn;
  bool accepted;
  bool understood;

  _ConsentScreen({
    required this.id,
    required this.titleSw,
    required this.titleEn,
    required this.bodySw,
    required this.bodyEn,
  }) : accepted = false,
       understood = false;
}

class _PreCallConsentModalState extends State<PreCallConsentModal> {
  late final List<_ConsentScreen> _screens;
  int _currentIndex = 0;
  bool _submitting = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _screens = [
      _ConsentScreen(
        id: 'location_sharing',
        titleSw: 'Kushiriki mahali',
        titleEn: 'Location sharing',
        bodySw:
            'Daktari anaweza kuona mahali ulipo wakati wa mahojiano ya video. '
            'Hii inasaidia kutoa huduma bora na ya haraka zaidi.',
        bodyEn:
            'The doctor may see your location during the video consultation. '
            'This helps deliver faster and better care.',
      ),
      _ConsentScreen(
        id: 'recording_consent',
        titleSw: 'Kurekodi mahojiano',
        titleEn: 'Recording consent',
        bodySw:
            'Mahojiano yako yanaweza kurekodiwa kwa ajili ya ubora wa huduma '
            'na usalama. Rekodi zitahifadhiwa kwa siri kulingana na sheria.',
        bodyEn:
            'Your consultation may be recorded for quality of service and safety. '
            'Recordings are kept confidential per applicable law.',
      ),
      _ConsentScreen(
        id: 'rx_delivery_consent',
        titleSw: 'Kutuma dawa',
        titleEn: 'Prescription delivery consent',
        bodySw:
            'Dawa zilizoagizwa zinaweza kutumwa kwenye nambari yako ya simu '
            'au anwani uliyotoa. Thibitisha unakubali kupokea dawa kupitia '
            'mfumo wetu.',
        bodyEn:
            'Prescribed medication may be sent to your phone number or address '
            'on file. Confirm you agree to receive medication through our system.',
      ),
    ];
  }

  Future<void> _submit() async {
    final screens = _screens
        .map((s) => {
              'id': s.id,
              'accepted': s.accepted,
            })
        .toList();
    setState(() => _submitting = true);
    final res = await ConsultationService.submitConsentScreens(
      id: widget.consultationId,
      userId: widget.userId,
      screens: screens,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.success) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (_isSwahili ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    final screen = _screens[_currentIndex];
    final allAccepted = _screens.every((s) => s.accepted && s.understood);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.privacy_tip_rounded,
                      size: 18, color: _kPrimary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSw ? 'Idhini kabla ya video' : 'Consent before video',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_currentIndex + 1}/${_screens.length}',
                    style: const TextStyle(fontSize: 11, color: _kSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSw ? screen.titleSw : screen.titleEn,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isSw ? screen.bodySw : screen.bodyEn,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: screen.accepted,
                onChanged: (v) => setState(() => screen.accepted = v == true),
                title: Text(
                  isSw ? 'Nakubali' : 'I agree',
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              CheckboxListTile(
                value: screen.understood,
                onChanged: (v) =>
                    setState(() => screen.understood = v == true),
                title: Text(
                  isSw ? 'Nimeelewa' : 'I understand',
                  style: const TextStyle(fontSize: 13, color: _kPrimary),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            setState(() => _currentIndex--),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kPrimary,
                          side: const BorderSide(color: _kBorder),
                          minimumSize: const Size.fromHeight(46),
                        ),
                        child: Text(isSw ? 'Rudi' : 'Back'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: screen.accepted && screen.understood
                          ? () {
                              if (_currentIndex < _screens.length - 1) {
                                setState(() => _currentIndex++);
                              } else if (allAccepted) {
                                _submit();
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: Text(
                        _currentIndex < _screens.length - 1
                            ? (isSw ? 'Endelea' : 'Next')
                            : (isSw ? 'Thibitisha' : 'Confirm'),
                      ),
                    ),
                  ),
                ],
              ),
              if (_submitting) ...[
                const SizedBox(height: 12),
                const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
