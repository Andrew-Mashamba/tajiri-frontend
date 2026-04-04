import 'main.dart';
import 'vicobaList.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:sms_autofill/sms_autofill.dart';
import 'start.dart';
import 'appColor.dart';

import 'HttpService.dart';
import 'DataStore.dart';
import 'loginExt.dart';
import 'login.dart';
import 'searchOrCreatekikoba.dart';

class registerMobileNumber extends StatelessWidget {
  const registerMobileNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIKUNDI',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
      ),
      home: const MyHomePage(title: 'Usajiri wa simu'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with CodeAutoFill {
  String _status = "";
  bool _loading = false;
  bool _numberInput = true;
  bool _statusView = false;
  bool _submitButton = true;
  late String _currentHeader;
  final TextEditingController numberController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  late String phoneNumber;
  late String phoneIsoCode;
  bool visible = false;
  String confirmedNumber = '';
  bool _otpInput = false;
  final String _code = "";
  late String appSignature;
  late String otpCode;

  @override
  void codeUpdated() {
    setState(() {
      otpCode = code!;
    });
  }

  @override
  void initState() {
    super.initState();
    _currentHeader = "Jaza taarifa zako";

    SmsAutoFill().getAppSignature.then((signature) {
      if (mounted) {
        setState(() {
          appSignature = signature;
        });
      }
    });
  }

  @override
  void dispose() {
    SmsAutoFill().unregisterListener();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: buttonBar(),
        ),
      ),
    );
  }

  void onPhoneNumberChange(
      String number, String internationalizedPhoneNumber, String isoCode) {
    print(number);
    setState(() {
      phoneNumber = number;
      phoneIsoCode = isoCode;
      print('THE NUMBER IN: check $phoneNumber');
    });
  }

  onValidPhoneNumber(
      String number, String internationalizedPhoneNumber, String isoCode) {
    setState(() {
      visible = true;
      confirmedNumber = internationalizedPhoneNumber;
      print('THE NUMBER: verificationCompleted $confirmedNumber');
    });
  }

  Future<void> sendData(String thedate) async {
    print("AAAAAA DATA OGAS");

    var thenumber = DataStore.userNumber.replaceAll("+", "");
    //var thenumber = "12345";
    print("AAAAAA NAMBA$thenumber");

    String link = "createUser.php?name=newUser&phone=$thenumber&password=3333&userId=${DataStore.currentUserId}";

    final http.Response response = await http.post(
      Uri.parse(link),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'name': "newUser",
        'phone': thenumber,
        'password': "3333",
        'reg_date': thedate,
        'userId': DataStore.currentUserId,
      }),
    );
    print("AAAAAA ${response.body}");
    if (response.statusCode == 200) {
      //var data = json.decode(response.body);
      //var userName = data["userName"];
      print(response.body);
      if (response.body.trim() == "700") {
        print("main : pass xxxxxxxxxx");
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => const VikobaListPage()));
      } else {
        print("Error in registration server");
        print("Load sent");
        print(link);
      }
    } else {
      throw Exception('Failed to create album.');
    }
  }

  Widget buttonBar() {
    return Column(
      children: [
        // Header Section - Fixed height to prevent overflow
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.25,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentHeader,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1A1A)),
                  strokeWidth: 2,
                ),
              if (_statusView)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF999999).withOpacity(0.3)),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        
        // Content Section - Using Flexible to prevent overflow
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // First Name Field
                if (_numberInput)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Jina la kwanza',
                        hintStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      ),
                      onChanged: (text) {
                        setState(() {});
                      },
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_numberInput) const SizedBox(height: 16),
                // Last Name Field
                if (_numberInput)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Jina la ukoo',
                        hintStyle: const TextStyle(
                          color: Color(0xFF999999),
                          fontSize: 16,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      ),
                      onChanged: (text) {
                        setState(() {});
                      },
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                if (_numberInput) const SizedBox(height: 16),
                // Phone Number Field
                if (_numberInput)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                            color: const Color(0xFF1A1A1A),
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
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
                      ),
                      onChanged: (text) {
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
                const SizedBox(height: 32),
                if (_submitButton)
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 56, maxHeight: 64),
                    child: Material(
                      color: _isFormValid()
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFF999999),
                      borderRadius: BorderRadius.circular(16),
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.1),
                      child: InkWell(
                        onTap: _isFormValid()
                            ? _submitPhoneNumber
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            "Sajiri",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                if (_otpInput)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Jaza namba za ufunguo",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        PinFieldAutoFill(
                          codeLength: 4,
                          decoration: BoxLooseDecoration(
                            strokeColorBuilder: FixedColorBuilder(
                              const Color(0xFF1A1A1A),
                            ),
                            bgColorBuilder: FixedColorBuilder(
                              Colors.white,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 24,
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w600,
                            ),
                            radius: const Radius.circular(12),
                          ),
                          currentCode: _code,
                          onCodeSubmitted: (code) {},
                          onCodeChanged: (code) {
                            if (code!.length == 4) {
                              FocusScope.of(context).requestFocus(FocusNode());
                              DataStore.otp = code;
                              submitOTP(code);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isFormValid() {
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        numberController.text.length >= 8;
  }

  void processPhoneNumber(String value) {
    if (value.trim().toLowerCase() == "0") {
      numberController.clear();
    } else {
      validateMobile(value);
      if (mounted) {
        setState(() {
          _statusView = false;
        });
      }
    }
  }

  String? validateMobile(String value) {
    if (value.length != 9) {
      return 'Namba ya simu lazima iwe na tarakimu 9';
    }
    return null;
  }

  Future<void> _submitPhoneNumber() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _numberInput = false;
        _submitButton = false;
        _currentHeader = "Tafadhali subiri...";
      });
    }

    /// NOTE: Either append your phone number country code or add in the code itself
    /// Since I'm in India we use "+91 " as prefix `phoneNumber`
    //String phoneNumber = _phoneNumberController.text.toString().trim();
    phoneNumber = "+255${numberController.text.trim()}";
    DataStore.userNumber = phoneNumber;

    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    DataStore.currentUserName = "$firstName $lastName";

    print('Phone: $phoneNumber, FirstName: $firstName, LastName: $lastName');

    try {
      HttpService.registerMobileNo(
        DataStore.userNumber,
        firstName: firstName,
        lastName: lastName,
      ).then((String result) {
        print(result);

        // Parse JSON response to get the message
        String message = result.trim();
        Map<String, dynamic>? jsonResponse;
        try {
          jsonResponse = json.decode(result);
          if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('message')) {
            message = jsonResponse['message'];
          }
        } catch (e) {
          // If parsing fails, use the raw result
          message = result.trim();
        }

        if (message == "registered") {
          // Store userId from response if available
          if (jsonResponse != null) {
            final userId = jsonResponse['userId']?.toString() ?? '';
            if (userId.isNotEmpty) {
              DataStore.currentUserId = userId;
            }
          }

          if (mounted) {
            setState(() {
              _otpInput = true;
              _currentHeader = "Jaza namba utakazo pokea kwenye meseji";
              _loading = false;
            });
          }
        } else if (message == "present") {
          // Phone number is already registered, redirect to login with prefilled number
          if (mounted) {
            setState(() {
              _loading = false;
              _currentHeader = "Namba hii imeshajisajiri. Inakuongoza kurasa ya kuingia...";
            });
            
            // Wait a moment for the user to see the message, then navigate
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => login(phoneNumber: DataStore.userNumber),
                  ),
                  (Route<dynamic> route) => false,
                );
              }
            });
          }
        } else if (message == "Network Error") {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Kuna matatizo ya mtandao. Jaribu tena';
              _loading = false;
              _numberInput = true;
              _submitButton = true;
              _currentHeader = "Jaza namba yako ya simu";
            });
          }
        } else if (message == "Device Offline") {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Hauna Internet. Tafadhali washa data';
              _loading = false;
              _numberInput = true;
              _submitButton = true;
              _currentHeader = "Jaza namba yako ya simu";
            });
          }
        } else if (message == "Server Error") {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Kuna tatizo la kiufundi. Jaribu tena baadae';
              _loading = false;
              _numberInput = true;
              _submitButton = true;
              _currentHeader = "Jaza namba yako ya simu";
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Kuna tatizo la kiufundi. Jaribu tena baadae';
              _loading = false;
              _numberInput = true;
              _submitButton = true;
              _currentHeader = "Jaza namba yako ya simu";
            });
          }

          HttpService.reportBug("no error", "registerMobileNo", "nobody",
              message, "no device");
        }
      });
    } on Exception catch (ex) {
      print('Query error: $ex');
    }
  }

  void submitOTP(String code) {
    try {
      HttpService.submitOTP(code).then((String result) {
        print(result);

        // Handle network/device errors first
        if (result.trim() == "Network Error") {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Kuna matatizo ya mtandao. Jaribu tena';
              _loading = false;
              _numberInput = false;
              _submitButton = false;
              _currentHeader = "Jaza namba utakazo pokea kwenye meseji";
            });
          }
          return;
        } else if (result.trim() == "Device Offline") {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Hauna Internet. Tafadhali washa data';
              _loading = false;
              _numberInput = true;
              _submitButton = true;
              _currentHeader = "Jaza namba yako ya simu";
            });
          }
          return;
        } else if (result.trim() == "Server Error") {
          if (mounted) {
            setState(() {
              _statusView = true;
              _status = 'Kuna tatizo la kiufundi. Jaribu tena baadae';
              _loading = false;
              _numberInput = false;
              _submitButton = false;
              _currentHeader = "Jaza namba utakazo pokea kwenye meseji";
            });
          }
          return;
        }

        // Try to parse JSON response
        try {
          final jsonResponse = json.decode(result);
          if (jsonResponse is Map<String, dynamic>) {
            final message = jsonResponse['message'] ?? '';

            if (message == "OTP verified successfully") {
              // Store the userId from the response
              final userId = jsonResponse['userId'] ?? '';
              if (userId.isNotEmpty) {
                DataStore.currentUserId = userId;
              }

              // Store phone number if provided
              final phone = jsonResponse['phone'] ?? '';
              if (phone.isNotEmpty) {
                DataStore.userNumber = phone;
              }

              // Store user name if provided
              final name = jsonResponse['name'] ?? '';
              if (name.isNotEmpty) {
                DataStore.currentUserName = name;
              }

              // Check if PIN was sent
              final pinSent = jsonResponse['pin_sent'] ?? false;

              // Navigate to kikoba selection/creation page
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const searchOrcreate()),
                    (Route<dynamic> route) => false);
              }
              return;
            } else if (jsonResponse.containsKey('error')) {
              // Handle error response like {"error":"Invalid OTP",...}
              if (mounted) {
                setState(() {
                  _statusView = true;
                  _status = 'Namba ulio jaza si sahihi. Jaribu tena';
                  _loading = false;
                  _numberInput = false;
                  _submitButton = false;
                  _currentHeader = "Jaza namba utakazo pokea kwenye meseji";
                });
              }
              return;
            }
          }
        } catch (e) {
          // JSON parsing failed, check for legacy string responses
          if (result.trim() == "success") {
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const searchOrcreate()),
                (Route<dynamic> route) => false);
            return;
          } else if (result.trim() == "wrong") {
            if (mounted) {
              setState(() {
                _statusView = true;
                _status = 'Namba ulio jaza si sahihi. Jaribu tena';
                _loading = false;
                _numberInput = false;
                _submitButton = false;
                _currentHeader = "Jaza namba utakazo pokea kwenye meseji";
              });
            }
            return;
          }
        }

        // Fallback for unrecognized response
        if (mounted) {
          setState(() {
            _statusView = true;
            _status = 'Kuna tatizo la kiufundi. Jaribu tena baadae';
            _loading = false;
            _numberInput = false;
            _submitButton = false;
            _currentHeader = "Jaza namba utakazo pokea kwenye meseji";
          });
        }

        HttpService.reportBug(
            "no error", "submitOTP", "nobody", result.trim(), "no device");
      });
    } on Exception catch (ex) {
      print('Query error: $ex');
    }
  }
}
