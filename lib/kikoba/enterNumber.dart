import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vicoba/DataStore.dart';
import 'package:vicoba/paymentStatus.dart';
import 'package:vicoba/waitDialog.dart';
import 'package:vicoba/appColor.dart';

import 'HttpService.dart';

final _formKey = GlobalKey<FormState>();

class enterNumber extends StatelessWidget {
  const enterNumber({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        //scaffoldBackgroundColor: const Color(0xFFEFEFEF),
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: PopMenu(),
    );
  }
}

class PopMenu extends StatefulWidget {
  const PopMenu({super.key});

  @override
  _PopMenuState createState() => _PopMenuState();
}

class _PopMenuState extends State<PopMenu> {
  TextEditingController numberController = TextEditingController();
  bool _statusView = false;
  final String _status = 'Namba ulio jaza sio sahihi, Jaribu tena\n';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Jaza namba ya simu'),
          titleSpacing: 10.0,
          centerTitle: true,
          leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
            ),
          ),
        ),
        body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[


              Card(
                color: Colors.white,
                elevation: 1.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Stack(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 30,
                         // backgroundImage: AssetImage("assets/redAccentinfo.png"),
                        ),

                      ],
                    ),
                    title: Text(
                      "Tuma pesa kutoka kwenye simu",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Jaza namba ya simu unayotaka kuhamisha pesa, kisha bonyeza lipa. Utapokea maelekezo ya kuweka namba ya siri. Fuata maelekezo mpaka mwisho."),
                  ),
                ),
              ),

              SizedBox(
                height: 50,
              ),






              Text(
                DataStore.paymentInstitution,
                style: TextStyle(
                  decoration: TextDecoration.underline,
                    fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontSize: 18,
                ),
              ),


              Center(
                child:_statusView ? Text(
                    _status,
                    style: TextStyle(fontWeight: FontWeight.bold,color: Colors.blue.withOpacity(0.8))
                ) : null,
              ),
              Center(
                child:SizedBox(height: 48),
              ),

              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 62, vertical: 16),
                  child:TextField(
                    controller: numberController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary)),
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
                  )
              ),

              Expanded(
                child: Align(
                    alignment: FractionalOffset.bottomCenter,

                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ), backgroundColor: AppColors.primary,
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          child: const Text(
                            'Lipa',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'halter',
                              fontSize: 14,
                              //package: 'flutter_credit_card',
                            ),
                          ),
                        ),
                        onPressed: () async {
                          //_onLoading();

                          //numberController.clear();

                          if(numberController.text.length >= 8) {
                            var phoneNumber = "+255${numberController.text.trim()}";
                            DataStore.userNumber =phoneNumber;
                            print(phoneNumber);
                          }

                          showDialog(context: context,
                              builder: (BuildContext context){
                                return waitDialog(
                                  title: "Tafadhali Subiri",
                                  descriptions: "Malipo yanafanyika...",
                                  text: "",
                                );
                              }
                          );

                          try {

                            var cc = await HttpService.createPaymentIntentFromBankAcc("500","TZS");
                            print(cc);
                            Navigator.of(context, rootNavigator: true).pop('dialog');
                            //Navigator.pop(context);
                            //Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => paymentStatus()),
                            );


                          } on Exception catch (ex) {
                            print('Query error: $ex');
                          }


                        },
                      ),

                    )
                ),
              ),



            ]
        )

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