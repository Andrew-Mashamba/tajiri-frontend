import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'HttpService.dart';
import 'DataStore.dart';

import 'getKikobaData.dart';
import 'majukumu.dart';

class majukumu extends StatefulWidget {

  const majukumu({super.key});


  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<majukumu> {
  int listSize = 9999;

  Future<List<majukumuData>> getData2x() async {
    print("AAAAAA DATA OGAS");

    List<majukumuData> list = [];
    var thenumber = DataStore.userNumber.replaceAll("+", "");
    //var thenumber = "12345";
    print("AAAAAA NAMBA$thenumber");
    String link = "${HttpService.baseUrl}majukumu?currentKikobaId=${DataStore.currentKikobaId}";
    var res = await http.get(Uri.parse(link), headers: {"Accept": "application/json"});

    //print("AAAAAA "+res.body);

    if (res.statusCode == 200) {
      var data = json.decode(res.body);
      //var userName = data["userName"];
      print("HAPA BXX");
      print(data);

      var vicobax = data["majukumu"];
      //print(vicobax);
      var restx = vicobax["majukumu"] as List;

      print(restx);
      //var rest = data["vicoba"] as List;
      //print(rest);
      list = restx.map<majukumuData>((json) => majukumuData.fromJson(json)).toList();
      //print(list);
    }
    print("List Size: ${list.length}");

    listSize = list.length;



    return list;
  }



  Widget listViewWidget(List<majukumuData> majukumux) {


    return Container(
      child: ListView.builder(
          itemCount: majukumux.length,
          padding: const EdgeInsets.all(2.0),
          itemBuilder: (context, position) {
            var majukumuType = "";
            if(majukumux[position].type == "loanRequest"){
              majukumuType = "Maombi ya mkopo";
            }
            return Column(
                children: [
                  ListTile(
                    title: Text(majukumuType, style: TextStyle(fontSize: 15.0, color: Colors.black, fontWeight: FontWeight.bold),),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [

                      Text(majukumux[position].maelezo),
                      SizedBox(
                        height: 10,
                      ),
                      Divider(),
                      Row(
                          children: [
                            Row(children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        margin: const EdgeInsets.only(left: 0.0, bottom: 10.0),
                                        child:
                                    Padding(
                                      padding: EdgeInsets.all(0.0),
                                      child: Text("Mwenyekiti",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14.0)),
                                    ),
                                    ),
                                    Container(
                                        margin: const EdgeInsets.only(left: 0.0, bottom: 10.0),
                                        child:
                                    Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text("Katibu",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14.0)),
                                    ),
                                    ),
                                    Container(
                                        margin: const EdgeInsets.only(left: 0.0, bottom: 10.0),
                                        child:
                                    Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text("Mdhamini",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14.0)),
                                    ),
                                    ),
                                    Container(
                                        margin: const EdgeInsets.only(left: 0.0, bottom: 10.0),
                                        child:
                                        Padding(
                                      padding: EdgeInsets.all(5.0),
                                      child: Text("Wajumbe",
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14.0)),
                                    ),
                                    )
                                  ])

                            ],),

                            Row(children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        margin: const EdgeInsets.only(left: 60.0, bottom: 10.0),
                                    child: Padding(
                                      padding: EdgeInsets.all(0.0),
                                      child: checkVote(majukumux[position].chairmansVote),

                                    ),

                                    ),

                                    Container(
                                      margin: const EdgeInsets.only(left: 60.0, bottom: 10.0),
                                      child: Padding(
                                        padding: EdgeInsets.all(0.0),
                                        child:checkVote(majukumux[position].secretarysVote),

                                      ),

                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(left: 60.0, bottom: 10.0),
                                      child: checkVote(majukumux[position].quarantorsVote),

                                    ),
                                    Row(children: [

                                      Container(
                                        margin: const EdgeInsets.only(left: 60.0, bottom: 10.0),
                                        child: Padding(
                                          padding: EdgeInsets.all(0.0),
                                          child:Container(
                                            decoration: BoxDecoration(
                                              //color: Colors.white,
                                              borderRadius: BorderRadius.circular(180),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(color: Colors.redAccent, spreadRadius: 3),
                                              ],
                                            ),
                                            width: 20,
                                            height: 20,
                                            //margin: EdgeInsets.all(10),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(50),
                                              child:             Icon(
                                                Icons.done_outline_rounded,
                                                color: Colors.redAccent,
                                                size: 15.0,
                                                semanticLabel: '',
                                              ),
                                            ),
                                          ),

                                        ),

                                      ),

                                      Container(
                                        margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                                        child:Text(majukumux[position].othersVote,
                                            style: TextStyle(
                                                color: Colors.green[600],
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold))
                                      ),

                                        Container(
                                        margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                                        child: Padding(
                                          padding: EdgeInsets.all(0.0),
                                          child:Container(
                                            decoration: BoxDecoration(
                                              //color: Colors.white,
                                              borderRadius: BorderRadius.circular(180),
                                              color: Colors.white,
                                              boxShadow: [
                                                BoxShadow(color: Colors.blue, spreadRadius: 3),
                                              ],
                                            ),
                                            width: 20,
                                            height: 20,
                                            //margin: EdgeInsets.all(10),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(50),
                                              child:             Icon(
                                                Icons.done_outline_rounded,
                                                color: Colors.blue[300],
                                                size: 15.0,
                                                semanticLabel: '',
                                              ),
                                            ),
                                          ),

                                        ),

                                      ),

