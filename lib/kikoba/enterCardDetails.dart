
import 'package:flutter/material.dart';
// import 'package:progress_indicators/progress_indicators.dart'; // replaced with CircularProgressIndicator
import 'DataStore.dart';

import 'constants.dart';
import 'HttpService.dart';
import 'paymentStatus.dart';
import 'waitDialog.dart';
import 'credit_card_form.dart';
import 'credit_card_model.dart';
import 'credit_card_widget.dart';
import 'appColor.dart';


class enterCardDetails extends StatefulWidget {
  const enterCardDetails({super.key});

  @override
  State<StatefulWidget> createState() {
    return MySampleState();
  }
}

class MySampleState extends State<enterCardDetails> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vikundi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFEFEF),
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text('Malipo kwa kadi'),
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
        body: SafeArea(
          child: Column(
            children: <Widget>[

              //pleaseWait(),

              Card(
                color: Colors.white,
                elevation: 0.0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Stack(
                      children: <Widget>[
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: AssetImage("assets/redAccentinfo.png"),
                        ),

                      ],
                    ),
                    title: Text(
                      "Malipo kwa kadi ya ${DataStore.paymentInstitution}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Jaza taarifa zote, kisha bonyeza Lipa"),
                  ),
                ),
              ),

              CreditCardWidget(
                cardNumber: cardNumber,
                expiryDate: expiryDate,
                cardHolderName: cardHolderName,
                cvvCode: cvvCode,
                showBackView: isCvvFocused,
                obscureCardNumber: true,
                obscureCardCvv: true,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      CreditCardForm(
                        //formKey: formKey,
                        obscureCvv: true,
                        obscureNumber: true,
                        cardNumber: cardNumber,
                        cvvCode: cvvCode,
                        cardHolderName: cardHolderName,
                        expiryDate: expiryDate,
                        themeColor: Colors.blue,
                        cardNumberDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Namba ya kadi',
                          hintText: 'XXXX XXXX XXXX XXXX',
                        ),
                        expiryDateDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Tarehe ya kadi kuisha',
                          hintText: 'XX/XX',
                        ),
                        cvvCodeDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'CVV',
                          hintText: 'XXX',
                        ),
                        cardHolderDecoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Jina la mmiliki wa kadi',
                        ),
                        onCreditCardModelChange: onCreditCardModelChange,
                      ),
                      ElevatedButton(
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
                            var cc = await HttpService.createPaymentIntent("500","TZS",cardNumber, expiryDate,cardHolderName,cvvCode);
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
                      )

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      cardNumber = creditCardModel!.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }


  Dialog pleaseWait(){
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Constants.padding),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: contentBox(context),
    );
  }


  contentBox(context){
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: Constants.padding,top: Constants.avatarRadius
              + Constants.padding, right: Constants.padding,bottom: Constants.padding
          ),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: [
                BoxShadow(color: Colors.black,offset: Offset(0,10),
                    blurRadius: 10
                ),
              ]
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 20),

              Text("Tafadhali Subiri",style: TextStyle(fontSize: 22,fontWeight: FontWeight.w600),),
              SizedBox(height: 15,),
              Text("Malipo yanaendelea",style: TextStyle(fontSize: 14),textAlign: TextAlign.center,),
              SizedBox(height: 22,),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      shadowColor: AppColors.primary,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0)),
                      minimumSize: Size(100, 40), //////// HERE
                    ),
                    onPressed: (){
                      Navigator.of(context).pop();
                    },
                    child: Text("OK",style: TextStyle(fontSize: 18),)),
              ),
            ],
          ),
        ),
        Positioned(
          left: Constants.padding,
          right: Constants.padding,
          child: CircleAvatar(
            backgroundColor: Colors.transparent,
            radius: Constants.avatarRadius,
            child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(Constants.avatarRadius)),
                child: Image.asset("assets/model.jpeg")
            ),
          ),
        ),
      ],
    );
  }





}