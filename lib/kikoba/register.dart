import 'main.dart';
import 'vicobaList.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:uuid/uuid.dart';
import 'start.dart';
import 'appColor.dart';

import 'DataStore.dart';



class Registerx extends StatelessWidget {
  const Registerx({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VIKUNDI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Usajiri wa simu'),
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
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  late User _firebaseUser;
  late String _status;
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


  late AuthCredential _phoneAuthCredential;
  late String _verificationId;


  var userAvailable = false;

  late String phoneNumber;
  late String phoneIsoCode;
  bool visible = false;
  String confirmedNumber = '';
  bool _otpInput = false;

  final String _code="";
  String signature = "{{ app signature }}";
  late String appSignature;
  late String otpCode;

  @override
  void codeUpdated() {
    setState(() {
      otpCode = code!;
    });
  }

  @override
  initState(){
    super.initState();
    //await Firebase.initializeApp();
    //_getFirebaseUser();
    _buttonText = "Sajiri";
    _currentHeader = "Jaza namba yako ya simu";

    listenForCode();

    SmsAutoFill().getAppSignature.then((signature) {
      setState(() {
        appSignature = signature;
      });
    });
  }
  @override
  void dispose() {
    SmsAutoFill().unregisterListener();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: 18);



    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),

      ),
      body: buttonBar(),
    );
  }


  void _handleError(e) {
    print(e.toString());
    print("LOGIN RESULTS : USER IS NOT REGISTERED");
    setState(() {
      //_status += e.message + '\n';
    });
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


  Future<void> _submitPhoneNumber() async {
    setState(() {_loading = true; _numberInput = false; _submitButton = false; _currentHeader="Tafadhali subiri...";});

    /// NOTE: Either append your phone number country code or add in the code itself
    /// Since I'm in India we use "+91 " as prefix `phoneNumber`
    //String phoneNumber = _phoneNumberController.text.toString().trim();
    phoneNumber = "+255${numberController.text.trim()}";
    DataStore.userNumber =phoneNumber;
    print(phoneNumber);

    /// The below functions are the callbacks, separated so as to make code more redable
    void verificationCompleted(AuthCredential phoneAuthCredential) {
      print('verificationCompleted');
      setState(() {
        _status += 'verificationCompleted\n';
      });
      _phoneAuthCredential = phoneAuthCredential;
      print(phoneAuthCredential);
    }

    void verificationFailed(FirebaseAuthException error) {
      print('verificationFailed');
      //_handleError(error);
      setState(() {
        _statusView = true;
        _status = 'Namba ulio jaza sio sahihi, Jaribu tena\n';
        _buttonText = 'Jaribu Tena';
        _loading = false;
        _numberInput = true;
        _submitButton = true;
        _currentHeader = "Jaza namba yako ya simu";

      });
    }



    void codeAutoRetrievalTimeout(String verificationId) {
      print('codeAutoRetrievalTimeout');
      setState(() {
        _status += 'codeAutoRetrievalTimeout\n';
      });
      print(verificationId);
    }

    await FirebaseAuth.instance.verifyPhoneNumber(
      /// Make sure to prefix with your country code
      phoneNumber: phoneNumber,

      /// `seconds` didn't work. The underlying implementation code only reads in `millisenconds`
      timeout: Duration(milliseconds: 10000),

      /// If the SIM (with phoneNumber) is in the current device this function is called.
      /// This function gives `AuthCredential`. Moreover `login` function can be called from this callback
      /// When this function is called there is no need to enter the OTP, you can click on Login button to sigin directly as the device is now verified
      verificationCompleted: verificationCompleted,

      /// Called when the verification is failed
      verificationFailed: verificationFailed,

      /// This is called after the OTP is sent. Gives a `verificationId` and `code`
      //codeSent: codeSent,

      /// After automatic code retrival `tmeout` this function is called
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout, codeSent: (String verificationId, int? forceResendingToken) {

      print('codeSent');
      _verificationId = verificationId;
      print(verificationId);
      if(_showOtpInput){
        _otpInput = true;
        _currentHeader = "Jaza namba uliopokea kwenye meseji";
        _loading = false;
      }
      //this._code = code;
      //print("THE CODE "+code.toString());
      setState(() {
        //_status = 'Code Sent\n';
      });

      },
    ); // All the callbacks are above
  }

  void _submitOTP(String smsCode) {
    /// get the `smsCode` from the user
    //String smsCode = _otpController.text.toString().trim();
    print("THE OTPCODE : $smsCode");

    /// when used different phoneNumber other than the current (running) device
    /// we need to use OTP to get `phoneAuthCredential` which is inturn used to signIn/login
    _phoneAuthCredential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: smsCode);


    _login();
  }

  Future<void> _login() async {
    /// This method is used to login the user
    /// `AuthCredential`(`_phoneAuthCredential`) is needed for the signIn method
    /// After the signIn method from `AuthResult` we can get `FirebaserUser`(`_firebaseUser`)
    try {
      await FirebaseAuth.instance
          .signInWithCredential(_phoneAuthCredential)
          .then((UserCredential authRes) async {

        _firebaseUser = authRes.user!;

        print("THE USER AFTER LOGIN$_firebaseUser");

        //GO TO BARAZA

        var uuid = Uuid();
        // Generate a v1 (time-based) id
        //print(uuid.v1()); // -> '6c84fb90-12c4-11e1-840d-7b25c5ee775a'

        var currentUserId = uuid.v1();
        DataStore.currentUserId = currentUserId;
        DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
        String thedate = dateFormat.format(DateTime.now());

        CollectionReference users = FirebaseFirestore.instance.collection('${currentUserId}userData');


        // Call the user's CollectionReference to add a new user
        users.add({
          'Name': "newUser",
          'userId': DataStore.currentUserId ,
          'phoneNumber': DataStore.userNumber,
          'userPhotoLocal': "",
          'userPhotoRemote': "",
          'status': "Available to chat",
          'userAccount': '000000000000',
          'pin': '3333',
          'cheo': 'Mjumbe',
          'totalAda': '0 /=',
          'monthlyAda': '0 /=',
          'ada': 'unpaid',
          'adaArreas': '0 /=',
          'hisa':'unpaid',
          'totalHisa': '0 /=',
          'minimumHisa': '1,000 /=',
          'hisaArreas': '0 /=',
          'currentLoan':'0 /=',
          'loanInterestType':'flat',
          'rejesho':'0 /=',
          'riba':'10',
          'loanArreas':'0 /=',
          'currentLoanPayment':'0 /=',
          'michangoUlioChangia':'0',
          'michangoUlioChangiaAmount':'0 /=',
          'michangoUliochangiwa':'0',
          'michangoUliochangiwaAmount':'0 /=',
          'fainiAmount':'0 /=',
          'registrationDate' : thedate,
          'lastUpdateDate' : thedate
        }).then((value) =>

        //print("User Added")
            sendData(thedate)
        //goToMessages(value.toString())

        ).catchError((error) => print("Failed to add user: $error"));





      }).catchError((e) => _handleError(e));

      setState(() {
        _status = 'Signed In\n';
      });

    } catch (e) {

      _handleError(e);

    }
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
    final textStyle = TextStyle(fontSize: 18);

    return Column(


      children: <Widget>[



        //Spacer(flex: 1),
        SizedBox(height: 60),
        Center(
          child: _currentHeaderView ? Text(_currentHeader,
            textScaleFactor: 1.5,) : null,
        ),
        SizedBox(height: 60),
        Center(
            child: _loading ? CircularProgressIndicator() : null
        ),
        Center(
          child:_space48 ? SizedBox(height: 48) : null,
        ),
        Center(
          child:_statusView ? Text(
              _status,
              style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.primary)
          ) : null,
        ),
        Center(
          child:_space48 ? SizedBox(height: 48) : null,
        ),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 62, vertical: 16),
            child: _numberInput ? TextField(
              controller: numberController,
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.redAccent)),
                  hintText: '',
                  helperText: 'Bila sifuri ya mwanzo mf. 712444576',
                  labelText: 'Namba yako ya simu',
                  prefixIcon: const Icon(
                    Icons.phone,
                    color: Colors.green,
                  ),
                  prefixText: ' +255 ',
                  suffixText: 'TZ',
                  suffixStyle: const TextStyle(color: Colors.green)),
              onChanged: (text) {
                print('First text field: $text');
                processPhoneNumber(text);
              },
              maxLength: 9,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ], // Only numbers can be entered
            ) : null
        ),

        SizedBox(height: 40),
        Center(
          child:_submitButton ? Container(
          margin: EdgeInsets.all(25),
          child: OutlinedButton (
            style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                  side: BorderSide(color: AppColors.primary, width: 1.0), // HERE
                ),
                side: BorderSide(color: Colors.black, width: 1.0)),

          onPressed: (numberController.text.length >= 8) ? () =>  _submitPhoneNumber() : null, // AND HERE
          child: Text("Sajiri", style: TextStyle(fontSize: 20.0),),
          ),
          ): null,),


        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _otpInput ? Builder(
            builder: (_) {
              if (_showOtpInput) {
                //return Text("Listening for code...", style: textStyle);

                return Column(


                    children: <Widget>[

                              PinFieldAutoFill(
                              decoration: UnderlineDecoration(
                              textStyle: TextStyle(fontSize: 20, color: Colors.black),
                              colorBuilder: FixedColorBuilder(Colors.black.withOpacity(0.3)),
                              ),
                              currentCode: _code,
                              onCodeSubmitted: (code) {},
                              onCodeChanged: (code) {
                              if (code!.length == 6) {
                              FocusScope.of(context).requestFocus(FocusNode());
                              DataStore.otp = code;
                              _submitOTP(code);
                              }
                              },
                              ),

                              ],
                );


              }else{



                return Column(


                  children: <Widget>[

                    PinFieldAutoFill(
                      decoration: UnderlineDecoration(
                        textStyle: TextStyle(fontSize: 20, color: Colors.black),
                        colorBuilder: FixedColorBuilder(Colors.black.withOpacity(0.3)),
                      ),
                      currentCode: _code,
                      onCodeSubmitted: (code) {},
                      onCodeChanged: (code) {
                        if (code!.length == 6) {
                          FocusScope.of(context).requestFocus(FocusNode());
                        }
                      },
                    ),

                  ],
                );



              }
              //return Text("Code Received: $otpCode", style: textStyle);
            },
          ) : null,
        ),


      ],
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




}




