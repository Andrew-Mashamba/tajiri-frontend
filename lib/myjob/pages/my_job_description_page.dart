// lib/myjob/pages/my_job_description_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../l10n/app_strings_scope.dart';
import '../models/myjob_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);
const Color _kCard = Color(0xFFFFFFFF);

class MyJobDescriptionPage extends StatelessWidget {
  final String token;
  final JobDescription jd;

  const MyJobDescriptionPage({
    super.key,
    required this.token,
    required this.jd,
  });

  Widget _section(String title, Widget child) => Card(
        color: _kCard, elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: _kSecondary)),
            const SizedBox(height: 10),
            child,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final sw = AppStringsScope.of(context)?.isSwahili ?? false;
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: Text(sw ? 'Maelezo ya Kazi' : 'Job Description',
            style: const TextStyle(
                color: _kPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: jd.roleSummary.isEmpty && jd.responsibilities.isEmpty
          ? Center(
              child: Text(
                  sw ? 'Maelezo yako ya kazi hayajawekwa bado.'
                     : "Your job description hasn't been set yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: Colors.grey.shade500)),
            )
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (jd.roleSummary.isNotEmpty)
                _section(
                  sw ? 'Muhtasari wa Nafasi' : 'Role Summary',
                  Text(jd.roleSummary,
                      style: const TextStyle(fontSize: 14, color: _kPrimary)),
                ),

              if (jd.responsibilities.isNotEmpty)
                _section(
                  sw ? 'Majukumu' : 'Responsibilities',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(jd.responsibilities.length, (i) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('${i + 1}. ${jd.responsibilities[i]}',
                              style: const TextStyle(fontSize: 14, color: _kPrimary)),
                        )),
                  ),
                ),

              if (jd.reportingTo.isNotEmpty)
                _section(
                  sw ? 'Anaripoti Kwa' : 'Reporting To',
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(jd.reportingTo,
                        style: const TextStyle(fontSize: 13, color: _kPrimary)),
                  ),
                ),

              if (jd.updatedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 16),
                  child: Text(
                      '${sw ? 'Imesasishwa' : 'Last updated'}: ${DateFormat('dd MMM yyyy').format(jd.updatedAt!)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ),
            ]),
    );
  }
}
