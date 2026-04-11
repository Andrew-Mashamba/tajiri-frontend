// lib/tanesco/pages/help_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/tanesco_models.dart';
import '../services/tanesco_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});
  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  List<ErrorCode> _errorCodes = [];
  bool _loading = true;

  // Fallback error codes for offline/initial use
  static final _fallbackCodes = [
    ErrorCode(code: '01', description: 'Nambari ya mita sio sahihi / Invalid meter number',
        solution: 'Hakikisha nambari ya mita ina tarakimu 11-13. Verify the meter number has 11-13 digits.'),
    ErrorCode(code: '02', description: 'Kiasi kidogo sana / Amount too low',
        solution: 'Kiwango cha chini ni TZS 1,000. Minimum amount is TZS 1,000.'),
    ErrorCode(code: '03', description: 'Mita imezuiwa / Meter blocked',
        solution: 'Wasiliana na TANESCO ofisi ya karibu. Contact nearest TANESCO office.'),
    ErrorCode(code: '04', description: 'Mtandao umeshindwa / Network failure',
        solution: 'Jaribu tena baada ya dakika chache. Try again after a few minutes.'),
    ErrorCode(code: '05', description: 'Malipo hayakukamilika / Payment not completed',
        solution: 'Angalia M-Pesa/Tigo Pesa message. Check your mobile money confirmation message.'),
    ErrorCode(code: '06', description: 'Token haiwezi kuingia / Token rejected by meter',
        solution: 'Hakikisha unaingiza token nzima (20 digit). Ensure you enter all 20 digits. Zima mita kisha washa tena.'),
    ErrorCode(code: '07', description: 'Mita haijasajiliwa / Meter not registered',
        solution: 'Peleka nambari ya mita TANESCO ofisi kusajili. Register your meter at TANESCO office.'),
    ErrorCode(code: '08', description: 'Huduma ya malipo haipo / Payment service unavailable',
        solution: 'Selcom/TANESCO maintenance. Jaribu tena baadaye. Try again later.'),
    ErrorCode(code: '09', description: 'Deni la zamani / Outstanding debt',
        solution: 'Lipa deni kwanza kabla ya kununua token. Clear outstanding debt before purchasing tokens.'),
    ErrorCode(code: '10', description: 'Token tayari imetumika / Token already used',
        solution: 'Kila token inaweza kutumika mara moja tu. Each token can only be used once. Check your purchase history.'),
  ];

  static const _faqs = [
    {'q': 'Ninawezaje kununua LUKU? / How to buy LUKU?',
     'a': 'Bonyeza "Nunua LUKU" kwenye ukurasa mkuu, ingiza kiasi na chagua njia ya malipo (M-Pesa, Tigo Pesa, au Airtel Money). Tap "Buy LUKU" on the home page, enter amount and select payment method.'},
    {'q': 'Token yangu inatumika kwa muda gani? / How long is a token valid?',
     'a': 'Token ya LUKU haina muda wa kumalizika, ila tunapendekeza uitumie mara moja. LUKU tokens do not expire, but we recommend using them immediately.'},
    {'q': 'Nifanye nini kama umeme umekatika? / What to do during outage?',
     'a': 'Ripoti kukatika kupitia app au piga simu 145. Report the outage through the app or call 145.'},
    {'q': 'Jinsi ya kusoma mita yangu? / How to read my meter?',
     'a': 'Bonyeza kitufe cha bluu kwenye mita kuona kiasi kilichobaki. Press the blue button on your meter to see remaining units.'},
    {'q': 'Gharama ya muunganisho mpya? / New connection cost?',
     'a': 'Nyumba: TZS 327,150 | Biashara: TZS 455,500 | Viwanda: TZS 1,250,000. Domestic: TZS 327,150 | Commercial: TZS 455,500 | Industrial: TZS 1,250,000.'},
  ];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await TanescoService.getErrorCodes();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.items.isNotEmpty) {
        _errorCodes = result.items;
      } else {
        _errorCodes = _fallbackCodes;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Msaada wa LUKU' : 'LUKU Help',
            style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white, elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Emergency contacts
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.emergency_rounded, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Dharura / Emergency',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _EmergencyContact(label: 'TANESCO Hotline', number: '145'),
                      const SizedBox(height: 6),
                      _EmergencyContact(label: 'Umeme umeshuka / Fallen lines', number: '0222 451 130'),
                      const SizedBox(height: 6),
                      _EmergencyContact(label: 'Moto / Fire', number: '114'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Error codes
                Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Kosa la LUKU' : 'Token Error Codes',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 4),
                Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Gusa kupanua' : 'Tap to expand',
                    style: const TextStyle(fontSize: 11, color: _kSecondary)),
                const SizedBox(height: 10),
                ..._errorCodes.map((ec) => _ErrorCodeTile(errorCode: ec)),
                const SizedBox(height: 20),

                // FAQ
                Text((AppStringsScope.of(context)?.isSwahili ?? false) ? 'Maswali ya Mara kwa Mara' : 'FAQ',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary)),
                const SizedBox(height: 10),
                ..._faqs.map((faq) => _FaqTile(question: faq['q']!, answer: faq['a']!)),
                const SizedBox(height: 20),

                // TANESCO office link
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => _launchUrl('https://www.tanesco.co.tz'),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: _kPrimary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.language_rounded, size: 20, color: _kPrimary),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tovuti ya TANESCO',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary)),
                                Text('www.tanesco.co.tz',
                                    style: TextStyle(fontSize: 11, color: _kSecondary)),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new_rounded, size: 18, color: _kSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _EmergencyContact extends StatelessWidget {
  final String label; final String number;
  const _EmergencyContact({required this.label, required this.number});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) await launchUrl(uri);
    },
    child: Row(children: [
      const Icon(Icons.phone_rounded, size: 14, color: Colors.red),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 12, color: _kPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      const Spacer(),
      Text(number, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
    ]),
  );
}

class _ErrorCodeTile extends StatefulWidget {
  final ErrorCode errorCode;
  const _ErrorCodeTile({required this.errorCode});
  @override
  State<_ErrorCodeTile> createState() => _ErrorCodeTileState();
}

class _ErrorCodeTileState extends State<_ErrorCodeTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32, height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.errorCode.code,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.red)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.errorCode.description,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 20, color: _kSecondary),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.errorCode.solution,
                              style: const TextStyle(fontSize: 12, color: _kPrimary, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question; final String answer;
  const _FaqTile({required this.question, required this.answer});
  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.question,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kPrimary),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                    Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        size: 20, color: _kSecondary),
                  ],
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(widget.answer,
                      style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.4)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
