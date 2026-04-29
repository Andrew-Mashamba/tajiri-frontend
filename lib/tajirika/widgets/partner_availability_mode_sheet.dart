import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../services/partner_availability_mode_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

/// Spec line 311 — partner-side bottom sheet to flip availability between
/// open / busy / closed and set busy ETA delta.
class PartnerAvailabilityModeSheet extends StatefulWidget {
  final int partnerUserId;
  final String currentMode;
  final int currentBusyEtaExtraMinutes;
  const PartnerAvailabilityModeSheet({
    super.key,
    required this.partnerUserId,
    required this.currentMode,
    this.currentBusyEtaExtraMinutes = 0,
  });

  static Future<bool?> show(
    BuildContext context, {
    required int partnerUserId,
    required String currentMode,
    int currentBusyEtaExtraMinutes = 0,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PartnerAvailabilityModeSheet(
        partnerUserId: partnerUserId,
        currentMode: currentMode,
        currentBusyEtaExtraMinutes: currentBusyEtaExtraMinutes,
      ),
    );
  }

  @override
  State<PartnerAvailabilityModeSheet> createState() =>
      _PartnerAvailabilityModeSheetState();
}

class _PartnerAvailabilityModeSheetState
    extends State<PartnerAvailabilityModeSheet> {
  late String _mode;
  late int _eta;
  bool _saving = false;

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void initState() {
    super.initState();
    _mode = widget.currentMode;
    _eta = widget.currentBusyEtaExtraMinutes;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await PartnerAvailabilityModeService.setMode(
      partnerUserId: widget.partnerUserId,
      mode: _mode,
      busyEtaExtraMinutes: _mode == 'busy' ? _eta : 0,
    );
    if (!mounted) return;
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSw ? 'Hali yangu' : 'My availability',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ..._modeRow('open',
                isSw ? 'Iko wazi' : 'Open',
                isSw
                    ? 'Pokea oda mpya kawaida.'
                    : 'Accept new orders normally.',
                Icons.check_circle_rounded,
                const Color(0xFF1B5E20)),
            ..._modeRow('busy',
                isSw ? 'Wenye shughuli' : 'Busy',
                isSw
                    ? 'Endelea kupokea, lakini ETA inaongezeka.'
                    : 'Still listed, but ETA shifts later.',
                Icons.access_time_rounded,
                const Color(0xFFE65100)),
            ..._modeRow('closed',
                isSw ? 'Imefungwa' : 'Closed',
                isSw
                    ? 'Wateja hawaoni huduma zako mpaka uongeze tena.'
                    : 'Customers can\'t see your services until you reopen.',
                Icons.do_not_disturb_rounded,
                const Color(0xFFB71C1C)),
            if (_mode == 'busy') ...[
              const SizedBox(height: 8),
              Text(isSw ? 'Ongezeka la ETA (daka)' : 'Add to ETA (min)',
                  style:
                      const TextStyle(fontSize: 11, color: _kSecondary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: [10, 20, 30, 45, 60].map((m) {
                  final selected = _eta == m;
                  return ChoiceChip(
                    label: Text('+$m'),
                    selected: selected,
                    onSelected: (_) => setState(() => _eta = m),
                    selectedColor: _kPrimary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : _kPrimary,
                      fontSize: 11,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(46),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(isSw ? 'Hifadhi' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _modeRow(
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color tint,
  ) {
    final selected = _mode == value;
    return [
      InkWell(
        onTap: () => setState(() => _mode = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? tint.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? tint : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: tint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _kPrimary),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.radio_button_checked_rounded,
                    color: tint, size: 18)
              else
                const Icon(Icons.radio_button_unchecked_rounded,
                    color: Color(0xFFBDBDBD), size: 18),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
    ];
  }
}
