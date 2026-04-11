// lib/career/pages/job_detail_page.dart
import 'package:flutter/material.dart';
import '../models/career_models.dart';
import '../services/career_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class JobDetailPage extends StatelessWidget {
  final JobListing job;
  final int userId;
  const JobDetailPage({super.key, required this.job, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg, foregroundColor: _kPrimary, elevation: 0,
        actions: [
          IconButton(icon: Icon(job.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded), onPressed: () => CareerService().saveJob(job.id)),
          IconButton(icon: const Icon(Icons.share_rounded), onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inashiriki... / Sharing...')));
          }),
        ],
      ),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          // Company logo
          Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12),
                image: job.companyLogo != null ? DecorationImage(image: NetworkImage(job.companyLogo!), fit: BoxFit.cover) : null,
              ),
              child: job.companyLogo == null ? const Icon(Icons.business_rounded, size: 28, color: _kSecondary) : null,
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(job.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kPrimary)),
              const SizedBox(height: 2),
              Text(job.company, style: const TextStyle(fontSize: 14, color: _kSecondary)),
            ])),
          ]),
          const SizedBox(height: 16),
          // Info chips
          Wrap(spacing: 8, runSpacing: 8, children: [
            _chip(Icons.location_on_rounded, job.location),
            _chip(Icons.work_rounded, job.type.displayName),
            if (job.salary != null) _chip(Icons.payments_rounded, job.salary!),
            _chip(Icons.timer_rounded, job.daysUntilDeadline),
          ]),
          const SizedBox(height: 20),
          // Description
          const Text('Maelezo / Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
          const SizedBox(height: 8),
          Text(job.description, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.6)),
          const SizedBox(height: 20),
          // Requirements
          if (job.requirements.isNotEmpty) ...[
            const Text('Mahitaji / Requirements', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _kPrimary)),
            const SizedBox(height: 8),
            ...job.requirements.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: _kSecondary)),
                const SizedBox(width: 10),
                Expanded(child: Text(r, style: const TextStyle(fontSize: 14, color: _kSecondary, height: 1.4))),
              ]),
            )),
            const SizedBox(height: 20),
          ],
          if (!job.hasApplied && !job.isExpired) FilledButton(
            onPressed: () async {
              final result = await CareerService().applyForJob(jobId: job.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.success ? 'Ombi limetumwa!' : 'Imeshindwa kutuma')));
              }
            },
            style: FilledButton.styleFrom(backgroundColor: _kPrimary, minimumSize: const Size.fromHeight(48)),
            child: const Text('Omba Kazi / Apply'),
          ),
          if (job.hasApplied) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
              SizedBox(width: 10),
              Text('Umeomba tayari', style: TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600)),
            ]),
          ),
          if (job.isExpired) Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [
              Icon(Icons.event_busy_rounded, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text('Muda umepita / Expired', style: TextStyle(fontSize: 14, color: Colors.red)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: _kPrimary),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: _kPrimary)),
      ]),
    );
  }
}
