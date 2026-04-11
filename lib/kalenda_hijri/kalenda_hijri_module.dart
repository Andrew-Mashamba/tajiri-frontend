// lib/kalenda_hijri/kalenda_hijri_module.dart
import 'package:flutter/material.dart';
import 'pages/kalenda_hijri_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class KalendaHijriModule extends StatefulWidget {
  final int userId;
  const KalendaHijriModule({super.key, required this.userId});

  @override
  State<KalendaHijriModule> createState() => _KalendaHijriModuleState();
}

class _KalendaHijriModuleState extends State<KalendaHijriModule> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      setState(() { _loading = true; _hasError = false; });
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = e.toString();
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
              Text('Loading Hijri Calendar / Inapakia Kalenda Hijri...',
                  style: TextStyle(color: _kSecondary, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
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
                const Icon(Icons.error_outline_rounded, size: 48, color: _kSecondary),
                const SizedBox(height: 16),
                Text(_errorMsg.replaceAll('Exception: ', ''),
                    style: const TextStyle(color: _kSecondary, fontSize: 14),
                    textAlign: TextAlign.center, maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _init,
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  child: const Text('Retry / Jaribu Tena'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return KalendaHijriHomePage(userId: widget.userId);
  }
}
