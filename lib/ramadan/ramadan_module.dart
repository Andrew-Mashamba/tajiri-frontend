// lib/ramadan/ramadan_module.dart
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import 'services/ramadan_service.dart';
import 'models/ramadan_models.dart';
import 'pages/ramadan_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class RamadanModule extends StatefulWidget {
  final int userId;
  const RamadanModule({super.key, required this.userId});

  @override
  State<RamadanModule> createState() => _RamadanModuleState();
}

class _RamadanModuleState extends State<RamadanModule> {
  bool _loading = true;
  bool _hasError = false;
  String _errorMsg = '';
  RamadanOverview? _overview;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      setState(() { _loading = true; _hasError = false; });
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please log in again / Tafadhali ingia tena.');
      }

      final service = RamadanService();
      final result = await service.getOverview(
        token: token,
        latitude: -6.7924,
        longitude: 39.2083,
      );
      _overview = result.data;
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
              Text('Loading Ramadan / Inapakia Ramadan...',
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

    return RamadanHomePage(userId: widget.userId, overview: _overview);
  }
}
