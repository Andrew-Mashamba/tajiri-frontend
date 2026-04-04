import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:vicoba/appColor.dart';

import 'CurrencyTextInputFormatter.dart';
import 'DataStore.dart';
import 'HttpService.dart';

class AdaWidget extends StatefulWidget {
  const AdaWidget({Key? key}) : super(key: key);

  @override
  _AdaWidgetState createState() => _AdaWidgetState();
}

class _AdaWidgetState extends State<AdaWidget> {
  final Logger _logger = Logger();
  bool showAdaWekaButton = true;
  bool showAdaInput2 = false;
  bool showAdaBadiliButton = true;
  bool showAdaInput = false;
  int selectedRadioTileAda = -1;

  @override
  void initState() {
    super.initState();
    _logger.d('AdaWidget initialized');
  }

  void setSelectedRadioTileAda(String val) {
    _logger.d('Radio tile selected: $val');
    setState(() {
      selectedRadioTileAda = int.tryParse(val) ?? -1;
      if (selectedRadioTileAda == 0) {
        showAdaInput = true;
      } else {
        showAdaInput = false;
      }
    });
  }

  Container _buildAdaContainer() {
    _logger.d('Building Ada container');
    final adaStatus = DataStore.adaStatus ?? '0';

    switch (adaStatus) {
      case '1':
        _logger.d('Ada status: 1 (No ada)');
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildAdviseToAddAda()
            : _buildNoAdaInfo();
      case '2':
        _logger.d('Ada status: 2 (Ada exists)');
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildAdaWithEditOption()
            : _buildAdaInfo();
      default:
        _logger.d('Ada status: 0 (Not set)');
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildSetAda()
            : _buildAdviceToSetAda();
    }
  }

  // WhatsApp-like styling
  // final _whatsAppGreen = const Color(0xFF005AA9);
  // final _whatsAppLightGreen = const Color(0xFF128C7E);
  // final _whatsAppTealGreen = const Color(0xFF005AA9);
  // final _whatsAppBlue = const Color(0xFF34B7F1);
  // final _whatsAppWhite = const Color(0xFFECE5DD);
  // final _whatsAppGrey = const Color(0xFFCCCCCC);


