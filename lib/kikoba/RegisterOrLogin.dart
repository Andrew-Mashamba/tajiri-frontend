import 'package:flutter/material.dart';
import 'package:vicoba/login.dart';
import 'package:vicoba/registerMobileNumber.dart';
import 'mwalikwaLogin.dart';

class RegisterOrLogin extends StatefulWidget {
  const RegisterOrLogin({super.key});

  @override
  _RegisterOrLoginState createState() => _RegisterOrLoginState();
}

class _RegisterOrLoginState extends State<RegisterOrLogin> with TickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _navigateToPage(Widget page) async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                // Header Section - Fixed height to prevent overflow
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const SizedBox(height: 24),
                      
                      // Company Name
                      const Text(
                        "VICOBA",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      const Text(
                        "Mfumo wa kuendesha kikoba",
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      

                    ],
                  ),
                ),
                
                // Spacer for flexible spacing
                const SizedBox(height: 24),
                
                // Buttons Section - Using Flexible to prevent overflow
                Flexible(
                  child: Column(
                    children: [
                      _buildMinimalButton(
                        icon: Icons.login_rounded,
                        title: "INGIA",
                        subtitle: "Kama ulifuta app au umebadilisha simu",
                        onPressed: () => _navigateToPage(const LoginScreen()),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildMinimalButton(
                        icon: Icons.mail_outline_rounded,
                        title: "MUALIKO",
                        subtitle: "Kama umealikwa na kikundi",
                        onPressed: () => _navigateToPage(const mwalikwaLogin()),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildMinimalButton(
                        icon: Icons.person_add_alt_1_rounded,
                        title: "JIUNGE",
                        subtitle: "Ni mara yako ya kwanza? Jisajili hapa",
                        onPressed: () => _navigateToPage(const registerMobileNumber()),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Loading Indicator
                      if (_isLoading)
                        Column(
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Inafungua ukurasa...",
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Bottom padding
                const SizedBox(height: 24),
              ],
            ),
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
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: _isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
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
                
                // Text content - Using Expanded to prevent overflow
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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Flexible(
                        child: Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF666666),
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Arrow icon
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
}
