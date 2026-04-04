import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../services/local_storage_service.dart';

/// Two-Factor Authentication management screen.
/// Navigation: Settings -> Security -> Two-Factor Authentication.
class TwoFactorScreen extends StatefulWidget {
  final int currentUserId;

  const TwoFactorScreen({super.key, required this.currentUserId});

  @override
  State<TwoFactorScreen> createState() => _TwoFactorScreenState();
}

class _TwoFactorScreenState extends State<TwoFactorScreen> {
  static const Color _background = Color(0xFFFAFAFA);
  static const Color _primaryText = Color(0xFF1A1A1A);
  static const Color _secondaryText = Color(0xFF666666);

  bool _isLoading = true;
  bool _is2FAEnabled = false;
  bool _isProcessing = false;

  // After enabling: QR code URL and recovery codes
  String? _qrCodeUrl;
  List<String> _recoveryCodes = [];
  String? _error;

  // Confirmation code input
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final storage = await LocalStorageService.getInstance();
    return storage.getAuthToken();
  }

  Future<void> _checkStatus() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final resp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/2fa/status?user_id=${widget.currentUserId}'),
        headers: token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers,
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _is2FAEnabled = data['enabled'] == true;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            // Default to disabled if status check fails
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to check 2FA status';
        });
      }
    }
  }

  Future<void> _enable2FA() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/2fa/enable'),
        headers: {
          ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _qrCodeUrl = data['qr_code_url'] as String?;
            _recoveryCodes = (data['recovery_codes'] as List?)
                    ?.map((c) => c.toString())
                    .toList() ??
                [];
            _isProcessing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _error = 'Failed to enable 2FA';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _confirm2FA() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/2fa/confirm'),
        headers: {
          ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': widget.currentUserId,
          'code': code,
        }),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          setState(() {
            _is2FAEnabled = true;
            _qrCodeUrl = null;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('2FA enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _error = 'Invalid code. Please try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _disable2FA() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: const Text(
          'Are you sure you want to disable two-factor authentication? This will reduce your account security.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disable', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final resp = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/2fa/disable'),
        headers: {
          ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (resp.statusCode == 200) {
        if (mounted) {
          setState(() {
            _is2FAEnabled = false;
            _recoveryCodes = [];
            _qrCodeUrl = null;
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('2FA disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _error = 'Failed to disable 2FA';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  Future<void> _regenerateRecoveryCodes() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });
    try {
      final token = await _getToken();
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/2fa/recovery-codes'),
        headers: {
          ...(token != null ? ApiConfig.authHeaders(token) : ApiConfig.headers),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': widget.currentUserId}),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (mounted) {
          setState(() {
            _recoveryCodes = (data['recovery_codes'] as List?)
                    ?.map((c) => c.toString())
                    .toList() ??
                [];
            _isProcessing = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _error = 'Failed to regenerate codes';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _primaryText,
        title: const Text('Two-Factor Authentication'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primaryText))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card
                    _buildStatusCard(),
                    const SizedBox(height: 16),

                    if (_error != null) ...[
                      _buildErrorBanner(),
                      const SizedBox(height: 16),
                    ],

                    // QR code setup (after enable, before confirm)
                    if (_qrCodeUrl != null) ...[
                      _buildQRSetupSection(),
                      const SizedBox(height: 16),
                    ],

                    // Recovery codes section
                    if (_recoveryCodes.isNotEmpty) ...[
                      _buildRecoveryCodesSection(),
                      const SizedBox(height: 16),
                    ],

                    // Actions
                    if (!_is2FAEnabled && _qrCodeUrl == null)
                      _buildActionButton(
                        icon: Icons.security,
                        label: 'Enable 2FA',
                        onPressed: _isProcessing ? null : _enable2FA,
                      ),

                    if (_is2FAEnabled) ...[
                      _buildActionButton(
                        icon: Icons.refresh,
                        label: 'Regenerate Recovery Codes',
                        onPressed: _isProcessing ? null : _regenerateRecoveryCodes,
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        icon: Icons.lock_open,
                        label: 'Disable 2FA',
                        isDestructive: true,
                        onPressed: _isProcessing ? null : _disable2FA,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _is2FAEnabled
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _is2FAEnabled ? Icons.verified_user : Icons.shield_outlined,
              color: _is2FAEnabled ? Colors.green : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _is2FAEnabled ? 'Enabled' : 'Disabled',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _is2FAEnabled ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _is2FAEnabled
                      ? 'Your account is protected with two-factor authentication'
                      : 'Add an extra layer of security to your account',
                  style: const TextStyle(fontSize: 13, color: _secondaryText),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(fontSize: 13, color: Colors.red.shade900),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRSetupSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Setup',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc.)',
            style: TextStyle(fontSize: 13, color: _secondaryText),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          if (_qrCodeUrl != null)
            Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Image.network(
                  _qrCodeUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text(
                      'QR code unavailable',
                      style: TextStyle(color: _secondaryText, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Enter the 6-digit code from your authenticator app:',
            style: TextStyle(fontSize: 13, color: _primaryText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: '000000',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              counterText: '',
            ),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 8,
              color: _primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: FilledButton(
                onPressed: _isProcessing ? null : _confirm2FA,
                style: FilledButton.styleFrom(
                  backgroundColor: _primaryText,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify & Enable'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCodesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recovery Codes',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _primaryText),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: _recoveryCodes.join('\n')));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recovery codes copied')),
                  );
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, size: 16, color: _secondaryText),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(fontSize: 13, color: _secondaryText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Save these codes in a safe place. You can use them to access your account if you lose your authenticator.',
            style: TextStyle(fontSize: 12, color: _secondaryText),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recoveryCodes.map((code) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  color: _primaryText,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : _primaryText;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isProcessing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryText),
                  )
                else
                  Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
