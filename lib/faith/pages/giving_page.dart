// lib/faith/pages/giving_page.dart
import 'package:flutter/material.dart';
import '../models/faith_models.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kCardBg = Color(0xFFFFFFFF);

class GivingPage extends StatelessWidget {
  final int userId;
  final FaithType faith;

  const GivingPage({
    super.key,
    required this.userId,
    required this.faith,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              faith == FaithType.islam ? 'Zaka na Sadaka' : 'Zaka na Sadaka',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              faith == FaithType.islam
                  ? 'Zakat & Sadaqah'
                  : 'Tithe & Offering',
              style: const TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.volunteer_activism_rounded,
                    size: 32, color: _kPrimary),
                const SizedBox(height: 12),
                Text(
                  faith == FaithType.islam
                      ? '"Hakuna siku ambayo waja wanaamka asubuhi ila malaika wawili washuke..."'
                      : '"Kila mtu na atoe kama alivyokusudia moyoni mwake..."',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: _kPrimary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  faith == FaithType.islam
                      ? '— Hadith (Bukhari & Muslim)'
                      : '— 2 Wakorintho 9:7',
                  style: const TextStyle(fontSize: 12, color: _kSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          if (faith == FaithType.islam) ...[
            _GivingOption(
              icon: Icons.calculate_rounded,
              title: 'Zaka (Zakat)',
              subtitle: '2.5% ya mali',
              description: 'Wajibu wa kila Muislamu mwenye mali ya kutosha.',
              onTap: () => _navigateToWallet(context, 'zakat'),
            ),
            const SizedBox(height: 10),
            _GivingOption(
              icon: Icons.favorite_rounded,
              title: 'Sadaka (Sadaqah)',
              subtitle: 'Kiasi chochote',
              description: 'Michango ya hiari kwa ajili ya Mwenyezi Mungu.',
              onTap: () => _navigateToWallet(context, 'sadaqah'),
            ),
            const SizedBox(height: 10),
            _GivingOption(
              icon: Icons.restaurant_rounded,
              title: 'Zakat al-Fitr',
              subtitle: 'Mwishoni mwa Ramadhani',
              description: 'Sadaka ya wajibu kabla ya Eid al-Fitr.',
              onTap: () => _navigateToWallet(context, 'zakat_fitr'),
            ),
          ] else ...[
            _GivingOption(
              icon: Icons.church_rounded,
              title: 'Zaka (Tithe)',
              subtitle: '10% ya mapato',
              description: 'Sehemu ya kumi ya mapato yako kwa Kanisa.',
              onTap: () => _navigateToWallet(context, 'tithe'),
            ),
            const SizedBox(height: 10),
            _GivingOption(
              icon: Icons.favorite_rounded,
              title: 'Sadaka (Offering)',
              subtitle: 'Kiasi chochote',
              description: 'Michango ya hiari kwa kanisa lako.',
              onTap: () => _navigateToWallet(context, 'offering'),
            ),
            const SizedBox(height: 10),
            _GivingOption(
              icon: Icons.people_rounded,
              title: 'Misaada ya Jamii',
              subtitle: 'Community Support',
              description: 'Saidia maskini, yatima, na wajane.',
              onTap: () => _navigateToWallet(context, 'community'),
            ),
          ],

          const SizedBox(height: 24),
          // Link to Michango
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: GestureDetector(
              onTap: () {
                // Navigate to Michango campaigns
                Navigator.pop(context);
              },
              child: const Row(
                children: [
                  Icon(Icons.campaign_rounded, size: 24, color: _kPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Michango ya Jamii',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        Text(
                          'Tazama michango hai ya kidini',
                          style: TextStyle(fontSize: 12, color: _kSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 16, color: _kSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToWallet(BuildContext context, String type) {
    // Navigate to wallet transfer screen with pre-filled giving type
    Navigator.pushNamed(context, '/home');
  }
}

class _GivingOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final VoidCallback onTap;

  const _GivingOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _kPrimary, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: _kSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: _kSecondary),
          ],
        ),
      ),
    );
  }
}
