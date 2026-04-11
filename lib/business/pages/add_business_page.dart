// lib/business/pages/add_business_page.dart
// Simplified business onboarding: ask if user has documents,
// if yes → collect business info, if no → offer Tajiri legal services.
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../services/business_service.dart';
import 'business_profile_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class AddBusinessPage extends StatefulWidget {
  final int userId;
  const AddBusinessPage({super.key, required this.userId});
  @override
  State<AddBusinessPage> createState() => _AddBusinessPageState();
}

class _AddBusinessPageState extends State<AddBusinessPage> {
  int _step = 0; // 0 = ask, 1 = has docs (go to profile), 2 = no docs (offer services)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text('Add Business', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _step == 0 ? _buildAskStep() : _buildNoDocsStep(),
    );
  }

  Widget _buildAskStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
          child: const Column(
            children: [
              Icon(Icons.business_center_rounded, color: Colors.white, size: 48),
              SizedBox(height: 12),
              Text(
                'Register Your Business',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Do you already have your business registration documents?',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Question: Do you have TIN, License, etc?
        const Text(
          'Do you have the following?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        _DocCheckItem(icon: Icons.numbers_rounded, label: 'TIN (Tax Identification Number)', subtitle: 'From TRA'),
        _DocCheckItem(icon: Icons.article_rounded, label: 'Certificate of Registration', subtitle: 'From BRELA'),
        _DocCheckItem(icon: Icons.badge_rounded, label: 'Business License', subtitle: 'From Municipal Council'),
        _DocCheckItem(icon: Icons.description_rounded, label: 'MEMART', subtitle: 'Memorandum & Articles of Association'),
        const SizedBox(height: 24),

        // Option 1: Yes, I have documents
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              // Go directly to business profile form
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => BusinessProfilePage(userId: widget.userId, business: null),
                ),
              );
            },
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text('Yes, I Have My Documents', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Option 2: No, I need help
        SizedBox(
          height: 52,
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _step = 2),
            icon: const Icon(Icons.help_outline_rounded, size: 20),
            label: const Text('No, I Need Help Registering', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kPrimary,
              side: const BorderSide(color: _kPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildNoDocsStep() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 10),

        // Tajiri Legal Services banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(16)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Tajiri Legal Services',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Text(
                'We can help you register your business legally in Tanzania. Our team handles everything — from BRELA to TRA to your Municipal Council.',
                style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // What we offer
        const Text('What We Handle For You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kPrimary)),
        const SizedBox(height: 12),

        _ServiceCard(
          icon: Icons.search_rounded,
          title: 'Company Name Search',
          description: 'We search and reserve your business name at BRELA.',
          price: 'From TZS 50,000',
        ),
        _ServiceCard(
          icon: Icons.article_rounded,
          title: 'Company Registration (BRELA)',
          description: 'Full registration under the Companies Act 2002. Sole proprietor, LLC, or partnership.',
          price: 'From TZS 250,000',
        ),
        _ServiceCard(
          icon: Icons.numbers_rounded,
          title: 'TIN Registration (TRA)',
          description: 'Get your Tax Identification Number from Tanzania Revenue Authority.',
          price: 'From TZS 100,000',
        ),
        _ServiceCard(
          icon: Icons.badge_rounded,
          title: 'Business License',
          description: 'Municipal Council business license for your location and sector.',
          price: 'From TZS 80,000',
        ),
        _ServiceCard(
          icon: Icons.description_rounded,
          title: 'MEMART Preparation',
          description: 'Memorandum and Articles of Association drafted by our legal team.',
          price: 'Included with registration',
        ),
        _ServiceCard(
          icon: Icons.verified_rounded,
          title: 'VAT Registration',
          description: 'Register for VAT with TRA if your revenue exceeds TZS 200M/year.',
          price: 'From TZS 100,000',
        ),
        _ServiceCard(
          icon: Icons.people_rounded,
          title: 'NSSF & WCF Registration',
          description: 'Employer registration for social security and workers compensation.',
          price: 'From TZS 50,000',
        ),
        const SizedBox(height: 16),

        // Full package
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rounded, color: Color(0xFF4CAF50), size: 22),
                  SizedBox(width: 8),
                  Text('Complete Package', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF4CAF50))),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'BRELA + TIN + License + MEMART + NSSF + WCF — everything you need to operate legally.',
                style: TextStyle(fontSize: 13, color: _kSecondary, height: 1.4),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Text('From ', style: TextStyle(fontSize: 14, color: _kSecondary)),
                  Text('TZS 450,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kPrimary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Request quote
        SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              _showQuoteRequest(context);
            },
            icon: const Icon(Icons.request_quote_rounded, size: 20),
            label: const Text('Request a Quote', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Go back to "I have docs"
        Center(
          child: TextButton(
            onPressed: () => setState(() => _step = 0),
            child: const Text('I already have my documents', style: TextStyle(color: _kSecondary)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  void _showQuoteRequest(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final bizNameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedPackage = 'complete';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Request a Quote', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _kPrimary)),
                  const SizedBox(height: 4),
                  const Text('We\'ll contact you within 24 hours.', style: TextStyle(fontSize: 13, color: _kSecondary)),
                  const SizedBox(height: 16),

                  // Package selector
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Complete Package', style: TextStyle(fontSize: 12)),
                        selected: selectedPackage == 'complete',
                        selectedColor: _kPrimary,
                        labelStyle: TextStyle(color: selectedPackage == 'complete' ? Colors.white : _kPrimary, fontWeight: FontWeight.w600),
                        onSelected: (_) => setSheetState(() => selectedPackage = 'complete'),
                      ),
                      ChoiceChip(
                        label: const Text('Individual Services', style: TextStyle(fontSize: 12)),
                        selected: selectedPackage == 'individual',
                        selectedColor: _kPrimary,
                        labelStyle: TextStyle(color: selectedPackage == 'individual' ? Colors.white : _kPrimary, fontWeight: FontWeight.w600),
                        onSelected: (_) => setSheetState(() => selectedPackage = 'individual'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Your Name', filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number', filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bizNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Proposed Business Name', filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Additional Notes (optional)', filled: true, fillColor: _kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity, height: 48,
                    child: FilledButton(
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name and phone number are required')),
                          );
                          return;
                        }
                        Navigator.pop(ctx);
                        // Store quote request info for now — backend endpoint pending
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final storage = await LocalStorageService.getInstance();
                          final token = storage.getAuthToken();
                          if (token != null) {
                            await BusinessService.requestLegalQuote(
                              token,
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              businessName: bizNameCtrl.text.trim(),
                              notes: notesCtrl.text.trim(),
                              packageType: selectedPackage,
                            );
                          }
                        } catch (_) {
                          // Silently fail — quote request is non-critical
                        }
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Quote request submitted! We\'ll contact you within 24 hours.')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _kPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Submit Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DocCheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  const _DocCheckItem({required this.icon, required this.label, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: _kSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String price;
  const _ServiceCard({required this.icon, required this.title, required this.description, required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _kCardBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: _kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kPrimary)),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.3)),
                const SizedBox(height: 6),
                Text(price, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
