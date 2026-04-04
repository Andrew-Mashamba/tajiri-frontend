import 'dart:ui';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:steel_crypt/steel_crypt.dart';
import 'package:vicoba/appColor.dart';
import 'package:vicoba/main.dart';
import 'package:vicoba/vicobaList.dart';

import 'profileImage.dart';
import 'OfflineDatabase.dart';
import 'Userx.dart';
import 'DataStore.dart';
import 'appColor.dart';
import 'waitDialog.dart';
import 'HttpService.dart';
import 'main.dart';

class CreateNewAccount extends StatelessWidget {
  const CreateNewAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Create Account',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, 
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(surface: Colors.white),
      ),
      home: PinCodeVerificationScreen("+8801376221100"),
    );
  }
}

class PinCodeVerificationScreen extends StatefulWidget {
  final String? phoneNumber;

  const PinCodeVerificationScreen(this.phoneNumber, {super.key});

  @override
  CreateNewAccountx createState() => CreateNewAccountx();
}

class CreateNewAccountx extends State<PinCodeVerificationScreen> {
  // Controllers and variables for first PIN
  TextEditingController textEditingController = TextEditingController();
  StreamController<ErrorAnimationType>? errorController;
  bool hasError = false;
  String currentText = "";
  final formKey = GlobalKey<FormState>();

  // Controllers and variables for second PIN
  TextEditingController textEditingController2 = TextEditingController();
  StreamController<ErrorAnimationType>? errorController2;
  bool hasError2 = false;
  String currentText2 = "";
  final formKey2 = GlobalKey<FormState>();

  // Name controller
  TextEditingController jinacontroller = TextEditingController();

  @override
  void initState() {
    super.initState();
    errorController = StreamController<ErrorAnimationType>();
    errorController2 = StreamController<ErrorAnimationType>();
  }

  @override
  void dispose() {
    errorController?.close();
    errorController2?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: size.width * 0.1),
                // Profile image picker
                InkWell(
                  onTap: () {
                    print("tapped on container");
                    goimagePicker(context);
                  },
                  child: Stack(
                    children: [
                      Center(
                        child: _buildDefaultProfileImage(size),
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: _previewImage(context),
                      ),
                      _buildUploadButton(size),
                    ],
                  ),
                ),
                SizedBox(height: size.width * 0.1),
                
                // Name input field
                _buildInputSection(size),
                
