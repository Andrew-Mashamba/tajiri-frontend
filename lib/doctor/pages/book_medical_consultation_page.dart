import 'package:flutter/material.dart';

import '../../consultations/models/consultation.dart';
import '../../consultations/pages/book_consultation_page.dart';
import '../../tajirika/models/tajirika_models.dart';

/// Spec §7 entry: lib/doctor/pages/book_medical_consultation_page.dart
class BookMedicalConsultationPage extends StatelessWidget {
  final int userId;
  final TajirikaPartner? preselectedPartner;

  const BookMedicalConsultationPage({
    super.key,
    required this.userId,
    this.preselectedPartner,
  });

  @override
  Widget build(BuildContext context) {
    return BookConsultationPage(
      userId: userId,
      vertical: ConsultationVertical.medical,
      skillFilter: const ['medical', 'nursing', 'pharmacy'],
      baseFeeTzs: 25000,
      preselectedPartner: preselectedPartner,
    );
  }
}
