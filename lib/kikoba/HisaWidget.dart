import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

import 'CurrencyTextInputFormatter.dart';
import 'DataStore.dart';
import 'HttpService.dart';

class HisaWidget extends StatefulWidget {
  const HisaWidget({Key? key}) : super(key: key);

  @override
  _HisaWidgetState createState() => _HisaWidgetState();
}

class _HisaWidgetState extends State<HisaWidget> {
  final Logger _logger = Logger();
  bool showHisaWekaButton = true;
  bool showHisaInput2 = false;
  bool showHisaBadiliButton = true;
  bool showHisaInput = false;
  int selectedRadioTileHisa = -1;

  // WhatsApp-like color scheme
  final _whatsAppGreen = const Color(0xFF005AA9);
  final _whatsAppLightGreen = const Color(0xFF128C7E);
  final _whatsAppTealGreen = const Color(0xFF25D366);
  final _whatsAppBlue = const Color(0xFF34B7F1);
  final _whatsAppWhite = const Color(0xFFECE5DD);
  final _whatsAppGrey = const Color(0xFFCCCCCC);

  @override
  void initState() {
    super.initState();
    _logger.d('HisaWidget initialized');
  }

  void setSelectedRadioTileHisa(String val) {
    _logger.d('Radio tile selected: $val');
    setState(() {
      selectedRadioTileHisa = int.tryParse(val) ?? -1;
      if (selectedRadioTileHisa == 0) {
        showHisaInput = true;
      } else {
        showHisaInput = false;
      }
    });
  }

  Widget _buildHisaContainer() {
    _logger.d('Building Hisa container');
    final hisaStatus = DataStore.hisaStatus ?? '0';

    switch (hisaStatus) {
      case '1':
        _logger.d('Hisa status: 1 (No hisa)');
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildAdviseToAddHisa()
            : _buildNoHisaInfo();
      case '2':
        _logger.d('Hisa status: 2 (Hisa exists)');
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildHisaWithEditOption()
            : _buildHisaInfo();
      default:
        _logger.d('Hisa status: 0 (Not set)');
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildSetHisa()
            : _buildAdviceToSetHisa();
    }
  }

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
            padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
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

  Widget _buildAdviseToAddHisa() {
    _logger.d('Building advise to add hisa container');
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
                  'Weka Hisa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _whatsAppGreen,
                  ),
                ),
              ),
              if (showHisaWekaButton)
                _buildButton(
                  text: 'Weka',
                  onPressed: () {
                    _logger.i('Weka button pressed');
                    setState(() {
                      showHisaInput2 = true;
                      showHisaWekaButton = false;
                    });
                  },
                ),
              const SizedBox(width: 12),
            ],
          ),
          if (showHisaInput2) ...[
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
                        _logger.d('Hisa amount changed: $cleanedText');
                        DataStore.Hisa = cleanedText;
                        try {
                          HttpService.saveHisa(DataStore.Hisa  ?? "0", "2");
                        } catch (e) {
                          _logger.e('Error saving hisa: $e');
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
                      _logger.i('Save hisa button pressed');
                      setState(() {
                        DataStore.hisaStatus = '2';
                        showHisaInput2 = false;
                        showHisaWekaButton = true;
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

  Widget _buildNoHisaInfo() {
    _logger.d('Building no hisa info container');
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
            'Hakuna hisa iliyowekwa',
            style: TextStyle(
              fontSize: 16,
              color: _whatsAppGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHisaWithEditOption() {
    _logger.d('Building hisa with edit option container');
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
                  'Hisa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _whatsAppGreen,
                  ),
                ),
              ),
              Text(
                formatCurrency.format(double.tryParse(DataStore.Hisa ?? '0') ?? 0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _whatsAppGreen,
                ),
              ),
              if (showHisaBadiliButton) ...[
                const SizedBox(width: 8),
                _buildButton(
                  text: 'Badili',
                  onPressed: () {
                    _logger.i('Badili button pressed');
                    setState(() {
                      showHisaInput = true;
                      showHisaBadiliButton = false;
                    });
                  },
                ),
              ],
              const SizedBox(width: 12),
            ],
          ),
          if (showHisaInput) ...[
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
                        _logger.d('New hisa amount: $cleanedText');
                        DataStore.Hisa = cleanedText;
                        try {
                          HttpService.saveHisa(DataStore.Hisa   ?? "0", "2");
                        } catch (e) {
                          _logger.e('Error saving new hisa: $e');
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
                      _logger.i('Save new hisa button pressed');
                      setState(() {
                        DataStore.hisaStatus = '2';
                        showHisaInput = false;
                        showHisaBadiliButton = true;
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

  Widget _buildHisaInfo() {
    _logger.d('Building hisa info container');
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
            'Shilingi ${DataStore.Hisa ?? '0'} /= tu.',
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

  Widget _buildSetHisa() {
    _logger.d('Building set hisa container');
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
            'Je, kikoba hichi kina hisa ya kila mwezi?',
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
                groupValue: selectedRadioTileHisa,
                onChanged: (val) {
                  _logger.d('Radio selected: $val (Yes)');
                  setSelectedRadioTileHisa(val.toString());
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
                groupValue: selectedRadioTileHisa,
                onChanged: (val) {
                  _logger.d('Radio selected: $val (No)');
                  setSelectedRadioTileHisa(val.toString());
                  try {
                    HttpService.saveHisa("0", "1");
                    setState(() {});
                  } catch (e) {
                    _logger.e('Error saving no hisa: $e');
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
          if (showHisaInput) ...[
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
                      _logger.d('Hisa amount changed: $cleanedText');
                      DataStore.Hisa = cleanedText;
                      try {
                        HttpService.saveHisa(DataStore.Hisa  ?? "0", "2");
                      } catch (e) {
                        _logger.e('Error saving hisa: $e');
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
                    _logger.i('Save hisa button pressed');
                    setState(() {
                      DataStore.hisaStatus = '2';
                      showHisaInput = false;
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

  Widget _buildAdviceToSetHisa() {
    _logger.d('Building advice to set hisa container');
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
            'Mwenyekiti wa hiki kikundi hajaweka hisa',
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
    return _buildHisaContainer();
  }
}

