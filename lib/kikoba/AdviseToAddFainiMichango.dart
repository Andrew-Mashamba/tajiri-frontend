import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'appColor.dart';

import 'CurrencyTextInputFormatter.dart';
import 'DataStore.dart';
import 'HisaWidget.dart';
import 'HttpService.dart';

final logger = Logger(); // global logger

// Colors for WhatsApp-like styling
const whatsAppBackground = Color(0xFFEFEFEF);
const whatsAppText = AppColors.textSecondary;
 const whatsAppGreen = AppColors.primary;      // Color(0xFF23D366)
 

class AdviseToAddFainiMichango extends StatefulWidget {
  const AdviseToAddFainiMichango({Key? key}) : super(key: key);

  @override
  State<AdviseToAddFainiMichango> createState() => _AdviseToAddFainiMichangoState();
}

class _AdviseToAddFainiMichangoState extends State<AdviseToAddFainiMichango> {
  bool showFainiMichangoWekaButton = true;
  bool showFainiMichangoInput2 = false;

  @override
  Widget build(BuildContext context) {
    logger.i('Rendering AdviseToAddFainiMichango widget');

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: whatsAppBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Weka Faini/Michango',
                  style: TextStyle(
                    color: whatsAppText,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              if (showFainiMichangoWekaButton)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: whatsAppGreen,
                    side: BorderSide(color: whatsAppGreen),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () {
                    logger.i('Weka button pressed');
                    setState(() {
                      showFainiMichangoInput2 = true;
                      showFainiMichangoWekaButton = false;
                    });
                  },
                  child: Text(
                    "WEKA",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (showFainiMichangoInput2)
            Column(
              children: [
                TextField(
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  maxLines: 1,
                  inputFormatters: [
                  CurrencyTextInputFormatter(
                  NumberFormat.currency(symbol: ''),
                  ),
                  ],
                  onChanged: (text) {
                    final sanitizedText = text.replaceAll(",", "").replaceAll("TZS", "").trim();
                    logger.i('Text input changed: $sanitizedText');

                    DataStore.faini_michango = sanitizedText;

                    try {
                      HttpService.saveFainiMichango(DataStore.faini_michango, "2");
                      logger.i('Faini michango saved successfully');
                    } catch (e, stack) {
                      logger.e('Failed to save faini michango $e');
                    }
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: "Jaza kiasi",
                    labelStyle: TextStyle(color: whatsAppText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: whatsAppGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    logger.i('Save button pressed');
                    setState(() {
                      showFainiMichangoInput2 = false;
                      showFainiMichangoWekaButton = true;
                    });
                  },
                  child: Text(
                    "SAVE",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
