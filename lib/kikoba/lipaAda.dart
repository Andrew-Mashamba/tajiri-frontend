
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'DataStore.dart';
import 'appColor.dart';

import 'ada.dart';
import 'HttpService.dart';


class lipaAda extends StatefulWidget {
  const lipaAda({super.key});

  @override
  _AccountState createState() => _AccountState();
}


class _AccountState extends State<lipaAda> {
  final formatCurrency = NumberFormat.simpleCurrency();


  late Future<List<Ada>> itemsx;
  int listSize = 0;

  Future<List<Ada>> getData() async {
    print("AAAAAA DATA OGAS");

    List<Ada> list = [];
    var thenumber = DataStore.userNumber.replaceAll("+", "");
    //var thenumber = "12345";
    print("AAAAAA NAMBA$thenumber");
    String link = "${HttpService.baseUrl}ada-info";
    var res = await http.get(Uri.parse(link), headers: {"Accept": "application/json"});

    //print("AAAAAA "+res.body);

    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      //var userName = data["userName"];
      //print(data);
      //var vicobax = data["vicoba"];
      //print(vicobax);
      //var restx = vicobax["vicoba"] as List;
      print(data);
      //var rest = data["vicoba"] as List;
      //print(rest);
      list = data.map<Ada>((json) => Ada.fromJson(json)).toList();
      print(list);
    }
    print("List Size: ${list.length}");
    listSize = list.length;
    return list;
  }


  Future<List<Ada>> returnThelist(){
    return itemsx;
  }



  @override
  void initState() {
    super.initState();

    itemsx = getData();
    print(itemsx);

    //Using HttpService.baseUrl + ada-info

  }



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(

        body: SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Stack(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage("assets/katiba.png"),
                      ),
                      Positioned(
                        bottom: 0.0,
                        right: 1.0,
                        child: Container(
                          height: 20,
                          width: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      )
                    ],
                  ),
                  title: Text(
                    "Katiba ya kikundi",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Bonyeza hapa kuongeza kifungu"),
                ),

                displayAccoutList(),
              ],
            ),
          ),
        ),
        
      ),
    );
  }


  displayAccoutList() {

    //final itemsx = List<String>.generate(10, (i) => "Item $i");
    final itemsx = returnThelist();



    return Column(
      children: [

        Table(
            columnWidths: {
              0: FlexColumnWidth(1),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            border: TableBorder.all(
                color: Colors.black,
                style: BorderStyle.solid,
                width: 0.2),
            children: [
              TableRow( children: [
                Column(children:[Text('Mwezi', style: TextStyle(fontSize: 14.0))]),
                Column(children:[Text('Ada', style: TextStyle(fontSize: 14.0))]),
                Column(children:[Text('Penati', style: TextStyle(fontSize: 14.0))]),
                Column(children:[Text('', style: TextStyle(fontSize: 14.0))]),
              ]),
            ]),

        FutureBuilder(
            future: returnThelist(),
            builder: (context, snapshot) {
              return snapshot.data != null ? listViewWidget(snapshot.data as List<Ada>) : Center(child: CircularProgressIndicator());

              //return snapshot.data != null ? Text("hello") : Center(child: CircularProgressIndicator());

            }),



      ],
    );



  }


  Widget listViewWidget(List<Ada> article) {
    //print("XXXXXXXXXXXX");
    print(article.length);
    return ListView.builder(
          shrinkWrap: true,
          itemCount: article.length,
          //padding: const EdgeInsets.all(2.0),
          itemBuilder: (context, position) {
            return Column(
                children: [

                  Container(
                    decoration: BoxDecoration(color: Colors.white),
                    padding:
                    EdgeInsets.only(top: 0.0, bottom: 0.0, left: 0.0, right: 0.0),
                    child: Column(
                      children: <Widget>[

                        Table(
                          columnWidths: {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(1),
                            2: FlexColumnWidth(1),
                            3: FlexColumnWidth(1),
                          },
                          defaultColumnWidth: FixedColumnWidth(120.0),
                          border: TableBorder.all(
                              color: Colors.black,
                              style: BorderStyle.solid,
                              width: 0.2),
                          children: [

                            TableRow( children: [
                              Column(children:[Text(article[position].mwezi)]),
                              Column(children:[Text(article[position].amount)]),
                              Column(children:[Text(article[position].penati, style: TextStyle(fontSize: 12.0))]),
                              Column(children:[
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    backgroundColor: Colors.white,
                                    shadowColor: AppColors.primary.withValues(alpha: 0.3),
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.0)),
                                    minimumSize: const Size(100, 40),
                                  ),

                                  onPressed: () {
                                    setState(() {
                                      //istapped = 'Button tapped';
                                    });
                                  },
                                  child: Text('Lipa'),
                                ),

                                               ]),

                                                ],
                                                ),

                      ],
                    ),

                    ]
                  )

                  )

            ]
            );

          });

}




}