                // Submit button
                _buildSubmitButton(),
              ],
            ),
          ),
        )
      ],
    );
  }

  // Default profile image placeholder
  Widget _buildDefaultProfileImage(Size size) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: CircleAvatar(
          radius: size.width * 0.14,
          backgroundColor: Colors.grey[400]!.withOpacity(0.4),
          child: Icon(
            FontAwesomeIcons.user,
            color: AppColors.accent,
            size: size.width * 0.1,
          ),
        ),
      ),
    );
  }

  // Upload button overlay
  Widget _buildUploadButton(Size size) {
    return Positioned(
      top: size.height * 0.08,
      left: size.width * 0.56,
      child: Container(
        height: size.width * 0.1,
        width: size.width * 0.1,
        decoration: BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: const Icon(
          FontAwesomeIcons.arrowUp,
          color: Colors.white,
        ),
      ),
    );
  }

  // Main form input section
  Widget _buildInputSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full name field
        const Padding(
          padding: EdgeInsets.only(left: 30),
          child: Text(
            "Jina lako kamili", 
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: Colors.black87
            ),
          ),
        ),
        _buildNameTextField(size),
        
        // First PIN field
        const Padding(
          padding: EdgeInsets.only(left: 30, top: 15),
          child: Text(
            "Namba yako ya siri",
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        _buildFirstPinField(size),
        
        // Second PIN field
        const Padding(
          padding: EdgeInsets.only(left: 30, top: 15),
          child: Text(
            "Rudia namba ya siri",
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        _buildSecondPinField(size),
      ],
    );
  }

  // Name text field
  Widget _buildNameTextField(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30),
      child: Container(
        height: size.height * 0.08,
        width: size.width * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
        ),
        child: Center(
          child: TextField(
            controller: jinacontroller,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Ingiza jina lako kamili",
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              prefixIcon: Icon(
                FontAwesomeIcons.user,
                color: AppColors.primary,
                size: 18,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ),
    );
  }

  // First PIN field
  Widget _buildFirstPinField(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30),
      child: Container(
        height: size.height * 0.12,
        width: size.width * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Form(
          key: formKey,
          child: PinCodeTextField(
            appContext: context,
            controller: textEditingController,
            length: 4,
            obscureText: true,
            obscuringCharacter: '*',
            obscuringWidget: iconx(),
            blinkWhenObscuring: true,
            animationType: AnimationType.fade,
            animationDuration: const Duration(milliseconds: 250),
            keyboardType: TextInputType.number,
            enableActiveFill: true,
            cursorColor: AppColors.primary,
            pastedTextStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
            validator: (v) => null,
            errorAnimationController: errorController,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 50,
              fieldWidth: 45,
              activeColor: AppColors.primary,
              selectedColor: AppColors.primary,
              inactiveColor: Colors.grey.shade400,
              activeFillColor: Colors.white,
              selectedFillColor: AppColors.primary.withOpacity(0.15),
              inactiveFillColor: Colors.grey.shade100,
              errorBorderColor: Colors.redAccent,
            ),
            boxShadows: const [
              BoxShadow(
                offset: Offset(0, 1),
                color: Colors.black12,
                blurRadius: 8,
              )
            ],
            onCompleted: (v) {
              print("Completed PIN: $v");
            },
            onChanged: (value) {
              setState(() => currentText = value);
            },
            beforeTextPaste: (text) => true,
          ),
        ),
      ),
    );
  }

  // Second PIN field
  Widget _buildSecondPinField(Size size) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30),
      child: Container(
        height: size.height * 0.12,
        width: size.width * 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Form(
          key: formKey2,
          child: PinCodeTextField(
            appContext: context,
            controller: textEditingController2,
            length: 4,
            obscureText: true,
            obscuringCharacter: '*',
            obscuringWidget: iconx(),
            blinkWhenObscuring: true,
            animationType: AnimationType.fade,
            animationDuration: const Duration(milliseconds: 300),
            enableActiveFill: true,
            keyboardType: TextInputType.number,
            cursorColor: AppColors.primary,
            pastedTextStyle: const TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
            validator: (v) => null,
            errorAnimationController: errorController2,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 50,
              fieldWidth: 45,
              activeColor: AppColors.primary,
              selectedColor: AppColors.primary,
              inactiveColor: Colors.grey.shade400,
              activeFillColor: Colors.white,
              selectedFillColor: AppColors.primary.withOpacity(0.15),
              inactiveFillColor: Colors.grey.shade100,
              errorBorderColor: Colors.redAccent,
            ),
            boxShadows: const [
              BoxShadow(
                offset: Offset(0, 1),
                color: Colors.black12,
                blurRadius: 8,
              )
            ],
            onCompleted: (v) {
              if (currentText != v) {
                errorDialog("Namba za siri hazi fanani. Tafadhali rudia tena");
              }
            },
            onChanged: (value) {
              setState(() => currentText2 = value);
            },
            beforeTextPaste: (text) => true,
          ),
        ),
      ),
    );
  }

  // Submit button
