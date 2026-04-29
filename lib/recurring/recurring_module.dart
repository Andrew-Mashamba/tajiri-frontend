import 'package:flutter/material.dart';

class RecurringModule extends StatelessWidget {
  final int userId;
  const RecurringModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Recurring module')),
    );
  }
}