  final _whatsAppGreen = AppColors.primary;      // Color(0xFF23D366)
  final _whatsAppLightGreen = AppColors.secondary; // Color(0xFFE8F5E9)
  final _whatsAppTealGreen = AppColors.primary;    // Color(0xFF23D366)
  final _whatsAppBlue = AppColors.primary;        // Using primary as replacement
  final _whatsAppWhite = AppColors.background;    // Colors.white
  final _whatsAppGrey = AppColors.textSecondary; 


  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
    Color? textColor,
    EdgeInsets? padding,
  }) {
    return TextButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all<Color>(
            backgroundColor ?? _whatsAppTealGreen),
        foregroundColor:
        WidgetStateProperty.all<Color>(textColor ?? Colors.white),
        padding: WidgetStateProperty.all<EdgeInsets>(
            padding ?? const EdgeInsets.all(12)),
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return SizedBox(
      height: 50.0,
      child: TextField(
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        keyboardType: keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          filled: true,
          fillColor: _whatsAppWhite,
          labelText: label,
          labelStyle: TextStyle(color: _whatsAppGreen),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          isDense: true,
        ),
      ),
    );
  }

  Container _buildAdviseToAddAda() {
    _logger.d('Building advise to add ada container');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Weka Ada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _whatsAppGreen,
                  ),
                ),
              ),
              if (showAdaWekaButton)
                _buildButton(
                  text: 'Weka',
                  onPressed: () {
                    _logger.i('Weka button pressed');
                    setState(() {
                      showAdaInput2 = true;
                      showAdaWekaButton = false;
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
              const SizedBox(width: 12),
            ],
          ),
          if (showAdaInput2) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: "Jaza kiasi",
                      onChanged: (text) {
                        final cleanedText = text
                            .replaceAll(",", "")
                            .replaceAll("TZS", "")
                            .trim();
                        _logger.d('Ada amount changed: $cleanedText');
                        DataStore.ada = cleanedText;
                        try {
                          HttpService.saveAda(DataStore.ada, "2");
                        } catch (e) {
                          _logger.e('Error saving ada: $e');
                        }
                      },
                      keyboardType: TextInputType.numberWithOptions(),
                      inputFormatters: [
                        CurrencyTextInputFormatter(
                          NumberFormat.currency(symbol: ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    text: 'Save',
                    onPressed: () {
                      _logger.i('Save ada button pressed');
                      setState(() {
                        DataStore.adaStatus = '2';
                        showAdaInput2 = false;
                        showAdaWekaButton = true;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Container _buildNoAdaInfo() {
    _logger.d('Building no ada info container');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _whatsAppWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _whatsAppGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            'Hakuna ada iliyowekwa',
            style: TextStyle(
              fontSize: 16,
              color: _whatsAppGreen,
            ),
          ),
        ],
      ),
    );
  }

  Container _buildAdaWithEditOption() {
    _logger.d('Building ada with edit option container');
    final formatCurrency = NumberFormat.currency(symbol: 'TZS ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ada',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _whatsAppGreen,
                  ),
                ),
              ),
              Text(
                formatCurrency.format(double.tryParse(DataStore.ada ?? '0') ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _whatsAppGreen,
                ),
              ),
              if (showAdaBadiliButton) ...[
                const SizedBox(width: 8),
                _buildButton(
                  text: 'Badili',
                  onPressed: () {
                    _logger.i('Badili button pressed');
                    setState(() {
                      showAdaInput = true;
                      showAdaBadiliButton = false;
                    });
                  },
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
          if (showAdaInput) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _buildInputField(
                      label: "Jaza kiasi kipya",
                      onChanged: (text) {
                        final cleanedText = text
                            .replaceAll(",", "")
                            .replaceAll("TZS", "")
                            .trim();
                        _logger.d('New ada amount: $cleanedText');
                        DataStore.ada = cleanedText;
                        try {
                          HttpService.saveAda(DataStore.ada, "2");
                        } catch (e) {
                          _logger.e('Error saving new ada: $e');
                        }
                      },
                      keyboardType: TextInputType.numberWithOptions(),
                      inputFormatters: [
                        CurrencyTextInputFormatter(
                          NumberFormat.currency(symbol: ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildButton(
                    text: 'Save',
                    onPressed: () {
                      _logger.i('Save new ada button pressed');
                      setState(() {
                        DataStore.adaStatus = '2';
                        showAdaInput = false;
                        showAdaBadiliButton = true;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Container _buildAdaInfo() {
    _logger.d('Building ada info container');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _whatsAppWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_money, color: _whatsAppGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            'Shilingi ${DataStore.ada ?? '0'} /= tu.',
            style: TextStyle(
              fontSize: 16,
              color: _whatsAppGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Container _buildSetAda() {
    _logger.d('Building set ada container');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Je, kikoba hichi kina ada ya kila mwezi?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: _whatsAppGreen,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Radio(
                value: 0,
                groupValue: selectedRadioTileAda,
                onChanged: (val) {
                  _logger.d('Radio selected: $val (Yes)');
                  setSelectedRadioTileAda(val.toString());
                },
                activeColor: _whatsAppGreen,
              ),
              Text(
                'Ndio',
                style: TextStyle(fontSize: 16, color: _whatsAppGreen),
              ),
              const SizedBox(width: 16),
              Radio(
                value: 1,
                groupValue: selectedRadioTileAda,
                onChanged: (val) {
                  _logger.d('Radio selected: $val (No)');
                  setSelectedRadioTileAda(val.toString());
                  try {
                    HttpService.saveAda("0", "1");
                    setState(() {});
                  } catch (e) {
                    _logger.e('Error saving no ada: $e');
                  }
                },
                activeColor: _whatsAppGreen,
              ),
              Text(
                'Hapana',
                style: TextStyle(fontSize: 16, color: _whatsAppGreen),
              ),
            ],
          ),
          if (showAdaInput) ...[
            const SizedBox(height: 12),
            Text(
              'Shilingi ngapi?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: _whatsAppGreen,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: "Jaza kiasi",
                    onChanged: (text) {
                      final cleanedText = text
                          .replaceAll(",", "")
                          .replaceAll("TZS", "")
                          .trim();
                      _logger.d('Ada amount changed: $cleanedText');
                      DataStore.ada = cleanedText;
                      try {
                        HttpService.saveAda(DataStore.ada, "2");
                      } catch (e) {
                        _logger.e('Error saving ada: $e');
                      }
                    },
                    keyboardType: TextInputType.numberWithOptions(),
                    inputFormatters: [
                      CurrencyTextInputFormatter(
                        NumberFormat.currency(symbol: ''),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildButton(
                  text: 'Save',
                  onPressed: () {
                    _logger.i('Save ada button pressed');
                    setState(() {
                      DataStore.adaStatus = '2';
                      showAdaInput = false;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Container _buildAdviceToSetAda() {
    _logger.d('Building advice to set ada container');
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _whatsAppWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: _whatsAppGreen, size: 20),
          const SizedBox(width: 8),
          Text(
            'Mwenyekiti wa hiki kikundi hajaweka ada',
            style: TextStyle(
              fontSize: 16,
              color: _whatsAppGreen,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildAdaContainer();
  }
}


