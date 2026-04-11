// lib/ofisi_mtaa/pages/service_catalog_page.dart
import 'package:flutter/material.dart';
import '../models/ofisi_mtaa_models.dart';
import '../services/ofisi_mtaa_service.dart';
import '../widgets/service_tile.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class ServiceCatalogPage extends StatefulWidget {
  final int mtaaId;
  const ServiceCatalogPage({super.key, required this.mtaaId});

  @override
  State<ServiceCatalogPage> createState() => _ServiceCatalogPageState();
}

class _ServiceCatalogPageState extends State<ServiceCatalogPage> {
  List<ServiceCatalog> _services = [];
  bool _loading = true;

  final _service = OfisiMtaaService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getServiceCatalog(widget.mtaaId);
    if (mounted) {
      setState(() {
        _services = result.items;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: _kPrimary),
        title: const Text(
          'Huduma za Mtaa',
          style: TextStyle(
            color: _kPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _kPrimary))
          : _services.isEmpty
              ? const Center(
                  child: Text(
                    'Hakuna huduma kwa sasa',
                    style: TextStyle(color: _kSecondary, fontSize: 14),
                  ),
                )
              : RefreshIndicator(
                  color: _kPrimary,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _services.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ServiceTile(
                        service: _services[i],
                        onApply: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Omba huduma / Apply for service - coming soon')),
                          );
                        },
                      ),
                    ),
                  ),
                ),
    );
  }
}
