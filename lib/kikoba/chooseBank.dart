import 'package:flutter/material.dart';
import 'package:vicoba/DataStore.dart';
import 'package:vicoba/paymentStatus.dart';
import 'package:vicoba/waitDialog.dart';
import 'package:vicoba/appColor.dart';


import 'HttpService.dart';

final _formKey = GlobalKey<FormState>();

class choosebank extends StatelessWidget {
  const choosebank({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEFEFEF),
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: PopMenu(),
    );
  }
}

class PopMenu extends StatefulWidget {
  const PopMenu({super.key});

  @override
  _PopMenuState createState() => _PopMenuState();
}

class _PopMenuState extends State<PopMenu> {



  final List<String> _menuList = [
    'UCHUMI BANK',
    'MKOMBOZI BANK',
    'MWALIMU BANK',
    'ACCESS BANK',
    'AKIBA COMMERCIAL BANK',
    'MWANGA HAKIKA BANK',
    'AZANIA COMMERCIAL BANK'
  ];
  final GlobalKey _key = LabeledGlobalKey("button_icon");
  late OverlayEntry _overlayEntry;
  late Offset _buttonPosition;
  bool _isMenuOpen = false;
  String thebank = 'CHAGUA BENKI YAKO';

  void _findButton() {
    RenderObject? renderBox = _key.currentContext!.findRenderObject();
    //_buttonPosition = renderBox!.localToGlobal(Offset.zero);

    final container = _key.currentContext!.findRenderObject() as RenderBox;
    _buttonPosition = container.localToGlobal(Offset.zero);
  }

  void _openMenu() {
    _findButton();
    _overlayEntry = _overlayEntryBuilder();
    Overlay.of(context).insert(_overlayEntry);
    _isMenuOpen = !_isMenuOpen;
  }

  void _closeMenu() {
    _overlayEntry.remove();
    _isMenuOpen = !_isMenuOpen;
  }

  OverlayEntry _overlayEntryBuilder() {
    return OverlayEntry(
      builder: (context) {
        return Positioned(
          //width: 300,
          top: _buttonPosition.dy + 70,
          left: _buttonPosition.dx,
          right: _buttonPosition.dx,
          child: _popMenu(),
        );
      },
    );
  }

  Widget _popMenu() {
    return Material(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: List.generate(
            _menuList.length,
                (index) {
              return GestureDetector(

                onTap: () {

                      if(index == 0){
                        DataStore.payingBank = "UCHUMI BANK";
                        DataStore.payingBIN ="1234";
                      }else if(index == 1){
                        DataStore.payingBank = "MKOMBOZI BANK";
                        DataStore.payingBIN ="1234";
                      }else if(index == 2){
                        DataStore.payingBank = "MWALIMU BANK";
                        DataStore.payingBIN ="1234";
                      }else if(index == 3){
                        DataStore.payingBank = "ACCESS BANK";
                        DataStore.payingBIN ="1234";
                      }else if(index == 4){
                        DataStore.payingBank = "AKIBA COMMERCIAL BANK";
                        DataStore.payingBIN ="1234";
                      }

                      setState(() {
                        thebank = DataStore.payingBank;
                      });
                      _closeMenu();

                },
                child: Container(
                  alignment: Alignment.center,
                  height: 30,

                  child: Text(_menuList[index],style: TextStyle(color: Colors.white)),

                ),
              );
            },
          ),

        ),
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Chagua Benki'),
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
      body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
          children: <Widget>[


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
                    "Hamisha pesa kutoka kwenye akaunti yako ya benki",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Chagua benki yako, jaza namba yako ya akaunti ya benki hiyo, kisha bonyeza lipa"),
                ),
              ),
            ),

            SizedBox(
              height: 50,
            ),






        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[


              Padding(
              padding: EdgeInsets.all(50),
              child: Container(
                    key: _key,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(child: Text(thebank,style: TextStyle(color: Colors.white),)),
                        ),
                        IconButton(
                          icon: Icon(Icons.arrow_downward),
                          color: Colors.white,
                          onPressed: () {
                            _isMenuOpen ? _closeMenu() : _openMenu();
                          },
                        ),
                      ],
                    ),
                  ),
              ),



              Padding(
                padding: EdgeInsets.all(50),
                child: TextField(
                  onChanged: (text) {
                    print('First text field: $text');
                    DataStore.payingAccount = text;
                  },
                  autofocus: false,
                  style: TextStyle(fontSize: 20.0, color: Colors.black54),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Namba ya akaunti',
                    filled: true,
                    fillColor: Color(0xFFD6D6D6),
                    contentPadding: const EdgeInsets.only(
                        left: 14.0, bottom: 6.0, top: 8.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),

            ],
          ),
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

                          var cc = await HttpService.createPaymentIntentFromBankAcc("500","TZS");
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
                    ),

                  )
              ),
            ),



        ]
        )

    );
  }
}