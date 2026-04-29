import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../models/food_cash_donation.dart';
import '../../fungu_la_kumi/pages/fungu_la_kumi_home_page.dart';
import '../../zaka/pages/zaka_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);
const Color _kAccent = Color(0xFF4CAF50);
const Color _kBorder = Color(0xFFE0E0E0);

class DonationReceiptPage extends StatelessWidget {
  final FoodCashDonation donation;
  final int userId;
  const DonationReceiptPage({super.key, required this.donation, required this.userId});

  Future<Uint8List> _buildPdf() async {
    final d = donation;
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          pw.Widget kv(String k, String v) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 3),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(
                      width: 160,
                      child: pw.Text(k,
                          style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
                    ),
                    pw.Expanded(
                      child: pw.Text(v, style: const pw.TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              );
          return pw.Padding(
            padding: const pw.EdgeInsets.all(28),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TAJIRI',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text('Risiti ya Mchango',
                    style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Divider(),
                pw.SizedBox(height: 8),
                pw.Text('TZS ${_fmtAmount(d.amount)}',
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    d.isInstitutional ? 'Mchango wa kikundi/kampuni' : 'Mchango binafsi',
                    style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                pw.SizedBox(height: 16),
                kv('Namba ya risiti', d.receiptNumber ?? '-'),
                kv('Tarehe', _fmtDate(d.createdAt)),
                kv('Shirika lililopokea', d.orgName.isEmpty ? '#${d.orgId}' : d.orgName),
                if (d.isInstitutional) ...[
                  kv('Jina la kampuni', d.organizationName ?? '-'),
                  if (d.registrationNumber != null && d.registrationNumber!.isNotEmpty)
                    kv('Namba ya usajili', d.registrationNumber!),
                  if (d.contactPerson != null && d.contactPerson!.isNotEmpty)
                    kv('Mwasiliani', d.contactPerson!),
                  if (d.contactPhone != null && d.contactPhone!.isNotEmpty)
                    kv('Simu', d.contactPhone!),
                  if (d.contactEmail != null && d.contactEmail!.isNotEmpty)
                    kv('Barua pepe', d.contactEmail!),
                ],
                kv('Njia ya malipo', d.paymentMethod),
                if (d.paymentReference != null && d.paymentReference!.isNotEmpty)
                  kv('Rejea ya malipo', d.paymentReference!),
                kv('Hali ya malipo', d.paymentStatus),
                if (d.purpose != null && d.purpose!.isNotEmpty)
                  kv('Madhumuni', d.purpose!),
                if (d.zakaTagged) kv('Tag', 'Zaka'),
                if (d.funguLaKumiTagged) kv('Tag', 'Fungu la kumi'),
                pw.SizedBox(height: 18),
                pw.Text(
                  'Risiti hii itakusaidia kuhifadhi michango yako kwa kodi, ripoti za CSR, au kumbukumbu za kidini.',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );
    return doc.save();
  }

  Future<void> _printOrSavePdf() async {
    await Printing.layoutPdf(onLayout: (_) => _buildPdf());
  }

  Future<void> _sharePdf() async {
    final bytes = await _buildPdf();
    final fileName = 'risiti_${donation.receiptNumber ?? donation.id}.pdf';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
        text: 'Risiti ya Mchango wa TAJIRI',
        fileNameOverrides: [fileName],
      ),
    );
  }

  String _fmtAmount(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final rem = s.length - i;
      buf.write(s[i]);
      if (rem > 1 && rem % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return '-';
    final d = dt.toLocal();
    return '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: _kSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? _kPrimary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = donation;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Risiti ya mchango',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: _kPrimary),
            tooltip: 'Nakili namba ya risiti',
            onPressed: () {
              if (d.receiptNumber != null) {
                Clipboard.setData(ClipboardData(text: d.receiptNumber!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Namba imenakiliwa')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: _kPrimary),
            tooltip: 'Hifadhi PDF',
            onPressed: _printOrSavePdf,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: _kPrimary),
            tooltip: 'Tuma',
            onPressed: _sharePdf,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: _kAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Risiti ya Mchango wa TAJIRI',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'TZS ${_fmtAmount(d.amount)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _kPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  d.isInstitutional ? 'Mchango wa kikundi/kampuni' : 'Mchango binafsi',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
                const Divider(height: 26),
                _row('Namba ya risiti', d.receiptNumber ?? '-', bold: true),
                _row('Tarehe', _fmtDate(d.createdAt)),
                _row('Shirika lililopokea', d.orgName.isEmpty ? '#${d.orgId}' : d.orgName),
                if (d.isInstitutional) ...[
                  _row('Jina la kampuni', d.organizationName ?? '-'),
                  if (d.registrationNumber != null && d.registrationNumber!.isNotEmpty)
                    _row('Namba ya usajili', d.registrationNumber!),
                  if (d.contactPerson != null && d.contactPerson!.isNotEmpty)
                    _row('Mwasiliani', d.contactPerson!),
                  if (d.contactPhone != null && d.contactPhone!.isNotEmpty)
                    _row('Simu', d.contactPhone!),
                  if (d.contactEmail != null && d.contactEmail!.isNotEmpty)
                    _row('Barua pepe', d.contactEmail!),
                ],
                _row('Njia ya malipo', d.paymentMethod),
                if (d.paymentReference != null && d.paymentReference!.isNotEmpty)
                  _row('Rejea ya malipo', d.paymentReference!),
                _row('Hali ya malipo', d.paymentStatus,
                    valueColor: d.paymentStatus == 'paid' ? _kAccent : const Color(0xFFE67E22)),
                if (d.purpose != null && d.purpose!.isNotEmpty)
                  _row('Madhumuni', d.purpose!),
                if (d.zakaTagged || d.funguLaKumiTagged) ...[
                  const Divider(height: 26),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (d.zakaTagged) _badge('Zaka'),
                      if (d.funguLaKumiTagged) _badge('Fungu la kumi'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (d.zakaTagged || d.funguLaKumiTagged) ...[
            const SizedBox(height: 14),
            if (d.zakaTagged)
              _linkTile(
                context,
                icon: Icons.mosque_rounded,
                label: 'Iangalie kwenye Zaka',
                subtitle: 'Mchango huu umehesabiwa kwenye zaka yako',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ZakaHomePage(userId: userId)),
                ),
              ),
            if (d.zakaTagged && d.funguLaKumiTagged) const SizedBox(height: 8),
            if (d.funguLaKumiTagged)
              _linkTile(
                context,
                icon: Icons.church_rounded,
                label: 'Iangalie kwenye Fungu la Kumi',
                subtitle: 'Mchango huu umeandikishwa kwenye fungu la kumi',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FunguLaKumiHomePage(userId: userId)),
                ),
              ),
          ],
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              'Risiti hii itakusaidia kuhifadhi michango yako kwa kodi, ripoti za CSR, au kumbukumbu za kidini. Namba ya risiti pekee inatosha kuithibitisha.',
              style: TextStyle(color: _kSecondary, fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _kCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: _kPrimary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _kSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: _kSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
