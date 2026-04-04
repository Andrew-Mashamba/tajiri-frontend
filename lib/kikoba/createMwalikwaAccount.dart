import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'HttpService.dart';
import 'OfflineDatabase.dart';
import 'Userx.dart';
import 'DataStore.dart';
import 'profileImage.dart';
import 'start.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _accentColor = Color(0xFF999999);

class createMwalikwaAccount extends StatelessWidget {
  const createMwalikwaAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VICOBA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: _primaryBg,
        fontFamily: 'Roboto',
      ),
      home: const _CreateAccountPage(),
    );
  }
}

class _CreateAccountPage extends StatefulWidget {
  const _CreateAccountPage();

  @override
  State<_CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<_CreateAccountPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _pinControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _pinFocusNodes = List.generate(4, (_) => FocusNode());

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Pre-fill name if available from DataStore
    if (DataStore.currentUserName != null &&
        DataStore.currentUserName!.isNotEmpty) {
      _nameController.text = DataStore.currentUserName!;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _pin => _pinControllers.map((c) => c.text).join();
  bool get _isPinComplete => _pin.length == 4;
  bool get _isFormValid =>
      _nameController.text.trim().length >= 2 && _isPinComplete;

  void _onPinDigitChanged(int index, String value) {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (value.isNotEmpty && index < 3) {
      _pinFocusNodes[index + 1].requestFocus();
    }
  }

  void _onPinKeyPressed(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _pinControllers[index].text.isEmpty &&
        index > 0) {
      _pinFocusNodes[index - 1].requestFocus();
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
  }

  Future<void> _submitForm() async {
    // Validate name
    if (_nameController.text.trim().length < 2) {
      _showError('Tafadhali andika jina lako kamili');
      return;
    }

    // Validate PIN
    if (!_isPinComplete) {
      _showError('Tafadhali weka namba ya siri (tarakimu 4)');
      return;
    }

    if (_pin == "1234" || _pin == "0000") {
      _showError('Namba ya siri ni rahisi sana, chagua nyingine');
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final result = await HttpService.updateUserData(
        _pin.trim(),
        _nameController.text.trim(),
      );

      if (!mounted) return;

      if (result.trim() == "success") {
        // Update local data
        DataStore.userPresent = true;
        DataStore.currentUserName = _nameController.text.trim();

        final user = Userx(
          id: "3",
          phone: DataStore.userNumber ?? '',
          name: DataStore.currentUserName ?? '',
          userId: DataStore.currentUserId ?? '',
          userStatus: '',
          remotepostImage: '',
          is_expired: '',
          password: '',
          otp: '',
          localpostImage: '',
          udid: '',
          create_at: '',
          reg_date: '',
        );

        await OfflineDatabase().setCurrentUser2(user);

        if (!mounted) return;

        // Navigate to main app
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const start()),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Kuna tatizo la mtandao, tafadhali jaribu tena');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Tatizo limetokea, jaribu tena');
    }
  }

  void _openImagePicker() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => profileImage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Header
                const Text(
                  'Kamilisha Akaunti',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Weka taarifa zako ili ukamilishe usajili',
                  style: TextStyle(
                    fontSize: 14,
                    color: _secondaryText,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Profile Image
                GestureDetector(
                  onTap: _openImagePicker,
                  child: _buildProfileImage(),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _openImagePicker,
                  child: const Text(
                    'Badilisha picha',
                    style: TextStyle(
                      color: _secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Name Input Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jina lako kamili',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 16,
                          color: _primaryText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Mfano: Juma Hassan',
                          hintStyle: TextStyle(
                            color: _accentColor,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: _secondaryText,
                          ),
                          filled: true,
                          fillColor: _primaryBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _primaryText,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // PIN Input Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Namba ya siri (PIN)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _primaryText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tarakimu 4 utakazotumia kuingia',
                        style: TextStyle(
                          fontSize: 12,
                          color: _secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return _buildPinField(index);
                        }),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Error Message
                if (_hasError)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Material(
                    color: _isFormValid ? _primaryText : _accentColor,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: _isFormValid && !_isLoading ? _submitForm : null,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Kamilisha Usajili',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final size = MediaQuery.of(context).size;
    final hasImage = DataStore.profileImage != null &&
        DataStore.profileImage != "noimage" &&
        DataStore.profileImage!.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _cardBg,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: hasImage
                ? Image.file(
                    File(DataStore.profileImage!),
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  )
                : Container(
                    color: _primaryBg,
                    child: const Icon(
                      Icons.person,
                      size: 48,
                      color: _accentColor,
                    ),
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primaryText,
              shape: BoxShape.circle,
              border: Border.all(color: _cardBg, width: 2),
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPinField(int index) {
    final bool hasValue = _pinControllers[index].text.isNotEmpty;

    return SizedBox(
      width: 56,
      height: 64,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onPinKeyPressed(index, event),
        child: TextField(
          controller: _pinControllers[index],
          focusNode: _pinFocusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          obscureText: true,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primaryText,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            filled: true,
            fillColor: hasValue ? _primaryBg : _cardBg,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError
                    ? Colors.red.shade300
                    : (hasValue ? _primaryText : _accentColor),
                width: hasValue ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _hasError ? Colors.red.shade400 : _primaryText,
                width: 2,
              ),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          onChanged: (value) => _onPinDigitChanged(index, value),
        ),
      ),
    );
  }
}
