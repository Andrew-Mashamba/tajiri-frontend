import 'package:flutter/material.dart';

class CallsModule extends StatelessWidget {
  final int userId;
  const CallsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calls')),
      body: const Center(child: Text('Calls module')),
    );
  }
}
