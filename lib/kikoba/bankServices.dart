
import 'package:flutter/material.dart';
import 'DataStore.dart';
import 'vicoba.dart';
import 'HttpService.dart';

import 'bankServicesModal.dart';
import 'getKikobaData.dart';

class bankServices extends StatefulWidget {

  const bankServices({super.key});


  @override
  _NewsListPageState createState() => _NewsListPageState();
}

class _NewsListPageState extends State<bankServices> {

  Widget listViewWidget(List<bankServicesModal> article) {


    return Container(
      child: ListView.builder(
          itemCount: article.length,
          padding: const EdgeInsets.all(2.0),
          itemBuilder: (context, position) {
            return Column(
                children: [
                  ListTile(
                    title: Text(article[position].Name, style: TextStyle(fontSize: 15.0, color: Colors.black, fontWeight: FontWeight.bold),),
                    subtitle: Text(article[position].App_Category),
                    //leading: CircleAvatar(backgroundImage: NetworkImage(article[position].serviceImage)),
                    leading: CircleAvatar(backgroundImage: NetworkImage("${HttpService.baseUrl}service-images/mpesa.jpeg")),
                    //trailing: Icon(Icons.star),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_forward_ios, size: 18.0),
                        //Icon(Icons.person, size: 38.0),
                      ],


                    ),

                    onTap: () => _onTapItem(context, article[position]),

                  ),

                  Divider(),
                ]

            );
          }),
    );
  }

  void _onTapItem(BuildContext context, bankServicesModal article) {
    //print(article.kikobaname);
    DataStore.bankServiceId = article.id;
    DataStore.bankServiceName = article.Name;


    Navigator.of(context).push(MaterialPageRoute(builder: (context) => getKikobaData()));
    //Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => tabshome(cameras: [],)));
  }

  @override
  initState(){
    super.initState();

  }

  @override
  Widget build(BuildContext context) {

    return getbody();

  }

  List<vicoba> returnThelist(){
    return DataStore.bankServicesList;
  }




  Scaffold getbody(){

    Scaffold scaffold;
    if(DataStore.bankServicesList.length < 1){
      //return searchOrcreate();
      scaffold = Scaffold();


    }else{

      scaffold = Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.redAccent,
            title: Text("Huduma za kibenki"),

          ),

          body:listViewWidget(DataStore.bankServicesList as List<bankServicesModal>)
        //body:bodySelector()

      );

    }


    return scaffold;



  }




}