

import 'package:flutter/material.dart';


class networkError extends StatelessWidget {
  const networkError({super.key});

  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text('Tatizo'),
      ),
      body: Center(


        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,


          children: <Widget>[

            SizedBox(
              height: 100,
            ),

            Container(
              decoration: BoxDecoration(
                //color: Colors.white,
                borderRadius: BorderRadius.circular(180),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.redAccent, spreadRadius: 3),
                ],
              ),
              width: 200,
              height: 200,
              margin: EdgeInsets.all(10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child:             Icon(
                  Icons.close_outlined,
                  color: Colors.blue,
                  size: 100.0,
                  semanticLabel: '',
                ),
              ),
            ),






            SizedBox(
              height: 10,
            ),
            Text(
              "Kuna tatizo la mtandao",
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              "Tafadhali, jaribu tena baadae.",
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
            ),

            Text(
              "",
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 10,
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
                          'OK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            //package: 'flutter_credit_card',
                          ),
                        ),
                      ),
                      onPressed: () async {
                        //_onLoading();

                        Navigator.pop(context);
                        Navigator.of(context).pop();

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



}


