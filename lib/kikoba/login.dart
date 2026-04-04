import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passcode_screen/circle.dart';
import 'package:passcode_screen/keyboard.dart';
import 'package:passcode_screen/passcode_screen.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:vicoba/main.dart';
import 'package:vicoba/vicobaList.dart';
import 'package:vicoba/appColor.dart';


import 'HttpService.dart';
import 'OfflineDatabase.dart';
import 'Userx.dart';
import 'DataStore.dart';
import 'fcm_service.dart';

const storedPasscode = '123456';

/// LoginScreen - Use this for navigation within an existing MaterialApp
class LoginScreen extends StatelessWidget {
  final String? phoneNumber;

  const LoginScreen({super.key, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return MyHomePage(title: 'Ingia', phoneNumber: phoneNumber);
  }
}

/// login - Legacy class that wraps in MaterialApp (use LoginScreen instead for navigation)
class login extends StatelessWidget {
  final String? phoneNumber;

  const login({super.key, this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIKUNDI',
    theme: ThemeData(
      primaryColor: AppColors.primary,
      hintColor: AppColors.background,
    ),


      home: MyHomePage(title: 'Ingia', phoneNumber: phoneNumber),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.phoneNumber});

  final String title;
  final String? phoneNumber;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController numberController = TextEditingController();
  bool _statusView = false;

  final formKey = GlobalKey<FormState>();

  StreamController<ErrorAnimationType>? errorController;

  TextEditingController textEditingController = TextEditingController();

  String pin = "0000";

  final StreamController<bool> _verificationNotifier =
      StreamController<bool>.broadcast();

  bool isAuthenticated = false;

  String? _errorText;

  bool isValid = false;

  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    //await Firebase.initializeApp();
    _errorText = null;
    
