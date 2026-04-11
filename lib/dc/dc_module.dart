// lib/dc/dc_module.dart
import 'package:flutter/material.dart';
import 'services/dc_service.dart';
import 'models/dc_models.dart';
import 'pages/dc_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DcModule extends StatefulWidget {
  final int userId;
  final int districtId;
  const DcModule({
    super.key,
    required this.userId,
    required this.districtId,
  });

  @override
  State<DcModule> createState() => _DcModuleState();
}

class _DcModuleState extends State<DcModule> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';

  District? _district;
  DistrictCommissioner? _dc;
  List<EmergencyAlert> _alerts = [];

  final _service = DcService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    try {
      final results = await Future.wait([
        _service.getDistrict(widget.districtId),
        _service.getDcProfile(widget.districtId),
        _service.getAlerts(widget.districtId),
      ]);

      final dResult = results[0] as SingleResult<District>;
      final dcResult = results[1] as SingleResult<DistrictCommissioner>;
      final aResult = results[2] as PaginatedResult<EmergencyAlert>;

      _district = dResult.data;
      _dc = dcResult.data;
      _alerts = aResult.items;

      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              SizedBox(height: 16),
              Text(
                'Inapakia... / Loading...',
                style: TextStyle(color: _kSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: _kSecondary),
                const SizedBox(height: 16),
                Text(
                  _errorMsg.replaceAll('Exception: ', ''),
                  style: const TextStyle(color: _kSecondary, fontSize: 14),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _load,
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  child: const Text('Jaribu Tena / Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DcHomePage(
      userId: widget.userId,
      districtId: widget.districtId,
      district: _district,
      dc: _dc,
      alerts: _alerts,
    );
  }
}
