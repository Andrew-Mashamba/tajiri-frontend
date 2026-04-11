// lib/ofisi_mtaa/ofisi_mtaa_module.dart
import 'package:flutter/material.dart';
import 'services/ofisi_mtaa_service.dart';
import 'models/ofisi_mtaa_models.dart';
import 'pages/ofisi_mtaa_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class OfisiMtaaModule extends StatefulWidget {
  final int userId;
  final int mtaaId;
  const OfisiMtaaModule({
    super.key,
    required this.userId,
    required this.mtaaId,
  });

  @override
  State<OfisiMtaaModule> createState() => _OfisiMtaaModuleState();
}

class _OfisiMtaaModuleState extends State<OfisiMtaaModule> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';

  List<MtaaOfficial> _officials = [];
  List<CommunityNotice> _notices = [];

  final _service = OfisiMtaaService();

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
        _service.getOfficials(widget.mtaaId),
        _service.getNotices(widget.mtaaId),
      ]);

      final oResult = results[0] as PaginatedResult<MtaaOfficial>;
      final nResult = results[1] as PaginatedResult<CommunityNotice>;

      _officials = oResult.items;
      _notices = nResult.items;

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

    return OfisiMtaaHomePage(
      userId: widget.userId,
      mtaaId: widget.mtaaId,
      officials: _officials,
      notices: _notices,
    );
  }
}
