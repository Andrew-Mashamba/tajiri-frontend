// lib/rc/rc_module.dart
import 'package:flutter/material.dart';
import 'services/rc_service.dart';
import 'models/rc_models.dart';
import 'pages/rc_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RcModule extends StatefulWidget {
  final int userId;
  final int regionId;
  const RcModule({
    super.key,
    required this.userId,
    required this.regionId,
  });

  @override
  State<RcModule> createState() => _RcModuleState();
}

class _RcModuleState extends State<RcModule> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';

  Region? _region;
  RegionalCommissioner? _rc;

  final _service = RcService();

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
        _service.getRegion(widget.regionId),
        _service.getRcProfile(widget.regionId),
      ]);

      final rResult = results[0] as SingleResult<Region>;
      final rcResult = results[1] as SingleResult<RegionalCommissioner>;

      _region = rResult.data;
      _rc = rcResult.data;

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

    return RcHomePage(
      userId: widget.userId,
      regionId: widget.regionId,
      region: _region,
      rc: _rc,
    );
  }
}
