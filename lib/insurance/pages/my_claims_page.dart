// lib/insurance/pages/my_claims_page.dart
import 'package:flutter/material.dart';
import '../models/insurance_models.dart';
import '../services/insurance_service.dart';
import '../widgets/claim_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kBackground = Color(0xFFFAFAFA);

class MyClaimsPage extends StatefulWidget {
  final int userId;
  const MyClaimsPage({super.key, required this.userId});
  @override
  State<MyClaimsPage> createState() => _MyClaimsPageState();
}

class _MyClaimsPageState extends State<MyClaimsPage> {
  final InsuranceService _service = InsuranceService();
  List<InsuranceClaim> _claims = [];
  bool _isLoading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await _service.getMyClaims(widget.userId);
    if (mounted) setState(() { _isLoading = false; if (result.success) _claims = result.items; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 1,
        title: const Text('Madai Yangu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _claims.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('Hakuna madai', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                  ],
                ))
              : RefreshIndicator(
                  onRefresh: _load, color: _kPrimary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16), itemCount: _claims.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClaimCard(claim: _claims[i]),
                    ),
                  ),
                ),
    );
  }
}
