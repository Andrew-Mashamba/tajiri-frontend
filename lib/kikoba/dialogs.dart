import 'package:flutter/material.dart';
import 'custom_dialog_box.dart';

class Dialogs extends StatefulWidget {
  const Dialogs({super.key});

  @override
  _DialogsState createState() => _DialogsState();
}

class _DialogsState extends State<Dialogs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Dialog In Flutter"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        child: Center(
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
              onPressed: (){
                showDialog(context: context,
                  builder: (BuildContext context){
                  return CustomDialogBox(
                    title: "Custom Dialog Demo",
                    descriptions: "Hii all this is a custom dialog in flutter and  you will be use in your flutter applications",
                    text: "Yes",
                  );
                  }
                );
              },
            child: Text("Custom Dialog"),

          ),
        ),
      ),
    );
  }
}
