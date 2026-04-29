import 'package:flutter/material.dart';

import '../../l10n/app_strings_scope.dart';
import '../widgets/hair_try_on_viewport.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);
const Color _kBackground = Color(0xFFFAFAFA);

/// Full-screen virtual hair try-on (same engine as the home hero viewport).
class VirtualHairTryOnPage extends StatelessWidget {
  final int userId;

  const VirtualHairTryOnPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final s = AppStringsScope.of(context)!;
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          s.hairNailsVirtualTryOnTitle,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        backgroundColor: _kBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: _kPrimary),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                s.hairNailsVirtualTryOnDisclaimer,
                style: const TextStyle(fontSize: 12, color: _kSecondary, height: 1.35),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: HairTryOnViewport(
                userId: userId,
                mode: HairTryOnViewportMode.fullscreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