Widget _buildSubmitButton() {
  return Container(
    margin: const EdgeInsets.all(25),
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.primary, // ✅ green background
        foregroundColor: Colors.white,      // ✅ white text and icon color
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15)),
        ),
        side: BorderSide(color: AppColors.primary, width: 1.0),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
      ),
      onPressed: _submitForm,
      child: const Text(
        "Twende",
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
      ),
    ),
  );
}


  // Form validation and submission
  void _submitForm() {
    // Validate first PIN
    formKey.currentState!.validate();
    if (currentText.length != 4 || currentText == "1234") {
      errorDialog("Neno la siri limekosewa, tafadhali jaribu tena");
      setState(() => hasError = true);
      return;
    } else {
      setState(() => hasError = false);
    }

    // Validate second PIN
    formKey2.currentState!.validate();
    if (currentText2.length != 4 || currentText2 == "1234") {
      errorDialog("Neno la siri limekosewa, tafadhali jaribu tena");
      setState(() => hasError2 = true);
      return;
    } else {
      setState(() => hasError2 = false);
    }

    // Validate name
    if (jinacontroller.text.length < 4 || jinacontroller.text == "") {
      errorDialog("Tafadhali, andika jina lako kamili");
      return;
    }

    // If PIN fields don't match
    if (currentText != currentText2) {
      errorDialog("Namba za siri hazi fanani. Tafadhali rudia tena");
      return;
    }

    // Show loading dialog
    DataStore.waitDescription = "Usajiri unafanyika...";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return waitDialog(
          title: "Tafadhali Subiri",
          descriptions: "Usajiri unafanyika...",
          text: "",
        );
      }
    );

    // Process the registration
    _processRegistration();
  }

  void _processRegistration() {
    try {
      // Encrypt password
      var fortunaKey = CryptKey().genFortuna();
      var nonce = CryptKey().genDart(len: 12); 
      var aesEncrypter = AesCrypt(key: fortunaKey, padding: PaddingAES.pkcs7);
      String encrypted = aesEncrypter.gcm.encrypt(inp: currentText.trim(), iv: nonce);
      print("encrypted PASSWORD: $encrypted");

      // Send data to server
      HttpService.updateUserData(currentText.trim(), jinacontroller.text).then((String result) {
        setState(() {
          print(result);

          if (result.trim() == "success") {
            // Update user data locally
            DataStore.userPresent = true;
            DataStore.currentUserName = jinacontroller.text;
            
            // Create user object
            Userx user = Userx(
              id: "3",
              phone: DataStore.userNumber,
              name: DataStore.currentUserName,
              userId: DataStore.currentUserId,
              userStatus: '',
              reg_date: '',
              create_at: '',
              udid: '',
              otp: '',
              localpostImage: '',
              remotepostImage: '',
              password: '',
              is_expired: ''
            );
            
            // Save user in local database
            OfflineDatabase().setCurrentUser2(user).then((value) {
              print(value.phone);
            });

            // Dismiss loading dialog
            Navigator.of(context, rootNavigator: true).pop('dialog');

            // Navigate to main app
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const VikobaListPage()),
              (Route<dynamic> route) => false
            );
          } else {
            // Handle error
            Navigator.pop(context);
            errorDialog("Kuna tatizo la mtandao, tafadhali jaribu tena");
          }
        });
      });
    } catch (ex) {
      print('Query error: $ex');
      Navigator.pop(context);
      errorDialog("Kuna hitilafu imetokea, tafadhali jaribu tena");
    }
  }

  void goimagePicker(BuildContext appContext) {
    print("SEARCH IMAGES");
    Navigator.of(appContext).push(
      MaterialPageRoute(builder: (BuildContext context) => profileImage())
    );
  }

  // Profile image preview
  Widget _previewImage(BuildContext context) {
    print("THE IMAGE PATH: ${DataStore.profileImage}");
    Size size = MediaQuery.of(context).size;
    
    if (DataStore.profileImage == "noimage") {
      // Return empty container to let default image show
      return Container();
    } else {
      // Display selected profile image
      return Center(
        child: ClipOval(
          child: CircleAvatar(
            radius: size.width * 0.14,
            backgroundColor: Colors.transparent,
            child: Image.file(
              File(DataStore.profileImage),
              height: size.width * 0.28,
              width: size.width * 0.28,
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }
  }

  // Lock icon for PIN fields
  Widget iconx() {
    return Image.asset('assets/lock.jpg');
  }

  // Error dialog
  Future<void> errorDialog(String message) async {
    print(message);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kuna tatizo'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}