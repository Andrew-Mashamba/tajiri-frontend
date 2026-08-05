import 'package:flutter/material.dart';

const Color _kBg = Color(0xFFFAFAFA);
const Color _kText = Color(0xFF1A1A1A);

/// Entry to global messaging (`docs/shop/shop_backend_api.md` chat).
class SellerInboxScreen extends StatelessWidget {
  const SellerInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Messages', style: TextStyle(color: _kText)),
        backgroundColor: _kBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Buyer and seller chats use the main TAJIRI inbox.',
                style: TextStyle(color: Color(0xFF444444), fontSize: 15),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kText,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, '/messages');
                  },
                  child: const Text('Open inbox'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
