// lib/alerts/pages/family_checkin_page.dart
import 'package:flutter/material.dart';
import '../../services/local_storage_service.dart';
import '../models/alerts_models.dart';
import '../services/alerts_service.dart';
import '../widgets/checkin_card.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class FamilyCheckInPage extends StatefulWidget {
  final int userId;
  const FamilyCheckInPage({super.key, required this.userId});
  @override
  State<FamilyCheckInPage> createState() => _FamilyCheckInPageState();
}

class _FamilyCheckInPageState extends State<FamilyCheckInPage> {
  List<FamilyCheckIn> _checkIns = [];
  bool _isLoading = true;
  bool _isSwahili = true;

  @override
  void initState() {
    super.initState();
    _isSwahili =
        (LocalStorageService.instanceSync?.getLanguageCode() ?? 'sw') == 'sw';
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final r = await AlertsService.getFamilyCheckIns();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (r.success) _checkIns = r.items;
    });
    if (!r.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(r.message ??
            (_isSwahili
                ? 'Imeshindwa kupakia hali'
                : 'Failed to load check-ins')),
      ));
    }
  }

  Future<void> _requestCheckIn() async {
    final r = await AlertsService.requestFamilyCheckIn();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.success
          ? (_isSwahili ? 'Ombi limetumwa!' : 'Request sent!')
          : (r.message ?? 'Error')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        title: Text(
            _isSwahili ? 'Hali ya Familia' : 'Family Check-in',
            style: const TextStyle(
                color: _kPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: _kPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded),
            tooltip:
                _isSwahili ? 'Omba hali' : 'Request check-in',
            onPressed: _requestCheckIn,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(strokeWidth: 2, color: _kPrimary))
          : RefreshIndicator(
              onRefresh: _load,
              color: _kPrimary,
              child: _checkIns.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(children: [
                          const Icon(Icons.family_restroom_rounded,
                              size: 48, color: _kSecondary),
                          const SizedBox(height: 12),
                          Text(
                            _isSwahili
                                ? 'Hakuna hali zilizosajiliwa'
                                : 'No check-ins yet',
                            style: const TextStyle(
                                fontSize: 14, color: _kSecondary),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _requestCheckIn,
                            icon: const Icon(Icons.send_rounded, size: 16),
                            label: Text(_isSwahili
                                ? 'Omba Hali'
                                : 'Request Check-in'),
                            style: FilledButton.styleFrom(
                                backgroundColor: _kPrimary),
                          ),
                        ]),
                      ),
                    ])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _checkIns.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => CheckInCard(
                          checkIn: _checkIns[i], isSwahili: _isSwahili),
                    ),
            ),
    );
  }
}
