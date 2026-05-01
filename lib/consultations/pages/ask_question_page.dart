import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../models/consultation.dart';
import '../services/consultation_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

/// F7 #25 — Pay-per-question flow (minimal).
/// User selects vertical, types question, pays a fee, and submits an async
/// text consultation (mode: text, 15 min).
class AskQuestionPage extends StatefulWidget {
  final int userId;
  const AskQuestionPage({super.key, required this.userId});

  @override
  State<AskQuestionPage> createState() => _AskQuestionPageState();
}

class _AskQuestionPageState extends State<AskQuestionPage> {
  ConsultationVertical _vertical = ConsultationVertical.medical;
  final TextEditingController _questionCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  Consultation? _submitted;

  static const Map<ConsultationVertical, int> _feeTzs = {
    ConsultationVertical.legal: 15000,
    ConsultationVertical.medical: 10000,
    ConsultationVertical.business: 12000,
  };

  bool get _isSwahili => AppStringsScope.of(context)?.isSwahili ?? false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _questionCtrl.text.trim();
    if (question.length < 10) {
      setState(() => _error = _isSwahili
          ? 'Andika swali lako (angalalu herufi 10)'
          : 'Please type your question (at least 10 characters)');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final fee = _feeTzs[_vertical] ?? 10000;
    final res = await ConsultationService.create(
      userId: widget.userId,
      targetPartnerUserId: 0, // backend will auto-assign
      vertical: _vertical,
      mode: ConsultationMode.text,
      durationMin: 15,
      serviceTitle: _isSwahili ? 'Swali la Haraka' : 'Quick Question',
      feeTzs: fee,
      intakeSummary: question,
      startsAt: DateTime.now().add(const Duration(minutes: 5)),
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      if (res.success && res.consultation != null) {
        _submitted = res.consultation;
      } else {
        _error = res.message ?? (_isSwahili ? 'Imeshindwa kutuma' : 'Failed to submit');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSw = _isSwahili;
    if (_submitted != null) {
      return _buildSuccessScreen(isSw);
    }
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _kPrimary,
        title: Text(
          isSw ? 'Uliza Swali' : 'Ask a Question',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSw ? 'Chagua Kategoria' : 'Select Category',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 10),
              ...ConsultationVertical.values.map((v) {
                final selected = _vertical == v;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _vertical = v),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected ? _kPrimary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(v.icon, size: 18, color: selected ? Colors.white : _kSecondary),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isSw ? v.labelSwahili : v.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : _kPrimary,
                              ),
                            ),
                          ),
                          if (selected)
                            const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Text(
                isSw ? 'Swali Lako' : 'Your Question',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _questionCtrl,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: isSw
                      ? 'Eleza shida yako kwa ufupi...'
                      : 'Briefly describe your issue...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money_rounded, size: 18, color: _kSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isSw ? 'Ada ya Huduma' : 'Service Fee',
                        style: const TextStyle(fontSize: 13, color: _kSecondary),
                      ),
                    ),
                    Text(
                      'TZS ${_feeTzs[_vertical]?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kPrimary),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFF44336)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isSw ? 'Lipa na Tuma' : 'Pay & Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessScreen(bool isSw) {
    final estimated = _submitted!.createdAt?.add(const Duration(minutes: 30)) ?? DateTime.now().add(const Duration(minutes: 30));
    final timeText = '${estimated.hour.toString().padLeft(2, '0')}:${estimated.minute.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF4CAF50)),
                const SizedBox(height: 20),
                Text(
                  isSw ? 'Swali Limetumwa!' : 'Question Submitted!',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  isSw
                      ? 'Tutaanza kushughulikia swali lako hivi punde. Unatarajiwa kupata jibu kabla ya saa $timeText.'
                      : 'We will start working on your question shortly. You should receive a response before $timeText.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.5),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(isSw ? 'Rudi Nyuma' : 'Go Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