    // Pre-fill phone number if provided
    if (widget.phoneNumber != null) {
      // Remove +255 prefix if present for display
      String displayNumber = widget.phoneNumber!;
      if (displayNumber.startsWith('+255')) {
        displayNumber = displayNumber.substring(4);
      }
      numberController.text = displayNumber;
    }
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
              // Header Section - Fixed height to prevent overflow
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                      "Ingia kwenye akaunti yako",
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content Section - Using Flexible to prevent overflow
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Namba ya simu",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity( 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: numberController,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: '712444576',
                            hintStyle: const TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 16,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.phone_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            prefixText: '+255 ',
                            prefixStyle: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            suffixText: 'TZ',
                            suffixStyle: const TextStyle(
                              color: const Color(0xFF666666),
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                          ),
                          onChanged: (text) {
                            setState(() {
                              _errorText = null;
                            });
                            processPhoneNumber(text);
                          },
                          maxLength: 9,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_errorText != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFE53935).withOpacity( 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFE53935),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: const TextStyle(
                                    color: Color(0xFFE53935),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : () {
                            if (numberController.text.trim().isNotEmpty) {
                              processPhoneNumber(numberController.text);
                            } else {
                              setState(() {
                                _errorText = "Tafadhali ingiza namba ya simu";
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A1A1A),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF1A1A1A).withValues(alpha: 0.7),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'INGIA',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void processPhoneNumber(String value) {
    String validityMessage;
    if (value.trim().toLowerCase() == "0") {
      numberController.clear();
    } else {
      validityMessage = validateMobile(value)!;
      if (validityMessage != "ok") {
        setState(() {
          //_status = 'verificationFailed\n';
          //_buttonText = 'Jaribu Tena';
          _statusView = false;
        });
      } else {
        print('GOOD GOOD');

        // For testing purposes, allow common test numbers to proceed directly
        List<String> testNumbers = ['712444576', '692410353', '123456789'];
        if (testNumbers.contains(numberController.text.trim())) {
          _showLockScreen(
            context,
            opaque: false,
            cancelButton: const Text(
              'Sitisha',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
              semanticsLabel: 'Sitisha',
            ),
          );
          return;
        }

        // Show loading indicator
        setState(() => _isVerifying = true);

        HttpService.verifyNumber(numberController.text).then((String result) {
          if (!mounted) return;
          setState(() => _isVerifying = false);

          print('Login response: $result');

          try {
            // Parse JSON response
            final jsonResponse = json.decode(result);

            if (jsonResponse is Map<String, dynamic> &&
                jsonResponse.containsKey('userId') &&
                jsonResponse['userId'] != null) {

              // Store user data
              DataStore.currentUserId = jsonResponse['userId'];
              DataStore.userNumber = jsonResponse['phone'] ?? numberController.text;
              if (jsonResponse['name'] != null) {
                DataStore.currentUserName = jsonResponse['name'];
              }

              print('User authenticated successfully: ${jsonResponse['userId']}');

              _showLockScreen(
                context,
                opaque: false,
                cancelButton: const Text(
                  'Sitisha',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                  semanticsLabel: 'Sitisha',
                ),
              );
            } else {
              setState(() {
                _errorText =
                    "Namba ulioingiza sio sahihi, tafadhali rudia. Kama hauja jiunga, jiunge kwanza.";
              });
            }
          } catch (e) {
            print('Error parsing login response: $e');
            // Fallback: check for string "1" for backward compatibility
            if (result.trim() == "1") {
              _showLockScreen(
                context,
                opaque: false,
                cancelButton: const Text(
                  'Sitisha',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                  semanticsLabel: 'Sitisha',
                ),
              );
            } else {
              setState(() {
                _errorText =
                    "Namba ulioingiza sio sahihi, tafadhali rudia. Kama hauja jiunga, jiunge kwanza.";
              });
            }
          }
        }).catchError((error) {
          print('Error verifying number: $error');
          if (mounted) {
            setState(() {
              _isVerifying = false;
              if (error.toString().contains('TimeoutException') ||
                  error.toString().contains('timed out')) {
                _errorText = "Mfumo haujajibu kwa wakati. Tafadhali jaribu tena.";
              } else if (error.toString().contains('Network') ||
                         error.toString().contains('Connection')) {
                _errorText = "Hakuna muunganisho wa mtandao. Angalia muunganisho wako.";
              } else {
                _errorText = "Kuna tatizo la kiufundi. Tafadhali jaribu tena baadaye.";
              }
            });
          }
        });
      }
      print('Validity message: $validityMessage');
    }
  }

  String? validateMobile(String value) {
    if (value.length != 9) {
      return 'Namba ya simu lazima iwe na tarakimu 9';
    } else {
      return "ok";
    }
  }

  Future<bool> _submitPhoneNumber() async {
    try {
      String result =
          await HttpService.login("+255${numberController.text}", pin.trim());
      print("THE RESULT FFFFFF");
      print(result);

      // Handle both old string responses and new JSON responses
      try {
        // Try to parse as JSON first
        final jsonResponse = json.decode(result);
        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('error')) {
            // Handle error responses
            print('Login error: ${jsonResponse['message'] ?? 'Unknown error'}');
            return false;
          } else if (jsonResponse.containsKey('userId') || jsonResponse.containsKey('id')) {
            // Successful login with user data
            print("THE RESULT USER SET UP");
            print("🔍 API Response fields:");
            jsonResponse.forEach((key, value) {
              if (key == 'vicoba') {
                print("  $key: ${value is List ? 'Array with ${value.length} items' : value}");
              } else {
                print("  $key: $value");
              }
            });
            Userx user = Userx.fromJson(jsonResponse);
            await OfflineDatabase().setCurrentUser2(user);
            DataStore.currentUserIdid = user.id;
            DataStore.currentUserName = user.name;
            DataStore.userNumber = user.phone;
            DataStore.currentUserReg_date = user.reg_date;
            DataStore.currentUserId = user.userId;
            DataStore.currentUserUserStatus = user.userStatus;
            DataStore.currentUserIdUdid = user.udid;
            DataStore.currentUserIdOtp = user.otp;
            DataStore.currentKikobaIs_expired = user.is_expired;
            DataStore.currentUserLocalpostImage = user.localpostImage;
            DataStore.currentUserIdRemotepostImage = user.remotepostImage;
            DataStore.currentUserCreate_at = user.create_at;
            return true;
          }
        }
      } catch (e) {
        // If JSON parsing fails, fall back to string comparison for backwards compatibility
        print('JSON parsing failed, using string comparison: $e');
      }

      // Fall back to old string-based error handling
      if (result.trim() == "norecord") {
        return false;
      } else if (result.trim() == "wrongpassword") {
        return false;
      } else if (result.trim() == "Network Error") {
        return false;
      } else if (result.trim() == "Device Offline") {
        return false;
      } else if (result.trim() == "Server Error") {
        return false;
      } else {
        // Try to parse as user data for old API responses
        try {
          print("THE RESULT USER SET UP (fallback)");
          Map valueMap = jsonDecode(result);
          Userx user = Userx.fromJson(valueMap);
          await OfflineDatabase().setCurrentUser2(user);
          DataStore.currentUserIdid = user.id;
          DataStore.currentUserName = user.name;
          DataStore.userNumber = user.phone;
          DataStore.currentUserReg_date = user.reg_date;
          DataStore.currentUserId = user.userId;
          DataStore.currentUserUserStatus = user.userStatus;
          DataStore.currentUserIdUdid = user.udid;
          DataStore.currentUserIdOtp = user.otp;
          DataStore.currentKikobaIs_expired = user.is_expired;
          DataStore.currentUserLocalpostImage = user.localpostImage;
          DataStore.currentUserIdRemotepostImage = user.remotepostImage;
          DataStore.currentUserCreate_at = user.create_at;
          return true;
        } catch (e) {
          print('Failed to parse user data: $e');
          return false;
        }
      }
    } on Exception catch (ex) {
      print('Query error: $ex');
      return false;
    }
  }

  Widget iconx() {
    return Image.asset('assets/lock.jpg');
  }

  _showLockScreen(
    BuildContext context, {
    required bool opaque,
    CircleUIConfig? circleUIConfig,
    KeyboardUIConfig? keyboardUIConfig,
    required Widget cancelButton,
    List<String>? digits,
  }) {
    Navigator.push(
        context,
        PageRouteBuilder(
          opaque: opaque,
          pageBuilder: (context, animation, secondaryAnimation) =>
              Scaffold(
                backgroundColor: Colors.black.withOpacity( 0.8),
                body: SafeArea(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height - 
                               MediaQuery.of(context).padding.top - 
                               MediaQuery.of(context).padding.bottom,
                        child: PasscodeScreen(
                          title: const Text(
                            'Ingiza PIN yako',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          circleUIConfig: circleUIConfig,
                          keyboardUIConfig: keyboardUIConfig,
                          passwordEnteredCallback: _onPasscodeEntered,
                          cancelButton: cancelButton,
                          deleteButton: const Text(
                            'Futa',
                            style: TextStyle(
                              fontSize: 16,
                              color: const Color(0xFF666666),
                              fontWeight: FontWeight.w500,
                            ),
                            semanticsLabel: 'Futa',
                          ),
                          shouldTriggerVerification: _verificationNotifier.stream,
                          backgroundColor: Colors.transparent,
                          cancelCallback: _onPasscodeCancelled,
                          digits: digits,
                          passwordDigits: 4,
                          bottomWidget: _buildPasscodeRestoreButton(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ));
  }

  _onPasscodeEntered(String enteredPasscode) {
    pin = enteredPasscode;

    _submitPhoneNumber().then((isValid) async {
      if (isValid) {
        print("HAPAAAAAAA - PIN verified successfully");

        // NOTE: Vikoba list is now fetched asynchronously in VikobaListPage
        // This makes login instant - user sees skeleton loading while data loads

        // Update FCM token after successful login (non-blocking)
        FCMService.updateFCMToken().then((_) {
          print("FCM token update completed");
        }).catchError((error) {
          print("FCM token update failed: $error");
          // Don't block login if FCM update fails
        });

        // Don't notify the passcode_screen - it causes navigation conflicts
        // Instead, close the stream and navigate directly
        _verificationNotifier.close();

        if (mounted) {
          setState(() {
            isAuthenticated = isValid;
          });

          // Pop the passcode screen first, then navigate to VikobaListPage
          // Use a small delay to ensure the passcode screen is fully closed
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) {
              // Pop the passcode screen
              Navigator.of(context).pop();

              // Navigate to VikobaListPage - it will handle data loading with skeleton
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const VikobaListPage()),
                  (Route<dynamic> route) => false);
            }
          });
        }
      } else {
        // Only notify on failure to show error animation
        _verificationNotifier.add(false);
      }
    });
  }

  _onPasscodeCancelled() {
    // Use mounted check to ensure widget is still active
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  void dispose() {
    _verificationNotifier.close();
    super.dispose();
  }

  _buildPasscodeRestoreButton() => Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10.0, top: 20.0),
          child: TextButton(
            onPressed: _resetAppPassword,
            child: Text(
              "Reset passcode",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            // splashColor: Colors.white.withOpacity(0.4),
            // highlightColor: Colors.white.withOpacity(0.2),
            // ),
          ),
        ),
      );

  _resetAppPassword() {
    if (mounted) {
      Navigator.maybePop(context).then((result) {
        if (!result) {
          return;
        }
        _showRestoreDialog(() {
          if (mounted) {
            Navigator.maybePop(context);
            //TODO: Clear your stored passcode here
          }
        });
      });
    }
  }

  _showRestoreDialog(VoidCallback onAccepted) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Reset passcode",
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            "Passcode reset is a non-secure operation!\n\nConsider removing all user data if this action performed.",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 16,
            ),
          ),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              onPressed: () {
                Navigator.maybePop(context);
              },
              child: const Text(
                "Cancel",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: onAccepted,
              child: const Text(
                "I understand",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
