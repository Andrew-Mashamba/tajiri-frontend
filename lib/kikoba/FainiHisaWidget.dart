import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';


import 'DataStore.dart';
import 'HisaWidget.dart';
import 'HttpService.dart';

// Logger instance
final Logger logger = Logger();

class FainiHisaWidget extends StatefulWidget {
  @override
  _FainiHisaWidgetState createState() => _FainiHisaWidgetState();
}

class _FainiHisaWidgetState extends State<FainiHisaWidget> {
  bool showInputField = false;
  bool showAddButton = true;
  final TextEditingController _controller = TextEditingController();

  void _toggleInputField() {
    logger.i("Toggling input field visibility.");
    setState(() {
      showInputField = !showInputField;
      showAddButton = !showAddButton;
    });
  }

  void _saveFainiHisa() {
    try {
      final text = _controller.text.replaceAll(",", "").replaceAll("TZS", "").trim();
      logger.i("Saving faini_hisa: $text");
      if (text.isNotEmpty) {
        DataStore.faini_hisa = text;
        HttpService.saveFainiHisa(text, "2");
        setState(() {
          showInputField = false;
          showAddButton = true;
        });
      } else {
        logger.w("Tried to save empty faini_hisa.");
      }
    } catch (e) {
      logger.e("Error saving faini_hisa", error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (showInputField) _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Weka Faini ya Hisa',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green[900],
            ),
          ),
        ),
        if (showAddButton)
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[300],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: _toggleInputField,
            child: Text('WEKA'),
          ),
      ],
    );
  }

  Widget _buildInputField() {
    return Column(
      children: [
        SizedBox(height: 10),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: "Jaza kiasi",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: TextStyle(fontSize: 14),
        ),
        SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.green[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: _saveFainiHisa,
            child: Text('SAVE'),
          ),
        ),
      ],
    );
  }
}

