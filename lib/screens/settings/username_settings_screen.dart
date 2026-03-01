import 'package:flutter/material.dart';
import '../../services/profile_service.dart';

/// Username (@handle) management screen.
/// Navigation: Home → Profile → Settings → Username field (STORY-14).
/// Design: DOCS/DESIGN.md (touch targets 48dp min, colors).
class UsernameSettingsScreen extends StatefulWidget {
  final int currentUserId;

  const UsernameSettingsScreen({super.key, required this.currentUserId});

  @override
  State<UsernameSettingsScreen> createState() => _UsernameSettingsScreenState();
}

class _UsernameSettingsScreenState extends State<UsernameSettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  bool _saving = false;
  String? _currentUsername;
  String? _loadError;

  static const int _minLength = 3;
  static const int _maxLength = 30;
  static final RegExp _validHandle = RegExp(r'^[a-zA-Z0-9_]+$');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final result = await _profileService.getProfile(
      userId: widget.currentUserId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.success && result.profile != null) {
        _currentUsername = result.profile!.username;
        _controller.text = _currentUsername ?? '';
      } else {
        _loadError = result.message ?? 'Imeshindwa kupakia wasifu';
      }
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weka jina la mtumiaji';
    }
    final trimmed = value.trim();
    if (trimmed.length < _minLength) {
      return 'Jina lazima liwe angalau $_minLength herufi';
    }
    if (trimmed.length > _maxLength) {
      return 'Jina si zaidi ya $_maxLength herufi';
    }
    if (!_validHandle.hasMatch(trimmed)) {
      return 'Tumia herufi, nambari na alama ya chini (_) tu';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _controller.text.trim();
    if (raw == _currentUsername) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jina halijabadilika')),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    final result = await _profileService.updateUsername(
      userId: widget.currentUserId,
      username: raw,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jina limehifadhiwa: @${result.username ?? raw}')),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Imeshindwa kuhifadhi jina'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Jina la Mtumiaji'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1A1A1A)),
              )
            : _loadError != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF666666)),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: TextButton(
                            onPressed: _loadProfile,
                            child: const Text('Jaribu tena'),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Jina lako la mtumiaji (@handle) litaonekana kwenye wasifu na machapisho.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _controller,
                            decoration: InputDecoration(
                              labelText: 'Jina la mtumiaji',
                              hintText: 'mfano_jina',
                              prefixText: '@ ',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            textCapitalization: TextCapitalization.none,
                            autocorrect: false,
                            validator: _validateUsername,
                            enabled: !_saving,
                            minLines: 1,
                            maxLength: _maxLength,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Herufi na nambari na _ tu, $_minLength–$_maxLength herufi.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _save(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A1A1A),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Hifadhi'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}
