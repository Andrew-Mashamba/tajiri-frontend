

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:vicoba/DataStore.dart';
import 'package:vicoba/waitDialog.dart';

import 'HttpService.dart';
import 'loanRequested.dart';
import 'networkError.dart';



class mchangoRequestKwaNiaba extends StatefulWidget {
  const mchangoRequestKwaNiaba({super.key});

  @override
  _FormWidgetsDemoStatex createState() => _FormWidgetsDemoStatex();
}

class _FormWidgetsDemoStatex extends State<mchangoRequestKwaNiaba> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  DateTime date = DateTime.now();
  double maxValue2 = 0;
  double maxValue1 = 0;
  bool brushedTeeth = false;
  bool enableFeature = false;

  String mdhaminiName = "Mdhamini";
  String mdhaminiMaelezo = "Bonyeza hapa kuchagua mdhamini";
  String mdhaminiId ="100";

  final formatCurrency = NumberFormat.simpleCurrency();

  Widget showData = Text("");

  TextEditingController maelezoController = TextEditingController();
  late DateTime tarehe;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maombi ya mchango kwa niaba'),
      ),
      body: Form(
        key: _formKey,
        child: Scrollbar(
          child: Align(
            alignment: Alignment.topCenter,
            child: ListView(children: [

              Card(
                color: Colors.white,
                elevation: 5.0,
                child: Padding(
                  padding: const EdgeInsets.all(0.0),
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
                      "Jinsi ya kuomba mchango",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Kwa kutumia vitelezo, chagua lengo la makusanyo unayo taka kufikia. Kisha chagua kiwango cha chini cha mchago kwa mwanakikundi."),
                  ),
                ),
              ),


              Card(
                elevation: 5.0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ...[

                          Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      'Jina la mchangiwa',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    Text(
                                      DataStore.kwaniabaName,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Eleza madhumuni ya huu mchango',
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: maelezoController,
                                  minLines: 1,
                                  maxLines: 10,
                                  keyboardType: TextInputType.multiline,
                                  decoration: InputDecoration(
                                    hintText: 'Maelezo',
                                    hintStyle: TextStyle(
                                        color: Colors.grey
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Weka maelezo';
                                    }
                                    return null;
                                  },
                                ),
                              ]),

                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kiasi unacho tarajia kupata kutoka kwa wanakikundi',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                              Text(
                                intl.NumberFormat.currency(
                                    symbol: "TZS ", decimalDigits: 0)
                                    .format(maxValue1),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Slider(
                                activeColor: Colors.redAccent,
                                inactiveColor: Colors.redAccent[100],
                                min: 0,
                                max: 50000000,
                                divisions: 500,
                                value: maxValue1,
                                onChanged: (value) {
                                  setState(() {
                                    maxValue1 = value;
                                    //getThelist(double.parse(DataStore.riba),maxValue, value);
                                  });
                                },
                              ),
                            ],
                          ),




                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Kiwango cha chini cha mchango',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                              Text(
                                intl.NumberFormat.currency(
                                    symbol: "TZS ", decimalDigits: 0)
                                    .format(maxValue2),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Slider(
                                activeColor: Colors.redAccent,
                                inactiveColor: Colors.redAccent[100],
                                min: 0,
                                max: 1000000,
                                divisions: 1000,
                                value: maxValue2,
                                onChanged: (value) {
                                  setState(() {
                                    maxValue2 = value;
                                    //getThelist(double.parse(DataStore.riba),maxValue, value);
                                  });
                                },
                              ),
                            ],
                          ),


                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Chagua tarehe ya mwisho ya mchango',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              SizedBox(
                                height: 100,
                                child:

                                CupertinoTheme(
                                  data: CupertinoThemeData(
                                    textTheme: CupertinoTextThemeData(
                                      pickerTextStyle: TextStyle(color: Colors.redAccent),
                                      dateTimePickerTextStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                  ),
                                  child: CupertinoDatePicker(
                                    mode: CupertinoDatePickerMode.date,
                                    initialDateTime: DateTime(now.year, now.month, now.day),
                                    onDateTimeChanged: (DateTime newDateTime) {
                                      // Do something
                                      tarehe = newDateTime;
                                    },
                                  ),
                                ),



                              ),
                            ],
                          ),





                          Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [


                                SizedBox(height: 30),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ), backgroundColor: Colors.redAccent,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    child: const Text(
                                      'Omba Mchango',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontFamily: 'halter',
                                        fontSize: 14,
                                        //package: 'flutter_credit_card',
                                      ),
                                    ),
                                  ),
                                  onPressed: () async {

                                    showDialog(context: context,
                                        builder: (BuildContext context){
                                          return waitDialog(
                                            title: "Tafadhali Subiri",
                                            descriptions: "Maombi yako yanatumwa...",
                                            text: "",
                                          );
                                        }
                                    );



                                    try {
                                      DataStore.ainayaMchango="kawaida";
                                      DataStore.paymentInstitution=DataStore.userNumberMNO;
                                      var loanID  = "LD${DateTime.now().millisecondsSinceEpoch}";



                                      HttpService.ombaMchangoKwaniaba(DataStore.ainayaMchango, maelezoController.text,DateFormat('dd-MM-yyyy').format(tarehe),maxValue1.toString(),maxValue2.toString()).then((String result){
                                        setState(() {
                                          print (result);

                                          if(result.trim() == "7"){

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => loanRequested()),
                                            );
                                          }else{

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => networkError()),
                                            );

                                          }


                                        });
                                      });



                                    } on Exception catch (ex) {
                                      print('Query error: $ex');
                                    }

                                    //_onLoading();
                                    //print("HELLO");
                                    //print(pmt(rate: 0.1 / 12, nper: 12, pv: 1200));


                                    // final num interestPaid = payments.fold(0, (num p, Map<String, num> c) => p + c['ipmt']);
                                    // print(interestPaid);

                                  },
                                ),



                              ])


                        ].expand(
                              (widget) => [
                            widget,
                            const SizedBox(
                              height: 24,
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),



            ],),

          ),
        ),
      ),
    );
  }









}

