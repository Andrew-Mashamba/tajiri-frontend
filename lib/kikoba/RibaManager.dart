import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'DataStore.dart';
import 'HttpService.dart';

class RibaManager {
  static final logger = Logger();

  static String mikopoText = "Asilimia ngapi kwa mwezi?";
  static String ribaButtonText = "BADILI";
  static bool showRibaInput2x = false;
  static bool showRibaBadiliButton = true;
  static bool showRibaWekaButton = true;
  static bool showKiingilioInput = false;
  static int? selectedRadioTile;

  static Container buildRiba(BuildContext context, Function(void Function()) setState) {
    logger.i("Starting riba() function");

    Container theContainer = Container();
    String? mikopoStatus = DataStore.mikopoStatus;
    String? userCheo = DataStore.userCheo;
    int ribaValue = DataStore.riba ?? 0;

    if (mikopoStatus == '1') {
      logger.i("Mikopo status is 1");
      if (userCheo == 'Mwenyekiti') {
        if (ribaValue > 0) {
          logger.i("Riba already set: $ribaValue%");
          theContainer = getRibaWithEditOption(setState);
        } else {
          logger.i("Riba not set yet, advising to add");
          theContainer = adviseToAddRiba(setState);
        }
      } else {
        logger.i("User is not Mwenyekiti - showing hakuna");
        theContainer = noRibaAvailable();
      }
    } else if (mikopoStatus == '2') {
      logger.i("Mikopo status is 2");
      if (userCheo == 'Mwenyekiti') {
        logger.i("Mwenyekiti can edit riba");
        theContainer = getRibaWithEditOption(setState);
      } else {
        logger.i("User can only view riba info");
        theContainer = getRibaInfo();
      }
    } else if (mikopoStatus == '0') {
      logger.i("Mikopo status is 0");
      if (userCheo == 'Mwenyekiti') {
        logger.i("Mwenyekiti can set riba");
        theContainer = setRiba(setState);
      } else {
        logger.i("Non-Mwenyekiti advised to wait for setup");
        theContainer = adviceMwenyekitiToSetRiba();
      }
    } else {
      logger.w("Unknown mikopoStatus: $mikopoStatus");
      theContainer = noRibaAvailable();
    }

    logger.i("riba() function completed");
    return theContainer;
  }

  static Container noRibaAvailable() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Text(
        'Hakuna taarifa ya riba',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  static Container getRibaWithEditOption(Function(void Function()) setState) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riba iliyopo:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
          ),
          SizedBox(height: 10),
          Text(
            '${DataStore.riba ?? 0}%',
            style: TextStyle(fontSize: 16, color: Colors.green.shade700),
          ),
          SizedBox(height: 10),
          if (showRibaBadiliButton)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                logger.i("Badili button pressed");
                setState(() {
                  showRibaInput2x = true;
                  showRibaBadiliButton = false;
                  showRibaWekaButton = false;
                  mikopoText = "Asilimia ngapi kwa mwezi?";
                  ribaButtonText = "BADILI";
                });
              },
              child: Text('Badili', style: TextStyle(color: Colors.white)),
            ),
          if (showRibaInput2x) ribaInputField(setState),
        ],
      ),
    );
  }

  static Widget ribaInputField(Function(void Function()) setState) {
    return Column(
      children: [
        TextField(
          onChanged: (text) {
            logger.i("Riba input changed: $text");
            DataStore.riba = int.tryParse(text.replaceAll(",", "").replaceAll("TZS", "").trim()) ?? 0;
            HttpService.saveRiba(DataStore.riba.toString(), "2");
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Weka Riba %",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            setState(() {
              showRibaInput2x = false;
              showRibaBadiliButton = true;
              showRibaWekaButton = true;
              mikopoText = "Riba ni asilimia: ${DataStore.riba}";
            });
            logger.i("Save button pressed for new riba: ${DataStore.riba}");
          },
          child: Text("SAVE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  static Container getRibaInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        'Riba ni ${DataStore.riba ?? 0}%',
        style: TextStyle(fontSize: 16, color: Colors.blue.shade800),
      ),
    );
  }

  static Container setRiba(Function(void Function()) setState) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Je, kikoba hiki kina kiingilio?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              radioOption(0, 'Ndio', setState),
              radioOption(1, 'Hapana', setState),
            ],
          ),
          if (showKiingilioInput) kiingilioInputField(setState),
        ],
      ),
    );
  }

  static Widget radioOption(int value, String label, Function(void Function()) setState) {
    return Row(
      children: [
        Radio(
          value: value,
          groupValue: selectedRadioTile,
          onChanged: (val) {
            logger.i("Radio selected: $label");
            setState(() {
              selectedRadioTile = val;
              if (val == 1) HttpService.saveKiingilio("0", "1");
            });
          },
          activeColor: Colors.orange,
        ),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }

  static Widget kiingilioInputField(Function(void Function()) setState) {
    return Column(
      children: [
        TextField(
          onChanged: (text) {
            logger.i("Kiingilio input changed: $text");
            DataStore.kiingilio = text.replaceAll(",", "").replaceAll("TZS", "").trim();
            HttpService.saveKiingilio(DataStore.kiingilio, "2");
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Weka Kiingilio",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            setState(() => showKiingilioInput = false);
            logger.i("Save kiingilio pressed: ${DataStore.kiingilio}");
          },
          child: Text("SAVE", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  static Container adviceMwenyekitiToSetRiba() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        'Mwanzilishi wa hiki kikundi haja set riba.',
        style: TextStyle(fontSize: 16, color: Colors.black54),
      ),
    );
  }

  static Container adviseToAddRiba(Function(void Function()) setState) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mikopoText,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF005AA9)),
          ),
          if (showRibaWekaButton)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  showRibaInput2x = true;
                  showRibaBadiliButton = false;
                  showRibaWekaButton = false;
                });
                logger.i("Weka Riba button pressed");
              },
              child: Text('WEKA RIBA', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}
