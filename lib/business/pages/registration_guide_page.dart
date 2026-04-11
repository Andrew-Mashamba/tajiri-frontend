// lib/business/pages/registration_guide_page.dart
// Interactive step-by-step guide for registering a business in Tanzania.
import 'package:flutter/material.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);
const Color _kCardBg = Color(0xFFFFFFFF);

class RegistrationGuidePage extends StatefulWidget {
  const RegistrationGuidePage({super.key});

  @override
  State<RegistrationGuidePage> createState() => _RegistrationGuidePageState();
}

class _RegistrationGuidePageState extends State<RegistrationGuidePage> {
  final Set<int> _completedSteps = {};

  final _steps = <_RegStep>[
    _RegStep(
      number: 1,
      title: 'BRELA Registration',
      subtitle: 'Business Registrations and Licensing Agency',
      description:
          'Register your business through the BRELA Online Registration System (ORS). '
          'Start by searching for a business name, then proceed with full registration.',
      documents: [
        'Application Form',
        'National ID (NIDA) copy',
        'Passport photos (2)',
        'Business office address',
        'Memorandum & Articles of Association (for companies)',
      ],
      cost: 'TZS 50,000 - 440,000',
      costDetail:
          'Sole Proprietor: TZS 50,000 | Company: TZS 150,000 - 440,000 depending on capital',
      guidance:
          'Visit: https://ors.brela.go.tz\n'
          '1. Search business name (Name Search) - TZS 5,000\n'
          '2. Reserve name (Name Reservation) - 30 days\n'
          '3. Fill registration forms online\n'
          '4. Pay registration fee\n'
          '5. Receive Certificate of Registration',
    ),
    _RegStep(
      number: 2,
      title: 'TIN Number (TRA)',
      subtitle: 'Tanzania Revenue Authority',
      description:
          'Get your Tax Identification Number (TIN) from TRA. '
          'This is mandatory for every business in Tanzania.',
      documents: [
        'Certificate of Registration (BRELA)',
        'National ID (NIDA)',
        'Proof of Address',
        'Passport photo',
      ],
      cost: 'Free',
      costDetail: 'No charge — free service',
      guidance:
          'Visit: https://www.tra.go.tz\n'
          '1. Log in to TRA Online Portal\n'
          '2. Fill TIN application form\n'
          '3. Upload required documents\n'
          '4. Wait for verification (1-3 days)\n'
          '5. Receive TIN Certificate\n\n'
          'TIN format: XXX-XXX-XXX',
    ),
    _RegStep(
      number: 3,
      title: 'Business License',
      subtitle: 'Municipal / District Council',
      description:
          'Obtain a business license from your Municipal or District Council. '
          'This license must be renewed annually.',
      documents: [
        'Certificate of Registration',
        'TIN Certificate',
        'Proof of Business Location (lease agreement)',
        'National ID',
        'Passport photos',
      ],
      cost: 'TZS 20,000 - 100,000+',
      costDetail:
          'Varies by business type and location. Small business: ~TZS 20,000. Large business: TZS 100,000+',
      guidance:
          '1. Visit your local Council office\n'
          '2. Fill license application form\n'
          '3. Submit documents\n'
          '4. Pay license fee\n'
          '5. Receive license — expires December 31 each year\n'
          '6. Renew before year end',
    ),
    _RegStep(
      number: 4,
      title: 'VAT Registration',
      subtitle: 'Value Added Tax — TRA',
      description:
          'Register for VAT if your annual business revenue exceeds TZS 200 million. '
          'VAT rate is 18%.',
      documents: [
        'TIN Certificate',
        'Certificate of Registration',
        'Financial Statements',
        'Business Address Proof',
      ],
      cost: 'Free',
      costDetail:
          'Registration is free, but business must collect and remit 18% VAT to TRA',
      guidance:
          '1. Visit TRA or register online\n'
          '2. Fill VAT application form\n'
          '3. Submit documents\n'
          '4. TRA will conduct initial audit\n'
          '5. Receive VRN (VAT Registration Number)\n'
          '6. Start issuing VAT invoices\n\n'
          'Note: VAT must be paid by the 20th of each month',
    ),
    _RegStep(
      number: 5,
      title: 'NSSF Registration',
      subtitle: 'National Social Security Fund',
      description:
          'Register as an employer with NSSF. Mandatory for any business with employees. '
          'Employer contributes 10% and employee contributes 10% of salary.',
      documents: [
        'Certificate of Registration',
        'TIN Certificate',
        'Employee list',
        'Employee ID copies',
      ],
      cost: 'Free (Registration)',
      costDetail:
          'Registration is free. Contributions: Employer 10% + Employee 10% = 20% of gross salary',
      guidance:
          '1. Visit your nearest NSSF office\n'
          '2. Fill employer registration form\n'
          '3. Register all employees\n'
          '4. Contributions due monthly (by the 7th)\n'
          '5. Submit monthly reports online',
    ),
    _RegStep(
      number: 6,
      title: 'WCF Registration',
      subtitle: 'Workers Compensation Fund',
      description:
          'Register with the Workers Compensation Fund. '
          'Employer pays 0.5% of total salaries for workplace accident insurance.',
      documents: [
        'Certificate of Registration',
        'TIN Certificate',
        'Employer NSSF Number',
        'Employee list with salaries',
      ],
      cost: 'Free (Registration)',
      costDetail:
          'Registration is free. Contributions: 0.5% of total salaries, monthly',
      guidance:
          '1. Visit WCF office or register online\n'
          '2. Fill registration form\n'
          '3. Contributions due monthly\n'
          '4. Non-payment may result in penalties\n\n'
          'Visit: https://www.wcf.go.tz',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kCardBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Business Registration Steps',
            style: TextStyle(
                color: _kPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _kPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Your Progress',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text(
                      '${_completedSteps.length} / ${_steps.length}',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _steps.isEmpty
                        ? 0
                        : _completedSteps.length / _steps.length,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Steps
          ..._steps.map((step) => _buildStepCard(step)),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStepCard(_RegStep step) {
    final isCompleted = _completedSteps.contains(step.number);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.shade200 : Colors.grey.shade100,
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          leading: GestureDetector(
            onTap: () {
              setState(() {
                if (isCompleted) {
                  _completedSteps.remove(step.number);
                } else {
                  _completedSteps.add(step.number);
                }
              });
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.shade600
                    : _kPrimary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20)
                    : Text(
                        '${step.number}',
                        style: const TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
              ),
            ),
          ),
          title: Text(
            step.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isCompleted ? Colors.green.shade700 : _kPrimary,
              decoration:
                  isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            ),
          ),
          subtitle: Text(step.subtitle,
              style: const TextStyle(fontSize: 11, color: _kSecondary)),
          children: [
            // Description
            Text(step.description,
                style: const TextStyle(fontSize: 13, color: _kSecondary,
                    height: 1.5)),
            const SizedBox(height: 14),

            // Cost
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_rounded,
                      size: 18, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cost: ${step.cost}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700)),
                        Text(step.costDetail,
                            style: TextStyle(
                                fontSize: 11, color: Colors.blue.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Documents needed
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.folder_rounded, size: 16, color: _kPrimary),
                      SizedBox(width: 6),
                      Text('Required Documents',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _kPrimary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ...step.documents.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('  \u2022 ',
                                style: TextStyle(
                                    fontSize: 12, color: _kSecondary)),
                            Expanded(
                              child: Text(doc,
                                  style: const TextStyle(
                                      fontSize: 12, color: _kSecondary)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Guidance
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_rounded,
                          size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Text('How To',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(step.guidance,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade800,
                          height: 1.5)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Mark complete button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    if (isCompleted) {
                      _completedSteps.remove(step.number);
                    } else {
                      _completedSteps.add(step.number);
                    }
                  });
                },
                icon: Icon(
                    isCompleted
                        ? Icons.undo_rounded
                        : Icons.check_circle_rounded,
                    size: 18),
                label: Text(
                    isCompleted ? 'Undo' : 'Mark as Complete'),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isCompleted ? _kSecondary : Colors.green.shade700,
                  side: BorderSide(
                      color: isCompleted
                          ? Colors.grey.shade300
                          : Colors.green.shade700),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegStep {
  final int number;
  final String title;
  final String subtitle;
  final String description;
  final List<String> documents;
  final String cost;
  final String costDetail;
  final String guidance;

  const _RegStep({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.documents,
    required this.cost,
    required this.costDetail,
    required this.guidance,
  });
}
