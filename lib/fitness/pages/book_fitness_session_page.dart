import 'package:flutter/material.dart';
import '../../appointments/models/appointment.dart';
import '../../appointments/pages/book_appointment_page.dart';
import '../../tajirika/models/tajirika_models.dart';

class BookFitnessSessionPage extends StatelessWidget {
  final int userId;
  final TajirikaPartner? preselectedPartner;
  final PartnerProduct? preselectedProduct;

  const BookFitnessSessionPage({
    super.key,
    required this.userId,
    this.preselectedPartner,
    this.preselectedProduct,
  });

  @override
  Widget build(BuildContext context) {
    return BookAppointmentPage(
      userId: userId,
      vertical: AppointmentVertical.fitness,
      skillFilter: const ['personalTraining'],
      allowRecurring: true,
      preselectedPartner: preselectedPartner,
      preselectedProduct: preselectedProduct,
    );
  }
}
