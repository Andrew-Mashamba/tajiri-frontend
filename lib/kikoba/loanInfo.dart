/// @deprecated This file is deprecated. Use [LoanDetailPage] from `lib/pages/LoanDetailPage.dart` instead.
/// This legacy loan info display has been replaced by a modern detail view with timeline and schedule.
/// Keeping for backward compatibility with legacy code paths.

import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vicoba/DataStore.dart';
import 'package:vicoba/appColor.dart';

import 'HttpService.dart';


class loanInfo extends StatefulWidget {
  const loanInfo({super.key});


  @override
  _loanInfoState createState() => _loanInfoState();
}


class _loanInfoState extends State<loanInfo> {

  final formatCurrency = NumberFormat.simpleCurrency();

  String loanID = "";
  String amount =  "";
  String interest =  "";
  String rejesho =  "";
  String mdhaminiId =  "";
  String month =  "";
  String tenure =  "";
  String performance ="";
  String disbursementNumber ="";
  String mdhamini ="";
  String mdhaminiphone = "";

  @override
  void initState() {
    super.initState();
    getLoanInfo();

  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text('Taarifa za mkopo'),
      ),
      body: Center(


        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,


          children: <Widget>[

            SizedBox(
              width: 10,
            ),

            DataTable(
              columns: [

                DataColumn(label: Text(
                    DataStore.currentKikobaName,
                    style: TextStyle(fontFamily: 'halter',fontSize: 16, fontWeight: FontWeight.bold)
                )),
                DataColumn(label: Text(
                    '',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                )),
              ],
              rows: [
                DataRow(cells: [

                  DataCell(Text('Aina ya huduma',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text('Mkopo',textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Jina la mjumbe',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(DataStore.currentUserName,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Namba ya mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(loanID,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Kiasi cha mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(amount,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Riba ya mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(interest,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Muda wa mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(tenure,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Rejesho la mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(rejesho,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Jina la mdhamini',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text("$mdhamini - $mdhaminiphone",textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Tarehe ya kutolewa mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(month,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Mwenendo wa mkopo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(performance,textAlign: TextAlign.right)),
                ]),
                DataRow(cells: [

                  DataCell(Text('Namba iliyo pokea pesa',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                  DataCell(Text(disbursementNumber,textAlign: TextAlign.right)),
                ]),
              ],
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
                        ), backgroundColor: Colors.redAccent,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        child: const Text(
                          'Sawa',
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

                        AwesomeDialog(
                          context: context,
                          headerAnimationLoop: false,
                          dialogType: DialogType.info,
                          body: Center(
                            child: SizedBox(
                              height: 650,
                              width: MediaQuery.of(context).size.width,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[

                                    Text(
                                      "Malipo ya ada",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontFamily: 'halter',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),




                                    DataTable(
                                      columns: [

                                        DataColumn(label: Text(
                                            'THE BOYS',
                                            style: TextStyle(fontFamily: 'halter',fontSize: 16, fontWeight: FontWeight.bold)
                                        )),
                                        DataColumn(label: Text(
                                            '',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                                        )),
                                      ],
                                      rows: [
                                        DataRow(cells: [

                                          DataCell(Text('Aina ya malipo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('Ada',textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Namba ya kumbukumbu',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('789876767654',textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Namba ya kikundi',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text("787878787",textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Namba ya mwanachana',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('AC4455',textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Jina la mwanachama',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('Andrew Mashamba',textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Mtandao wa malipo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('Visa Card',textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Namba ya malipo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('3456 **** **** 7898',textAlign: TextAlign.right)),
                                        ]),
                                        DataRow(cells: [

                                          DataCell(Text('Tarehe ya malipo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('06/07/2021 08:44 am',textAlign: TextAlign.right)),
                                        ]),

                                        DataRow(cells: [

                                          DataCell(Text('Kiasi cha malipo',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('500.00 /=',textAlign: TextAlign.right)),
                                        ]),

                                        DataRow(cells: [

                                          DataCell(Text('Status ya muamala',style: TextStyle(fontFamily: 'halter',fontWeight: FontWeight.bold))),
                                          DataCell(Text('Kamilifu',textAlign: TextAlign.right)),
                                        ]),
                                      ],
                                    ),





                                    Expanded(
                                      child: Align(
                                        alignment: FractionalOffset.bottomCenter,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.0),
                                            ), backgroundColor: AppColors.primary,
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.all(8),
                                            child: const Text(
                                              'Pakua',
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


                                          },
                                        ),
                                      ),
                                    ),





                                  ],
                                ),
                              ),
                            ),

                          ),

                          title: 'This is Ignored',
                          desc:
                          'Dialog description here..................................................',
                          //btnOkIcon: Icons.check_circle,
                        ).show();



                      },
                    ),

                  )
              ),
            ),
          ],





        ),

      ),
    );
  }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }

  void getLoanInfo() async{


    // var data = DataStore.mikopoList;
    // List<mkopo> namelist = List<mkopo>.from(data.map((i){
    //   print("MIKOPO LIST : "+mkopo.fromJSON(i).toString());
    //   return mkopo.fromJSON(i);
    // })
    // );
print("INITIAL LOAN ID : ${DataStore.loanInfoID}");
    await HttpService.loanInfo(DataStore.loanInfoID).then((String result){

      Map<String, dynamic> map = json.decode(result);
      Map<String, dynamic> data = map["loan"];
      Map<String, dynamic> mdhaminix = map["mdhamini"];
      setState(() {
        loanID = data["loanID"];
        amount = formatCurrency.format(double.parse(data["amount"])).replaceAll("\$", "");
        interest = data["interest"];
        tenure = "Miezi ${data["tenure"]}";
        rejesho = formatCurrency.format(double.parse(data["rejesho"])).replaceAll("\$", "");
        mdhaminiId = data["mdhaminiId"];
        month = data["month"];
        performance = data["performance"];
        disbursementNumber = data["disbursementNumber"];
        mdhamini = mdhaminix["name"];
        mdhaminiphone = mdhaminix["phone"];
      });

      //print(data["kikobaID"]);interest




    });

  }



}


