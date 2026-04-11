// lib/nida/pages/office_finder_page.dart
import 'package:flutter/material.dart';
import '../models/nida_models.dart';
import '../services/nida_service.dart';
import '../widgets/office_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OfficeFinderPage extends StatefulWidget {
  const OfficeFinderPage({super.key});
  @override
  State<OfficeFinderPage> createState() => _OfficeFinderPageState();
}

class _OfficeFinderPageState extends State<OfficeFinderPage> {
  List<NidaOffice> _offices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await NidaService.getOffices();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success) {
        _offices = result.items;
      } else {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('Ofisi za NIDA',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: _kSecondary)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: _kPrimary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _offices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => OfficeCard(office: _offices[i]),
                  ),
                ),
    );
  }
}
