// lib/barozi_wangu/barozi_wangu_module.dart
import 'package:flutter/material.dart';
import 'services/barozi_wangu_service.dart';
import 'models/barozi_wangu_models.dart';
import 'pages/barozi_wangu_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class BaroziWanguModule extends StatefulWidget {
  final int userId;
  final int wardId;
  const BaroziWanguModule({
    super.key,
    required this.userId,
    required this.wardId,
  });

  @override
  State<BaroziWanguModule> createState() => _BaroziWanguModuleState();
}

class _BaroziWanguModuleState extends State<BaroziWanguModule> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';

  Councillor? _councillor;
  List<WardIssue> _issues = [];

  final _service = BaroziWanguService();

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
        _service.getCouncillor(widget.wardId),
        _service.getIssues(widget.wardId),
      ]);

      final cResult = results[0] as SingleResult<Councillor>;
      final iResult = results[1] as PaginatedResult<WardIssue>;

      _councillor = cResult.data;
      _issues = iResult.items;

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

    return BaroziWanguHomePage(
      userId: widget.userId,
      wardId: widget.wardId,
      councillor: _councillor,
      issues: _issues,
    );
  }
}
