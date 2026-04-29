import 'package:flutter/material.dart';

class EngagementsModule extends StatelessWidget {
  final int userId;
  const EngagementsModule({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Engagements')),
      body: const Center(child: Text('Engagements module')),
    );
  }
}
