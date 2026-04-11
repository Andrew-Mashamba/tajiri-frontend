import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'waitDialog.dart';
import 'HttpService.dart';
import 'DataStore.dart';
import '../services/event_service.dart';
import '../services/local_storage_service.dart';



class pickdatetime extends StatelessWidget {
  const pickdatetime({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyHomePage(title: 'Chagua Tarehe');
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>  {

  TextEditingController MadhumuniController = TextEditingController();
  TextEditingController eneoController = TextEditingController();
  var dateyakikao = "";
  var timeyakikao = "";



  @override
  initState(){
    super.initState();


  }


  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: 18);



    return Scaffold(

      appBar: AppBar(
        title: Text(widget.title),

      ),
      body: body(),
    );
  }



  Widget body() {
    final textStyle = TextStyle(fontSize: 18);
    String radioItem = '';

    return ListView(children: [

      Column(


        children: <Widget>[


          //Spacer(flex: 1),
          SizedBox(height: 60),

          Text("Madhumuni ya kikao.", style: TextStyle(fontSize: 15.0),),

          SizedBox(height: 15),

          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: MadhumuniController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent)),
                    hintText: '',
                    helperText: '',
                    labelText: 'Madhumuni',

                    suffixStyle: const TextStyle(color: Colors.green)),
                onChanged: (text) {
                  print('First text field: $text');
                  //processPhoneNumber(text);
                },
                maxLength: 100,
                keyboardType: TextInputType.name,

              )
          ),

          SizedBox(height: 15),

          Text("Eneo la kikao.", style: TextStyle(fontSize: 15.0),),

          SizedBox(height: 15),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: eneoController,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.redAccent)),
                    hintText: '',
                    helperText: '',
                    labelText: 'Eneo',

                    suffixStyle: const TextStyle(color: Colors.green)),
                onChanged: (text) {
                  print('First text field: $text');
                  //processPhoneNumber(text);
                },
                maxLength: 100,
                keyboardType: TextInputType.name,

              )
          ),


          TextButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  dateyakikao = DateFormat('yyyy-MM-dd').format(picked);
                });
              }
            },
            child: Text(
              'Chagua tarehe ya kikao',
              style: TextStyle(color: Colors.blue),
            ),
          ),
          TextButton(
            onPressed: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (picked != null) {
                final now = DateTime.now();
                final fullDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
                setState(() {
                  timeyakikao = DateFormat('HH:mm').format(fullDate);
                });
              }
            },
            child: Text(
              'Chagua muda',
              style: TextStyle(color: Colors.blue),
            ),
          ),





          Center(
              child:Container(
                margin: EdgeInsets.all(25),
                child: OutlinedButton (
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        side: BorderSide(color: Colors.blue, width: 1.0), // HERE
                      ),
                      side: BorderSide(color: Colors.black, width: 1.0)), // AND HERE
                  child: Text("Twende", style: TextStyle(fontSize: 20.0),),

                  //onPressed: (MadhumuniController.text.length >= 1) ? () =>  submitData() : null,
                  onPressed: () {
                    submitData();
                  },
                ),
              )),




        ],
      )

    ],);






  }



  Future<void> submitData() async {


    showDialog(context: context,
        builder: (BuildContext context){
          DataStore.waitTitle = "Tafadhali Subiri";
          DataStore.waitDescription = "Mualikwa ana taarifiwa...";
          return waitDialog(
            title: "Tafadhali Subiri",
            descriptions: "Mualikwa ana taarifiwa...",
            text: "",
          );
        }
    );




    try {

      HttpService.itishaKikao(eneoController.text,MadhumuniController.text,dateyakikao,timeyakikao,"reminder").then((String result){
        setState(() {
          print (result);

          if(result.trim() == "7"){


            print (result);

            // Fire-and-forget: sync meeting to TAJIRI calendar
            _syncMeetingToCalendar(
              MadhumuniController.text,
              dateyakikao,
              timeyakikao,
              eneoController.text,
            );

            Navigator.of(context, rootNavigator: true).pop('dialog');

            Navigator.of(context, rootNavigator: true).pop(context);

          }else if(result.trim() == "present"){

            print('verificationFailed');
            //_handleError(error);
            setState(() {


            });


          }else if(result.trim() == "Network Error"){

            print('verificationFailed');
            //_handleError(error);
            setState(() {


            });


          }else if(result.trim() == "Device Offline"){

            setState(() {


            });



          }else if(result.trim() == "Server Error"){




          }else{

            HttpService.reportBug("no error", "registerMobileNo", "nobody", result.trim(),"no device");
          }


        });
      });



    } on Exception catch (ex) {
      print('Query error: $ex');
    }



  }




  Future<void> _syncMeetingToCalendar(
    String title,
    String dateStr,
    String timeStr,
    String location,
  ) async {
    try {
      final storage = await LocalStorageService.getInstance();
      final token = storage.getAuthToken();
      final user = storage.getUser();
      final userId = user?.userId;
      if (token == null || userId == null) return;

      // Parse date string (yyyy-MM-dd)
      final date = DateTime.tryParse(dateStr);
      if (date == null) return;

      final kikobaName = DataStore.currentKikobaName ?? 'Kikoba';
      final eventName = '$kikobaName: $title';

      // ignore: unawaited_futures
      EventService().createEvent(
        creatorId: userId,
        name: eventName,
        startDate: date,
        startTime: timeStr.isNotEmpty ? timeStr : null,
        description: title,
        locationName: location.isNotEmpty ? location : null,
        category: 'kikoba',
      );
    } catch (_) {
      // Fire-and-forget — never block the meeting creation flow
    }
  }

  void addData(String namba, String jinalamwalikwa, String cheo) {
    var postComment = "${DataStore.currentUserName} amemwalika mjumbe mpya, ndugu $jinalamwalikwa kama $cheo, kwenye kikoba hichi.";
    var uuid = Uuid();
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String thedate = dateFormat.format(DateTime.now());


    CollectionReference users = FirebaseFirestore.instance.collection('${DataStore.currentKikobaId}barazaMessages');


    // Call the user's CollectionReference to add a new user
    users.add({
      'posterName': DataStore.currentUserName,
      'posterId': DataStore.currentUserId,
      'posterNumber': DataStore.userNumber,
      'posterPhoto': "",
      'postComment': postComment,
      'postImage': '',
      'postType': 'taarifaYamualiko',
      'postId': uuid.v4(),
      'postTime': thedate,
      'kikobaId': DataStore.currentKikobaId
    }).then((value) =>

        sendNotifications(postComment,namba)

    ).catchError((error) =>

        print("Failed to add user: $error")
    );


  }

  void sendNotifications(String postComment, String namba){

  }








}




