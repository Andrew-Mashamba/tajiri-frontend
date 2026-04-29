import 'package:flutter/material.dart';

import '../../consultations/models/consultation.dart';
import '../../consultations/pages/book_consultation_page.dart';
import '../../tajirika/models/tajirika_models.dart';

/// Spec §7 entry: lib/legal_gpt/pages/book_legal_consultation_page.dart
///
/// Three-tier base fee per spec line 717: text TZS 5,000 (anchor) — derived
/// fees: text 1,000 (15min), video 2,500 (15min)... Multiplier scales from
/// [ConsultationMode.baseMultiplier] × duration.
class BookLegalConsultationPage extends StatelessWidget {
  final int userId;
  final TajirikaPartner? preselectedPartner;

  const BookLegalConsultationPage({
    super.key,
    required this.userId,
    this.preselectedPartner,
  });

  @override
  Widget build(BuildContext context) {
    return BookConsultationPage(
      userId: userId,
      vertical: ConsultationVertical.legal,
      skillFilter: const ['legal'],
      baseFeeTzs: 25000, // anchor at video 30-min equivalent; tiers scale around it
      preselectedPartner: preselectedPartner,
    );
  }
}
