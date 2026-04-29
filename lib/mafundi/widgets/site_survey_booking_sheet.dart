import 'package:flutter/material.dart';
import '../../l10n/app_strings_scope.dart';
import '../services/service_request_service.dart';

class SiteSurveyBookingSheet extends StatefulWidget {
  final int requestId;
  final int userId;

  const SiteSurveyBookingSheet({
    super.key,
    required this.requestId,
    required this.userId,
  });

  @override
  State<SiteSurveyBookingSheet> createState() => _SiteSurveyBookingSheetState();
}

class _SiteSurveyBookingSheetState extends State<SiteSurveyBookingSheet> {
  final _feeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    final fee = int.tryParse(_feeCtrl.text.trim());
    if (fee == null || fee <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isSw ? 'Andika bei sahihi' : 'Enter a valid fee'),
      ));
      return;
    }
    setState(() => _busy = true);
    final res = await ServiceRequestService.createSurvey(
      id: widget.requestId,
      userId: widget.userId,
      siteSurveyFeeTzs: fee,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (res.success && res.request != null) {
      Navigator.of(context).pop(res.request);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.message ?? (isSw ? 'Imeshindikana' : 'Failed')),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSw = AppStringsScope.of(context)?.isSwahili ?? false;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSw ? 'Endesha ukaguzi' : 'Run survey',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              isSw
                  ? 'Weka ada ya ukaguzi wa site kabla ya kuanza kazi kubwa.'
                  : 'Set a site-survey fee before starting the full job.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _feeCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: isSw ? 'Ada ya ukaguzi (TZS)' : 'Survey fee (TZS)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isSw ? 'Tuma' : 'Send'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