                                      Container(
                                          margin: const EdgeInsets.only(left: 10.0, bottom: 10.0),
                                          child:Text(majukumux[position].othersVoteNo,
                                              style: TextStyle(
                                              color: Colors.blue[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold))
                                      ),


                                    ],),





                                  ])
                            ],),



                          ]
                      ),

                      Row(
                        //crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [

                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(""),
                            ),
                          ),


                          Container(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.blue[300],
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.blue[100],
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.0)),
                                    minimumSize: Size(100, 40), //////// HERE
                                  ),
                                  child: Text("Kataa"),

                                  onPressed: () {
                                    setState(() {
                                      //_status = true;
                                      FocusScope.of(context).requestFocus(FocusNode());
                                    });
                                    //preparetosendData();
                                  },

                                )),

                          SizedBox(
                            width: 10,
                          ),


                            Container(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.green[300],
                                    backgroundColor: Colors.white,
                                    shadowColor: Colors.green[100],
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20.0)),
                                    minimumSize: Size(100, 40), //////// HERE
                                  ),
                                  child: Text("Kubali"),

                                  onPressed: () {
                                    setState(() {
                                      //_status = true;
                                      FocusScope.of(context).requestFocus(FocusNode());
                                    });
                                    //preparetosendData();
                                  },

                                )),



                      ]),



                    ],),
                    leading: CircleAvatar(backgroundImage: NetworkImage(DataStore.currentKikobaImage)),
                    //trailing: Icon(Icons.star),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_ios, size: 18.0),
                        //Icon(Icons.person, size: 38.0),
                      ],


                    ),

                    onTap: () => _onTapItem(context, majukumux[position]),

                  ),



                  Divider(),
                ]

            );
          }),
    );
  }

  void _onTapItem(BuildContext context, majukumuData article) {
    //print(article.kikobaname);
    //DataStore.currentKikobaId = article.kikobaid;
    //DataStore.currentKikobaName = article.kikobaname;


    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => getKikobaData()), (Route<dynamic> route) => false);
    //Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => tabshome(cameras: [],)));
  }

  @override
  initState(){
    super.initState();
    //getDataMajukumu();
  }

  @override
  Widget build(BuildContext context) {

    return getbody();

  }





  Scaffold getbody(){


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text("Majukumu"),


      ),

      body:
      FutureBuilder(
          future: getData2x(),
          builder: (context, snapshot) {

            return snapshot.data != null ? listViewWidget(snapshot.data as List<majukumuData>) : Center(child: CircularProgressIndicator());


          }),

    );



  }

checkVote(vote) {
  if (vote == "0") {
    return SizedBox(
      width: 20,
      height: 20,
      child: Text(""),);
  } else if (vote == "1") {
    return Container(
      decoration: BoxDecoration(
        //color: Colors.white,
        borderRadius: BorderRadius.circular(180),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.redAccent, spreadRadius: 3),
        ],
      ),
      width: 20,
      height: 20,
      //margin: EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Icon(
          Icons.done_outline_rounded,
          color: Colors.redAccent,
          size: 15.0,
          semanticLabel: '',
        ),
      ),
    );
  } else {
    return Container(
      decoration: BoxDecoration(
        //color: Colors.white,
        borderRadius: BorderRadius.circular(180),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.blue, spreadRadius: 3),
        ],
      ),
      width: 20,
      height: 20,
      //margin: EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Icon(
          Icons.close_outlined,
          color: Colors.blue[300],
          size: 15.0,
          semanticLabel: '',
        ),
      ),
    );
  }
}


}