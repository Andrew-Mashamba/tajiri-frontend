import 'package:flutter/material.dart';

class AppointmentsModule extends StatelessWidget {
  final int userId;
  const AppointmentsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: const Center(child: Text('Appointments module')),
    );
  }
}
