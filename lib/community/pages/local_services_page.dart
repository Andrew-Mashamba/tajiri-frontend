// lib/community/pages/local_services_page.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';
import '../widgets/service_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class LocalServicesPage extends StatefulWidget {
  final int userId;
  const LocalServicesPage({super.key, required this.userId});
  @override
  State<LocalServicesPage> createState() => _LocalServicesPageState();
}

class _LocalServicesPageState extends State<LocalServicesPage> {
  final CommunityService _service = CommunityService();
  List<LocalService> _services = [];
  bool _isLoading = true;
  LocalServiceType? _filterType;

  final double _latitude = -6.7924;
  final double _longitude = 39.2083;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    final result = await _service.getNearbyServices(
      latitude: _latitude,
      longitude: _longitude,
      type: _filterType,
    );
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) _services = result.items;
      });
    }
  }

  Future<void> _callNumber(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Huduma za Karibu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Nearby Services',
                style: TextStyle(fontSize: 12, color: _kSecondary)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _kPrimary,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Zote',
                    isSelected: _filterType == null,
                    onTap: () {
                      _filterType = null;
                      _loadServices();
                    },
                  ),
                  const SizedBox(width: 8),
                  ...LocalServiceType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: type.displayName,
                        isSelected: _filterType == type,
                        onTap: () {
                          _filterType = type;
                          _loadServices();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _kPrimary))
                : _services.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.location_off_rounded,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('Hakuna huduma zilizopatikana',
                                style: TextStyle(color: _kSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadServices,
                        color: _kPrimary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _services.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => ServiceCard(
                            service: _services[i],
                            onCall: _services[i].phone != null
                                ? () => _callNumber(_services[i].phone!)
                                : null,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _kSecondary,
          ),
        ),
      ),
    );
  }
}
