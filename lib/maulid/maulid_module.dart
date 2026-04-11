// lib/maulid/maulid_module.dart
import 'package:flutter/material.dart';
import 'pages/maulid_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class MaulidModule extends StatefulWidget {
  final int userId;
  const MaulidModule({super.key, required this.userId});

  @override
  State<MaulidModule> createState() => _MaulidModuleState();
}

class _MaulidModuleState extends State<MaulidModule> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _loading = false);
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
              Text('Loading Maulid / Inapakia Maulid...',
                  style: TextStyle(color: _kSecondary, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }

    return MaulidHomePage(userId: widget.userId);
  }
}
