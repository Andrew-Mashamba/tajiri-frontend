
import 'package:flutter/material.dart';
import 'sajiriKikoba.dart';
import 'searchForKikoba.dart';
import '../services/local_storage_service.dart';
// import 'login.dart'; // removed — auth handled by TAJIRI bridge

class searchOrcreate extends StatefulWidget {
  final String? message;

  const searchOrcreate({super.key, this.message});

  @override
  _SearchOrCreateState createState() => _SearchOrCreateState();
}

class _SearchOrCreateState extends State<searchOrcreate>
    with SingleTickerProviderStateMixin {
  bool get _isSwahili =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Header Section
              SizedBox(
                height: MediaQuery.of(context).size.height * (widget.message != null ? 0.32 : 0.28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    const Text(
                      "VIKOBA",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSwahili ? "Chagua hatua yako ya kwanza" : "Choose your first step",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show message if provided
                    if (widget.message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFB74D),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: Color(0xFFF57C00),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.message!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Content Section (Flexible with scroll support)
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildMinimalButton(
                          icon: Icons.add_business_rounded,
                          title: _isSwahili ? "Sajiri kikoba kipya" : "Register new group",
                          subtitle: _isSwahili ? "Anza kikoba chako cha kwanza" : "Start your first savings group",
                          onPressed: () => _navigateToPage(sajiriKikoba()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildMinimalButton(
                          icon: Icons.search_rounded,
                          title: _isSwahili ? "Tafuta kikoba" : "Find a group",
                          subtitle: _isSwahili ? "Jiunge na kikoba kilichopo" : "Join an existing savings group",
                          onPressed: () => _navigateToPage(const SearchBarx()),
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildMinimalButton(
                          icon: Icons.login_rounded,
                          title: _isSwahili ? "Ingia" : "Sign In",
                          subtitle: _isSwahili ? "Ingia kwenye akaunti yako" : "Sign in to your account",
                          onPressed: () { if (Navigator.of(context).canPop()) Navigator.of(context).pop(); },
                        ),
                      ),
                      // Bottom Padding
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 72, maxHeight: 80),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF999999),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToPage(Widget page) {
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }
}