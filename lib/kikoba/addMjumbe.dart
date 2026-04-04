// import 'main.dart'; // removed — auth handled by TAJIRI bridge
import 'vicobaList.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:uuid/uuid.dart';
// import 'start.dart'; // removed — auth handled by TAJIRI bridge

import 'waitDialog.dart';
import 'HttpService.dart';
import 'contacts_list.dart';
import 'contacts_picker.dart';
import 'DataStore.dart';
import 'sms_launcher.dart';

import 'package:permission_handler/permission_handler.dart';

// Design Guidelines Colors (Monochrome)
const _primaryBg = Color(0xFFFAFAFA);
const _cardBg = Color(0xFFFFFFFF);
const _primaryText = Color(0xFF1A1A1A);
const _secondaryText = Color(0xFF666666);
const _iconBg = Color(0xFF1A1A1A);
const _accentColor = Color(0xFF999999);

class addMjumbe extends StatelessWidget {
  const addMjumbe({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIKUNDI',
      theme: ThemeData(
        scaffoldBackgroundColor: _primaryBg,
        fontFamily: 'Roboto',
      ),
      home: const MyHomePage(title: 'Ongeza Mwanachama'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with CodeAutoFill  {




  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  late FirebaseMessaging messaging;
  String? notificationText;



  String _status ="";
  late String _buttonText;
  bool _loading = false;
  bool _numberInput = true;
  final bool _space48 = false;
  bool _statusView = false;
  bool _submitButton = true;
  final bool _currentHeaderView = true;
  final bool _showOtpInput = true;
  late String _currentHeader;
  TextEditingController numberController = TextEditingController();
  TextEditingController jinaController = TextEditingController();

  var userAvailable = false;

  late String phoneNumber;
  late String phoneIsoCode;
  bool visible = false;
  String confirmedNumber = '';
  final bool _otpInput = false;

  final String _code="";
  String signature = "{{ app signature }}";
  late String appSignature;
  late String otpCode;

  TextEditingController nameController = TextEditingController();
  final int _radioValue = 0;


  final int _groupValue = -1;

  var _result = "Mjumbe";

  late TextEditingController _controllerPeople, _controllerMessage;
  String? _message, body;
  final String _canSendSMSMessage = 'Check is not run.';
  List<String> people = [];
  bool sendDirect = false;


  @override
  void codeUpdated() {
    setState(() {
      otpCode = code!;
    });
  }

  @override
  initState(){
    super.initState();




    _buttonText = "Sajiri";
    _currentHeader = "Jaza namba ya simu ya mwanachama unaye mualika";

    _askPermissions();
    initPlatformState();
  }


  Future<void> initPlatformState() async {
    _controllerPeople = TextEditingController();
    _controllerMessage = TextEditingController();

    var status = await Permission.sms.status;
    if (status.isDenied) {
      // We didn't ask for permission yet or the permission has been denied before but not permanently.
      Map<Permission, PermissionStatus> statuses = await [
        Permission.sms,
      ].request();
      if (kDebugMode) {
        print(statuses[Permission.sms]);
      }
    }
  }




  Route _routeTocontactList() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ContactListPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Route _routeTocontactsPicker() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => ContactPickerPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }


  Future<void> _askPermissions() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {

    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await Permission.contacts.status;
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.permanentlyDenied) {
      PermissionStatus permissionStatus = await Permission.contacts.request();
      return permissionStatus;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      final snackBar = SnackBar(content: Text('Access to contact data denied'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (permissionStatus == PermissionStatus.permanentlyDenied) {
      final snackBar =
      SnackBar(content: Text('Contact data not available on device'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryBg,
      appBar: AppBar(
        backgroundColor: _iconBg,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: buttonBar(),
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


    final http.Response response = await http.post(Uri.parse(link),
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
      if(response.body.trim() == "700"){

        print("main : pass xxxxxxxxxx");
        Navigator.push(context, MaterialPageRoute(builder: (context) => const VikobaListPage()));

      }else{

        print("Error in registration server");
        print("Load sent");
        print(link);

      }

    } else {
      throw Exception('Failed to create album.');
    }


  }




  Widget buttonBar() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        const SizedBox(height: 24),

        // Select from contacts card
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context).pushReplacement(_routeTocontactList());
              },
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.contacts_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Chagua kutoka Contacts",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: _primaryText,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Bonyeza hapa kuchagua mtu kutoka simu yako",
                            style: TextStyle(
                              fontSize: 13,
                              color: _secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: _accentColor,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Divider with "AU"
        Row(
          children: [
            Expanded(child: Container(height: 1, color: _accentColor.withValues(alpha: 0.3))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "AU",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _secondaryText,
                ),
              ),
            ),
            Expanded(child: Container(height: 1, color: _accentColor.withValues(alpha: 0.3))),
          ],
        ),

        const SizedBox(height: 24),

        // Manual entry card
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Jaza taarifa za mualikwa",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 20),

                // Name field
                TextField(
                  controller: jinaController,
                  style: const TextStyle(color: _primaryText, fontSize: 16),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _primaryBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _iconBg, width: 2),
                    ),
                    labelText: 'Jina la mualikwa',
                    labelStyle: const TextStyle(color: _secondaryText),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 20),
                    ),
                    counterText: '',
                  ),
                  maxLength: 100,
                  keyboardType: TextInputType.name,
                ),

                const SizedBox(height: 16),

                // Status message
                if (_statusView)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Phone field
                if (_numberInput)
                  TextField(
                    controller: numberController,
                    style: const TextStyle(color: _primaryText, fontSize: 16),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: _primaryBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _accentColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _iconBg, width: 2),
                      ),
                      labelText: 'Namba ya simu',
                      labelStyle: const TextStyle(color: _secondaryText),
                      helperText: 'Bila sifuri ya mwanzo mf. 712444576',
                      helperStyle: const TextStyle(color: _secondaryText, fontSize: 12),
                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _iconBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                      ),
                      prefixText: '+255 ',
                      prefixStyle: const TextStyle(color: _primaryText, fontWeight: FontWeight.w600),
                      counterText: '',
                    ),
                    maxLength: 9,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Role selection card
        Container(
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cheo cha mualikwa",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: _primaryText,
                  ),
                ),
                const SizedBox(height: 16),

                _buildRoleOption(
                  title: "Mwenyekiti",
                  subtitle: "Kitambulisho chake kitahitajika",
                  value: "Mwenyekiti",
                  icon: Icons.star_rounded,
                ),
                const SizedBox(height: 12),

                _buildRoleOption(
                  title: "Katibu",
                  subtitle: "Kitambulisho chake kitahitajika",
                  value: "Katibu",
                  icon: Icons.edit_note_rounded,
                ),
                const SizedBox(height: 12),

                _buildRoleOption(
                  title: "Mjumbe",
                  subtitle: "Kitambulisho chake hakitahitajika",
                  value: "Mjumbe",
                  icon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _iconBg,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _accentColor.withValues(alpha: 0.3),
              disabledForegroundColor: _secondaryText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: (numberController.text.length >= 8 && jinaController.text.isNotEmpty)
                ? () => _submitPhoneNumber()
                : null,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mwalike',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.send_rounded, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRoleOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _result == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _result = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _iconBg : _primaryBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _iconBg : _accentColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : _iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? Colors.white : _primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white.withValues(alpha: 0.7) : _secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: isSelected ? Colors.white : _accentColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }


  void processPhoneNumber(String value){
    String validityMessage;
    if(value.trim().toLowerCase() == "0"){
      numberController.clear();
    }else {
      validityMessage = validateMobile(value)!;
      setState(() {
        //_status = 'verificationFailed\n';
        //_buttonText = 'Jaribu Tena';
        _statusView = false;
      });
          print('Validity message: $validityMessage');
    }
  }

  String? validateMobile(String value) {
// Indian Mobile number are of 10 digit only
    if (value.length != 9) {
      return 'Mobile Number must be of 9 digit';
    } else {
      return null;
    }
  }



  Future<void> _submitPhoneNumber() async {
    setState(() {
      _loading = true;
      _numberInput = false;
      _submitButton = false;
      _currentHeader = "Tafadhali subiri...";
    });

    phoneNumber = "+255${numberController.text.trim()}";

    // Check if chairman - can directly add members
    final isChairman = DataStore.userCheo == 'Mwenyekiti';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return waitDialog(
          title: "Tafadhali Subiri",
          descriptions: isChairman
              ? "Mualikwa ana taarifiwa..."
              : "Ombi la uanachama linatumwa...",
          text: "",
        );
      },
    );

    try {
      if (isChairman) {
        // Chairman can directly add members
        final response = await HttpService.registerMobileNo2(
          phoneNumber,
          jinaController.text,
          _result,
        );

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop('dialog');
        }

        if (response.isSuccess) {
          // Success - registered or added_to_kikoba
          print("Registration successful: ${response.message}");
          print("User ID: ${response.userId}");
          if (response.otp != null) {
            print("OTP: ${response.otp}");
            print("OTP expires at: ${response.otpExpiresAt}");
            print("WhatsApp sent: ${response.whatsappSent}");
          }

          // Store the new user ID if needed
          if (response.userId != null) {
            DataStore.lastRegisteredUserId = response.userId;
          }

          // Open SMS app if manual sending is required
          if (response.requiresManualSend) {
            await SmsLauncher.openSmsApp(
              phoneNumber: response.manualSend!.recipientPhone,
              message: response.manualSend!.message,
            );
          }

          // Post to baraza
          addData(phoneNumber, jinaController.text, _result);

          // Navigate back
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop(context);
          }
        } else {
          // Handle error cases
          _handleRegistrationError(response.message);
        }
      } else {
        // Non-chairman: Create membership request for voting
        final response = await HttpService.createMembershipJoinRequest(
          userId: '', // Will be assigned by server
          userName: jinaController.text,
          phone: phoneNumber,
          role: _result,
          reason: '${DataStore.currentUserName} amependekeza mwanachama huyu',
        );

        // Dismiss loading dialog
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop('dialog');
        }

        if (response['success'] == true) {
          // Show success message about voting
          if (mounted) {
            _showVotingCreatedDialog();
          }
        } else {
          _handleRegistrationError(response['message'] ?? 'Tatizo limetokea');
        }
      }
    } catch (ex) {
      print('Query error: $ex');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        _handleRegistrationError("Unexpected Error");
      }
    }
  }

  void _showVotingCreatedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.how_to_vote_rounded, color: Colors.green.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ombi Limetumwa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ombi la kumwalika ${jinaController.text} limetumwa kwa wanachama wote kupiga kura.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Mualikwa ataongezwa baada ya wanachama wengi kukubali.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context, rootNavigator: true).pop(context);
              },
              child: const Text('Sawa'),
            ),
          ],
        );
      },
    );
  }

  void _handleRegistrationError(String errorMessage) {
    setState(() {
      _statusView = true;
      _loading = false;
      _numberInput = true;
      _submitButton = true;
      _currentHeader = "Jaza namba ya simu ya mwanachama unaye mualika";

      switch (errorMessage) {
        case "present":
          _status = 'Namba ulio jaza imesajiriwa na mtu mwingine, Jaribu namba nyingine';
          _buttonText = 'Jaribu Tena';
          break;
        case "Network Error":
          _status = 'Kuna matatizo ya mtandao, Jaribu tena';
          _buttonText = 'Jaribu Tena';
          break;
        case "Device Offline":
          _status = 'Hauna Internet, Tafadhali washa data';
          _buttonText = 'Jaribu Tena';
          break;
        case "Server Error":
          _status = 'Kuna tatizo la kiufundi, jaribu tena baadae';
          _buttonText = 'Jaribu Tena Baadae';
          break;
        default:
          _status = 'Kuna tatizo, jaribu tena baadae';
          _buttonText = 'Jaribu Tena';
      }
    });
  }




  void addData(String namba, String jinalamwalikwa, String cheo) {
    var postComment = "${DataStore.currentUserName} amemwalika mjumbe mpya, ndugu $jinalamwalikwa kama $cheo, kwenye kikoba hichi.";
    var uuid = Uuid();
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String thedate = dateFormat.format(DateTime.now());


    CollectionReference users = FirebaseFirestore.instance.collection('${DataStore.currentKikobaId}barazaMessages');


    // Call the user's CollectionReference to add a new user
    users.add({
      'posterName': DataStore.currentUserName,
      'posterId': DataStore.currentUserId,
      'posterNumber': DataStore.userNumber,
      'posterPhoto': "",
      'postComment': postComment,
      'postImage': '',
      'postType': 'taarifaYamualiko',
      'postId': uuid.v4(),
      'postTime': thedate,
      'kikobaId': DataStore.currentKikobaId
    }).then((value) =>

        sendNotifications(postComment,namba)

    ).catchError((error) =>

        print("Failed to add user: $error")
    );


  }

void sendNotifications(String postComment, String namba){

}








}




