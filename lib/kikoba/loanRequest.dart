/// @deprecated This file is deprecated. Use [MikopoPage] from `lib/pages/MikopoPage.dart` instead.
/// This legacy loan request form has been replaced by a modern multi-step wizard.
/// Keeping for backward compatibility with legacy code paths.

import 'dart:convert';
import 'dart:math';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:vicoba/DataStore.dart';
import 'package:vicoba/paymentModal.dart';
import 'package:vicoba/paymentStatus.dart';
import 'package:vicoba/waitDialog.dart';
import 'package:vicoba/appColor.dart';

import 'HttpService.dart';
import 'loanRequested.dart';
import 'membersModal.dart';
import 'networkError.dart';



class loanRequest extends StatefulWidget {
  const loanRequest({super.key});

  @override
  _FormWidgetsDemoState createState() => _FormWidgetsDemoState();
}

class _FormWidgetsDemoState extends State<loanRequest> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  DateTime date = DateTime.now();
  double maxValue = 0;
  double maxValue2 = 0;
  bool brushedTeeth = false;
  bool enableFeature = false;

  String mdhaminiName = "Mdhamini";
  String mdhaminiMaelezo = "Bonyeza hapa kuchagua mdhamini";
  String mdhaminiId ="100";

  final formatCurrency = NumberFormat.simpleCurrency();

  Widget showData = Text("");


  Route _routeTopaymentStatus() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => paymentStatus(),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maombi ya mkopo'),
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
                         // backgroundImage: AssetImage("assets/redAccentinfo.png"),
                         backgroundColor: AppColors.textPrimary
                        ),

                      ],
                    ),
                    title: Text(
                      "Jinsi ya kuomba mkopo",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Chagua mdhamini, kisha kwa kutumia vitelezo, chagua muda wa mkopo na kiasi. Kagua ratiba kisha bonyeza Omba mkopo"),
                  ),
                ),
              ),

              Card(

                 elevation: 5.0,
            color: AppColors.secondary, // ✅ Green background
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),



                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ...[


                    InkWell(
                    child: Card(
                            color: Colors.black12,
                            elevation: 0.0,
                            child: Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: ListTile(
                                leading: Stack(
                                  children: <Widget>[
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: AssetImage("assets/no-avatar.png"),
                                    ),

                                  ],
                                ),
                                title: Text(
                                  mdhaminiName,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(mdhaminiMaelezo),
                              ),
                            ),
                          ),
                    onTap: () {
                      showusers();
                    },
                  ),


                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Muda wa mkopo (Miezi)',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ],
                              ),
                              Text(
                                intl.NumberFormat.currency(
                                    symbol: "MIEZI ", decimalDigits: 0)
                                    .format(maxValue),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Slider(
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.primary,
                                min: 0,
                                max: 12,
                                divisions: 12,
                                value: maxValue,
                                onChanged: (value) {
                                  setState(() {
                                    maxValue = value;
                                    DataStore.riba ??= 8.0;
                                    getThelist(DataStore.riba,value,maxValue2);
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
                                    'Kiasi cha mkopo',
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
                                activeColor: AppColors.primary,
                                inactiveColor: AppColors.primary,
                                min: 0,
                                max: 10000000,
                                divisions: 500,
                                value: maxValue2,
                                onChanged: (value) {
                                  setState(() {
                                    maxValue2 = value;
                                    DataStore.riba ??= 8.0;
                                    getThelist(DataStore.riba,maxValue, value);
                                  });
                                },
                              ),
                            ],
                          ),


                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [


                        showData,

                        SizedBox(height: 30),

                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ), backgroundColor: AppColors.primary,
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            child: const Text(
                              'Omba Mkopo',
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

                            if(DataStore.paymentService == "topup"){

                              DataStore.paymentChanel="MNO";
                              DataStore.paymentInstitution=DataStore.userNumberMNO;
                              var loanID  = "LD${DateTime.now().millisecondsSinceEpoch}";


                              HttpService.topupRequestHttp(
                                  maxValue2,
                                  maxValue,
                                  mdhaminiId,
                                  loanID,
                                  DataStore.ratibaYaMkopo,
                                  DataStore.paymentAmount,
                                  "TZS",
                                  DataStore.userNumber,
                                  DataStore.paymentService,
                                  DataStore.paidServiceId,
                                  DataStore.personPaidId,
                                  DataStore.maelezoYaMalipo
                              ).then((String result){
                                setState(() {
                                  print (result);
                                  var data = json.decode(result);
                                  print ("TOP UP RESULTS : $data");



                                  print("PAYMENT RESULTS : $result");


                                  var postComment = DataStore.maelezoYaMalipo;
                                  var uuid = Uuid();
                                  DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
                                  String thedate = dateFormat.format(DateTime.now());


                                  CollectionReference baraza = FirebaseFirestore.instance.collection('${DataStore.currentKikobaId}barazaMessages');


                                  // Call the user's CollectionReference to add a new user
                                  baraza.add({
                                    'posterName': DataStore.currentUserName,
                                    'posterId': DataStore.currentUserId,
                                    'posterNumber': DataStore.userNumber,
                                    'posterPhoto': "",
                                    'postComment': postComment,
                                    'postImage': '',
                                    'postType': 'taarifaYakujiunga',
                                    'postId': uuid.v4(),
                                    'postTime': thedate,
                                    'kikobaId': DataStore.currentKikobaId
                                  }).then((value) =>

                                  //sendNotifications(postComment,namba)
                                  print("done")

                                  ).catchError((error) =>

                                      print("Failed to add user: $error")
                                  );



                                  Navigator.of(context, rootNavigator: true).pop('dialog');
                                  Navigator.of(context).pushReplacement(_routeTopaymentStatus());




                                });
                              });



                            }else{

                              try {
                                DataStore.paymentChanel="MNO";
                                DataStore.paymentInstitution=DataStore.userNumberMNO;
                                var loanID  = "LD${DateTime.now().millisecondsSinceEpoch}";
                                var cc = await HttpService.loanRequestHttp(maxValue2,maxValue,mdhaminiId,loanID,DataStore.ratibaYaMkopo);
                                print(cc);
                                print("HAPO JUU UU");
                                if(cc == "7"){
                                  Navigator.of(context, rootNavigator: true).pop('dialog');
                                  //Navigator.pop(context);
                                  //Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => loanRequested()),
                                  );
                                }else{
                                  Navigator.of(context, rootNavigator: true).pop('dialog');
                                  //Navigator.pop(context);
                                  //Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => networkError()),
                                  );

                                }



                              } on Exception catch (ex) {
                                print('Query error: $ex');
                              }

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




  getThelist(double interest,double months, double amount){
    print(interest);
    print(months);
    print(amount);
    List<Widget>? listings2 = [];
    List<TableRow>? TableRows = [];

    TableRows.add(
      TableRow( children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Padding(
            padding: EdgeInsets.all(5),
            child:Text('Tarehe', style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)))]),
        Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Padding(
            padding: EdgeInsets.all(5),
            child:Text('Principal', style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)))]),
        Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Padding(
            padding: EdgeInsets.all(5),
            child:Text('Riba', style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)))]),
        Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Padding(
            padding: EdgeInsets.all(5),
            child:Text('Rejesho', style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)))]),
      ]),
    );
    var kiasiSum = 0.0;
    var kiasiRiba = 0.0;
    var kiasiPrincipal = 0.0;


    final Iterable<Map<String, num>> payments =
    List<int>.generate(months.toInt(), (int index) => index + 1).map((int per) =>
    <String, num>{
      'per': per,
      'pmt': pmt(rate: (interest/100) / 12, nper: months, pv: amount),
      'ppmt':
      ppmt(rate: (interest/100) / 12, per: per, nper: months, pv: amount),
      'ipmt':
      ipmt(rate: (interest/100) / 12, per: per, nper: months, pv: amount),
    });

    //payments.forEach(print);
    List<paymentModal> paymentsTogo = [];
    DateTime now = DateTime.now();
    DateTime date = DateTime(now.year, now.month, now.day);
    var newDate = DateTime(date.year, date.month, date.day);

    for (var value in payments) {
      print(value['pmt']);
      if(value.isNotEmpty){
        kiasiSum = kiasiSum + value['pmt']!.toDouble();
        kiasiRiba = kiasiRiba + value['ipmt']!.toDouble();
        kiasiPrincipal = kiasiPrincipal + value['ppmt']!.toDouble();
        var f = value['per'];
        newDate = DateTime(date.year, date.month + f!.toInt(), date.day);

        var dateTime = DateTime.parse(newDate.toString());

        var formate1 = "${dateTime.day}-${dateTime.month}-${dateTime.year}";


        paymentModal myPayment = paymentModal(date: formate1, ppmt: (value['ppmt']!*-1), ipmt: (value['ipmt']!*-1), pmt:(value['pmt']!*-1));
        paymentsTogo.add(myPayment);

        TableRows.add(
          TableRow( children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formate1))]),
            Column(crossAxisAlignment: CrossAxisAlignment.end,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formatCurrency.format((value['ppmt']!*-1)).replaceAll("\$", "")))]),
            Column(crossAxisAlignment: CrossAxisAlignment.end,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formatCurrency.format((value['ipmt']!*-1)).replaceAll("\$", "")))]),
            Column(crossAxisAlignment: CrossAxisAlignment.end,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formatCurrency.format((value['pmt']!*-1)).replaceAll("\$", "")))]),
          ]),
        );

      }
    }

    TableRows.add(
      TableRow(
          decoration: BoxDecoration(color: AppColors.secondary),
          children: [

            Column(crossAxisAlignment: CrossAxisAlignment.start,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text("Jumla"))]),

            Column(crossAxisAlignment: CrossAxisAlignment.end,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formatCurrency.format((kiasiPrincipal*-1)).replaceAll("\$", "")))]),

            Column(crossAxisAlignment: CrossAxisAlignment.end,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formatCurrency.format((kiasiRiba*-1)).replaceAll("\$", "")))]),

            Column(crossAxisAlignment: CrossAxisAlignment.end,children:[Padding(
                padding: EdgeInsets.all(5),
                child:Text(formatCurrency.format((kiasiSum*-1)).replaceAll("\$", "")))]),
          ]),
    );


    setState(() {
      //var json = jsonEncode(paymentsTogo.);
      //String json = jsonEncode(paymentModal.fromJSON(paymentsTogo) );
      DataStore.ratibaYaMkopo = paymentsTogo;

      showData = Column(children:  <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ratiba ya marejesho',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
        SizedBox(
          height: 5,
        ),
        Container(
            child: Table(
                border: TableBorder.all(
                    color: AppColors.primary,
                    style: BorderStyle.solid,
                    width: 1),
                children: TableRows))]);

    });

    //return listings2;
  }


  void showusers() {

    AwesomeDialog(
      context: context,
      headerAnimationLoop: false,
      dialogType: DialogType.info,
      body: ListView(
        shrinkWrap: true,
        children: [

          Column(crossAxisAlignment: CrossAxisAlignment.center,children:[Padding(
              padding: EdgeInsets.all(5),
              child:Text("Chagua mdhamini",
                  style: TextStyle(fontSize: 16.0,fontWeight: FontWeight.bold)
              ))]),



          SizedBox(
            width: 10,
          ),

          datalist(),

          SizedBox(
            width: 20,
          ),
        ],
      ),

    ).show();




  }





  Widget datalist(){
    //print(data);
    //print("LOOOK HEERE");
    //print(DataStore.transactionsList);
    List<Widget>? membersShowList = [];


    var data = DataStore.membersList;
    print(data);
    List<member> namelist = List<member>.from(data.map((i){


      print(member.fromJSON(i).phone);
      membersShowList.add(
      InkWell(
        child: Card(
          color: Colors.black12,
          elevation: 0.0,
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: ListTile(
              leading: Stack(
                children: <Widget>[
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage("assets/no-avatar.png"),
                  ),

                ],
              ),
              title: Text(
                member.fromJSON(i).name,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(member.fromJSON(i).phone),
            ),
          ),
        ),
        onTap: () {
          setState(() {
            mdhaminiName = member.fromJSON(i).name;
            mdhaminiMaelezo = member.fromJSON(i).phone;
            mdhaminiId = member.fromJSON(i).userId;
          });
          Navigator.of(context, rootNavigator: true).pop('dialog');
        },
      )
      );





      return member.fromJSON(i);
    })
    );


    return Column(children:  membersShowList);


  }










  static num fv(
      {required num rate,
        required num nper,
        required num pmt,
        required num pv,
        bool end = true}) {
    final int when = end ? 0 : 1;
    final num temp = pow(1 + rate, nper);
    final num fact =
    (rate == 0) ? nper : ((1 + rate * when) * (temp - 1) / rate);
    return -(pv * temp + pmt * fact);
  }

  static num pmt(
      {required num rate,
        required num nper,
        required num pv,
        num fv = 0,
        bool end = true}) {
    final int when = end ? 0 : 1;
    final num temp = pow(1 + rate, nper);
    final num maskedRate = (rate == 0) ? 1 : rate;
    final num fact = (rate == 0)
        ? nper
        : ((1 + maskedRate * when) * (temp - 1) / maskedRate);
    return -(fv + pv * temp) / fact;
  }


  static num nper(
      {required num rate,
        required num pmt,
        required num pv,
        num fv = 0,
        bool end = true}) {
    final int when = end ? 0 : 1;

    try {
      final num A = -(fv + pv) / pmt;
      final num z = pmt * (1 + rate * when) / rate;
      final num B = log((-fv + z) / (pv + z)) / log(1 + rate);
      return (rate == 0) ? A : B;
    } catch (e) {
      return (-fv + pv) / pmt;
    }
  }


  static num ipmt(
      {required num rate,
        required num per,
        required num nper,
        required num pv,
        num fv = 0,
        bool end = true}) {
    final num totalPmt = pmt(rate: rate, nper: nper, pv: pv, fv: fv, end: end);
    num ipmt =
        _rbl(rate: rate, per: per, pmt: totalPmt, pv: pv, end: end) * rate;
    ipmt = end ? ipmt : ipmt / (1 + rate);
    ipmt = (!end && (per == 1)) ? 0 : ipmt;
    return ipmt;
  }

  static num _rbl(
      {required num rate,
        required num per,
        required num pmt,
        required num pv,
        bool end = true}) {
    return fv(rate: rate, nper: per - 1, pmt: pmt, pv: pv, end: end);
  }


  static num ppmt(
      {required num rate,
        required num per,
        required num nper,
        required num pv,
        num fv = 0,
        bool end = true}) {
    final num total = pmt(rate: rate, nper: nper, pv: pv, fv: fv, end: end);
    return total -
        ipmt(rate: rate, per: per, nper: nper, pv: pv, fv: fv, end: end);
  }


  static num pv(
      {required num rate,
        required num nper,
        required num pmt,
        required num fv,
        bool end = true}) {
    final int when = end ? 0 : 1;
    final num temp = pow(1 + rate, nper);
    final num fact =
    (rate == 0) ? nper : ((1 + rate * when) * (temp - 1) / rate);
    return -(fv + pmt * fact) / temp;
  }

  // Computed with Sage
  //  (y + (r + 1)^n*x + p*((r + 1)^n - 1)*(r*w + 1)/r)/(n*(r + 1)^(n - 1)*x -
  //  p*((r + 1)^n - 1)*(r*w + 1)/r^2 + n*p*(r + 1)^(n - 1)*(r*w + 1)/r +
  //  p*((r + 1)^n - 1)*w/r)
  static num _g_div_gp(num r, num n, num p, num x, num y, num w) {
    final num t1 = pow(r + 1, n);
    final num t2 = pow(r + 1, n - 1);
    return (y + t1 * x + p * (t1 - 1) * (r * w + 1) / r) /
        (n * t2 * x -
            p * (t1 - 1) * (r * w + 1) / pow(r, 2) +
            n * p * t2 * (r * w + 1) / r +
            p * (t1 - 1) * w / r);
  }

  static num rate(
      {required num nper,
        required num pmt,
        required num pv,
        required num fv,
        bool end = true,
        num guess = 0.1,
        num tol = 1e-6,
        num maxIter = 100}) {
    final int when = end ? 0 : 1;

    num rn = guess;
    num iterator = 0;
    bool close = false;
    while ((iterator < maxIter) && !close) {
      final num rnp1 = rn - _g_div_gp(rn, nper, pmt, pv, fv, when);
      final num diff = (rnp1 - rn).abs();
      close = diff < tol;
      iterator += 1;
      rn = rnp1;
    }

    return rn;
  }


  static num npv({required num rate, required List<num> values}) {
    return List<int>.generate(values.length, (int index) => index)
        .map((int index) => values[index] / pow(1 + rate, index))
        .fold(0, (num p, num c) => p + c);
  }

  static num _npvPrime({required num rate, required List<num> values}) {
    return List<int>.generate(values.length, (int index) => index)
        .map((int index) => -index * values[index] / pow(1 + rate, index + 1))
        .fold(0, (num p, num c) => p + c);
  }

  static num _npv_div_npvPrime(num rate, List<num> values) {
    final num t1 = npv(rate: rate, values: values);
    final num t2 = _npvPrime(rate: rate, values: values);
    return t1 / t2;
  }



  static num irr(
      {required List<num> values,
        num guess = 0.1,
        num tol = 1e-6,
        num maxIter = 100}) {
    num rn = guess;
    num iterator = 0;
    bool close = false;
    while ((iterator < maxIter) && !close) {
      final num rnp1 = rn - _npv_div_npvPrime(rn, values);
      final num diff = (rnp1 - rn).abs();
      close = diff < tol;
      iterator += 1;
      rn = rnp1;
    }

    return rn;
  }




}

