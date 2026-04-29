import 'package:flutter/material.dart';

import '../../consultations/models/consultation.dart';
import '../../consultations/pages/book_consultation_page.dart';
import '../../tajirika/models/tajirika_models.dart';

/// Spec §7 entry: lib/business/pages/book_business_consultation_page.dart
class BookBusinessConsultationPage extends StatelessWidget {
  final int userId;
  final TajirikaPartner? preselectedPartner;

  const BookBusinessConsultationPage({
    super.key,
    required this.userId,
    this.preselectedPartner,
  });

  @override
  Widget build(BuildContext context) {
    return BookConsultationPage(
      userId: userId,
      vertical: ConsultationVertical.business,
      skillFilter: const ['accounting', 'taxAdvisory', 'businessConsulting', 'hrConsulting', 'careerCoaching'],
      baseFeeTzs: 30000,
      preselectedPartner: preselectedPartner,
    );
  }
}
