import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/registration_models.dart';
import '../../../services/user_service.dart';
import '../../../utils/handle_validator.dart';

/// Chapter 0, Screen 3 — Public handle (username) creation.
///
/// Shows up to 4 suggested handles derived from the user's name + DOB and
/// lets them type a custom one. Format is validated locally; uniqueness is
/// confirmed against the backend with debounced live checks.
class HandleStep extends StatefulWidget {
  final RegistrationState state;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const HandleStep({
    super.key,
    required this.state,
    required this.onNext,
    this.onBack,
  });

  @override
  State<HandleStep> createState() => _HandleStepState();
}

enum _HandleStatus {
  idle,
  invalid,
  checking,
  available,
  taken,
  endpointMissing,
  networkError,
}

class _HandleStepState extends State<HandleStep> {
  static const Color _primary = Color(0xFF1A1A1A);
  static const Color _secondary = Color(0xFF666666);
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _fieldBg = Colors.white;
  static const Color _border = Color(0xFFE0E0E0);
  static const Color _successGreen = Color(0xFF2E7D32);
  static const Color _errorRed = Color(0xFFE53935);

  final TextEditingController _ctrl = TextEditingController();
  final UserService _userService = UserService();

  Timer? _debounce;
  int _checkSeq = 0;

  _HandleStatus _status = _HandleStatus.idle;
  String? _localErrorKey;
  String? _serverMessage;
  List<String> _suggestions = const [];

  @override
  void initState() {
    super.initState();
    _suggestions = HandleValidator.suggest(
      firstName: widget.state.firstName ?? '',
      middleName: widget.state.middleName,
      lastName: widget.state.lastName ?? '',
      dob: widget.state.dateOfBirth,
    );
    if (widget.state.handle != null && widget.state.handle!.isNotEmpty) {
      _ctrl.text = widget.state.handle!;
      _onChanged(widget.state.handle!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // ── Validation pipeline ────────────────────────────────────────────────────

  void _onChanged(String raw) {
    _debounce?.cancel();
    final cleaned = raw.trim().toLowerCase();
    if (cleaned.isEmpty) {
      setState(() {
        _status = _HandleStatus.idle;
        _localErrorKey = null;
        _serverMessage = null;
      });
      return;
    }

    final local = HandleValidator.validate(cleaned);
    if (!local.isValid) {
      setState(() {
        _status = _HandleStatus.invalid;
        _localErrorKey = local.errorKey;
        _serverMessage = null;
      });
      return;
    }

    setState(() {
      _status = _HandleStatus.checking;
      _localErrorKey = null;
      _serverMessage = null;
    });

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkAvailability(cleaned);
    });
  }

  Future<void> _checkAvailability(String handle) async {
    final mySeq = ++_checkSeq;
    final result = await _userService.checkHandleAvailability(handle);
    if (!mounted || mySeq != _checkSeq) return;

    if (result.endpointMissing) {
      setState(() {
        _status = _HandleStatus.endpointMissing;
        _serverMessage = result.message;
      });
      return;
    }

    if (result.available) {
      setState(() {
        _status = _HandleStatus.available;
        _serverMessage = null;
      });
    } else if (result.message != null && result.message!.isNotEmpty &&
        result.message != 'Imeshindwa kuwasiliana na seva') {
      setState(() {
        _status = _HandleStatus.taken;
        _serverMessage = result.message;
      });
    } else {
      setState(() {
        _status = _HandleStatus.networkError;
        _serverMessage = result.message;
      });
    }
  }

  void _useSuggestion(String s) {
    _ctrl.text = s;
    _ctrl.selection = TextSelection.fromPosition(
      TextPosition(offset: s.length),
    );
    _onChanged(s);
  }

  void _handleNext() {
    if (_status != _HandleStatus.available) return;
    widget.state.handle = _ctrl.text.trim().toLowerCase();
    widget.onNext();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  String? get _errorMessage {
    switch (_status) {
      case _HandleStatus.invalid:
        return HandleValidator.errorSwahili(_localErrorKey);
      case _HandleStatus.taken:
        return _serverMessage ?? 'Jina hili limechukuliwa, chagua lingine';
      case _HandleStatus.endpointMissing:
      case _HandleStatus.networkError:
        return _serverMessage ?? 'Imeshindwa kuthibitisha. Jaribu tena.';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chagua jina la utumiaji',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hili litakuwa anwani yako TAJIRI. Tumia herufi ndogo, '
                      'namba, na _ pekee.',
                      style: TextStyle(
                        fontSize: 14,
                        color: _secondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildHandleField(),
                    const SizedBox(height: 8),
                    _buildStatusLine(),

                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Mapendekezo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _secondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _suggestions
                            .map((s) => _buildSuggestionChip(s))
                            .toList(),
                      ),
                    ],

                    const SizedBox(height: 24),
                    _buildRules(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHandleField() {
    final hasError = _status == _HandleStatus.invalid ||
        _status == _HandleStatus.taken ||
        _status == _HandleStatus.endpointMissing ||
        _status == _HandleStatus.networkError;

    return Container(
      decoration: BoxDecoration(
        color: _fieldBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasError
              ? _errorRed.withValues(alpha: 0.6)
              : (_status == _HandleStatus.available
                  ? _successGreen
                  : _border),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14, right: 4),
            child: Text(
              '@',
              style: TextStyle(
                fontSize: 18,
                color: _secondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Jina la utumiaji',
              child: TextField(
                controller: _ctrl,
                onChanged: _onChanged,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(20),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                ],
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                style: const TextStyle(fontSize: 16, color: _primary),
                decoration: const InputDecoration(
                  hintText: 'jina_lako',
                  hintStyle:
                      TextStyle(color: Color(0xFFBBBBBB), fontSize: 15),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildTrailingIcon(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingIcon() {
    switch (_status) {
      case _HandleStatus.checking:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_secondary),
          ),
        );
      case _HandleStatus.available:
        return const Icon(Icons.check_circle, color: _successGreen, size: 22);
      case _HandleStatus.invalid:
      case _HandleStatus.taken:
      case _HandleStatus.endpointMissing:
      case _HandleStatus.networkError:
        return const Icon(Icons.error_outline, color: _errorRed, size: 22);
      case _HandleStatus.idle:
        return const SizedBox(width: 22, height: 22);
    }
  }

  Widget _buildStatusLine() {
    final err = _errorMessage;
    if (err != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, top: 4),
        child: Text(
          err,
          style: const TextStyle(color: _errorRed, fontSize: 12),
        ),
      );
    }
    if (_status == _HandleStatus.available) {
      return const Padding(
        padding: EdgeInsets.only(left: 4, top: 4),
        child: Text(
          'Inapatikana',
          style: TextStyle(
            color: _successGreen,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }

  Widget _buildSuggestionChip(String suggestion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _useSuggestion(suggestion),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '@$suggestion',
            style: const TextStyle(
              fontSize: 13,
              color: _primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRules() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sheria',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _secondary,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '• Herufi 3–20\n'
            '• Anza na herufi (a-z)\n'
            '• Tumia a-z, 0-9, na _ pekee\n'
            '• Hakuna nafasi au herufi kubwa\n'
            '• Halibadiliki kwa urahisi baadaye',
            style: TextStyle(fontSize: 12, color: _secondary, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    final enabled = _status == _HandleStatus.available;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: enabled ? 1.0 : 0.45,
        child: FilledButton(
          onPressed: enabled ? _handleNext : null,
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            disabledBackgroundColor: _primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Endelea',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
