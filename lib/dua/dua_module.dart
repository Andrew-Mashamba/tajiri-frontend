// lib/dua/dua_module.dart
import 'package:flutter/material.dart';
import 'pages/dua_home_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBg = Color(0xFFFAFAFA);

class DuaModule extends StatefulWidget {
  final int userId;
  const DuaModule({super.key, required this.userId});

  @override
  State<DuaModule> createState() => _DuaModuleState();
}

class _DuaModuleState extends State<DuaModule> {
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
              Text('Loading Duas / Inapakia Dua...',
                  style: TextStyle(color: _kSecondary, fontSize: 13),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }

    return DuaHomePage(userId: widget.userId);
  }
}
