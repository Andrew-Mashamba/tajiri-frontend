// lib/career/widgets/job_card.dart
import 'package:flutter/material.dart';
import '../models/career_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class JobCard extends StatelessWidget {
  final JobListing job;
  final VoidCallback? onTap;
  const JobCard({super.key, required this.job, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: job.isExpired ? Colors.red.shade100 : Colors.grey.shade200),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10),
              image: job.companyLogo != null ? DecorationImage(image: NetworkImage(job.companyLogo!), fit: BoxFit.cover) : null,
            ),
            child: job.companyLogo == null ? const Icon(Icons.business_rounded, size: 24, color: _kSecondary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(job.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(job.company, style: const TextStyle(fontSize: 12, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(4)),
                child: Text(job.type.displayName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: _kPrimary)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on_rounded, size: 13, color: _kSecondary),
              const SizedBox(width: 2),
              Expanded(child: Text(job.location, style: const TextStyle(fontSize: 11, color: _kSecondary), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              if (job.salary != null) ...[
                Text(job.salary!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _kPrimary)),
                const Spacer(),
              ],
              Text(job.daysUntilDeadline, style: TextStyle(fontSize: 11, color: job.isExpired ? Colors.red : _kSecondary)),
            ]),
          ])),
        ]),
      ),
    );
  }
}
