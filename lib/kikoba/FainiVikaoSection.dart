import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

import 'AdaWidget.dart';
import 'CurrencyTextInputFormatter.dart';
import 'DataStore.dart';
import 'HttpService.dart';

class FainiVikaoSection extends StatefulWidget {
  const FainiVikaoSection({Key? key}) : super(key: key);

  @override
  _FainiVikaoSectionState createState() => _FainiVikaoSectionState();
}

class _FainiVikaoSectionState extends State<FainiVikaoSection> {
  final Logger _logger = Logger();
  bool showfainiVikaoInput = false;
  bool showfainiVikaoInput2 = false;
  bool showfainiVikaoWekaButton = true;
  bool showfainiVikaoBadiliButton = true;
  int selectedRadioTilefainiVikao = -1;

  @override
  void initState() {
    super.initState();
    _logger.d('Initializing FainiVikaoSection');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Initialize any required data here
      _logger.i('Loading initial data for FainiVikaoSection');
    } catch (e) {
      _logger.e('Error loading initial data', error: e);
    }
  }

  void setSelectedRadioTilefainiVikao(String val) {
    _logger.d('Setting selected radio tile to: $val');
    try {
      setState(() {
        selectedRadioTilefainiVikao = int.tryParse(val) ?? -1;
        if (selectedRadioTilefainiVikao == 0) {
          showfainiVikaoInput = true;
        }
      });
    } catch (e) {
      _logger.e('Error setting radio tile', error: e);
    }
  }

  Future<void> _handleSaveFainiVikao(String amount, String status) async {
    _logger.i('Saving faini vikao: $amount, status: $status');
    try {
      final cleanedAmount = amount.replaceAll(",", "").replaceAll("TZS", "").trim();
      if (cleanedAmount.isEmpty) {
        _logger.w('Empty amount provided');
        return;
      }

      final result = await HttpService.saveFainiVikao(cleanedAmount, status);
      setState(() {
        showfainiVikaoInput = false;
        showfainiVikaoInput2 = false;
        showfainiVikaoWekaButton = true;
        showfainiVikaoBadiliButton = true;
      });
    } catch (e) {
      _logger.e('Error saving faini vikao', error: e);
      // Show error to user if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ), // <-- you missed closing this!
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: _buildFainiVikaoContent(),
    ); // <-- this closing bracket fixes the Container
  }


  Widget _buildFainiVikaoContent() {
    try {
      final fainiVikaoStatusx = DataStore.fainiVikaoStatus ?? '0';
      _logger.d('Building faini vikao content with status: $fainiVikaoStatusx');

      if (fainiVikaoStatusx == '1') {
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildAdviseToAddFainiVikao()
            : _buildNoFainiVikaoMessage();
      } else if (fainiVikaoStatusx == '2') {
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildFainiVikaoWithEditOption()
            : _buildFainiVikaoInfo();
      } else {
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildSetFainiVikao()
            : _buildAdviceMkititoSetFainiVikao();
      }
    } catch (e) {
      _logger.e('Error building faini vikao content', error: e);
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Error loading faini vikao information',
        style: TextStyle(color: Color(0xFF005AA9)),
      ), // <-- Fixed closing parenthesis here
    ); // <-- Fixed closing parenthesis here
  }

  Widget _buildAdviseToAddFainiVikao() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Weka faini',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (showfainiVikaoWekaButton)
              TextButton(
                style: _whatsappButtonStyle(),
                onPressed: () {
                  _logger.d('Weka button pressed');
                  setState(() {
                    showfainiVikaoInput2 = true;
                    showfainiVikaoWekaButton = false;
                  });
                },
                child: Text(
                  "Weka".toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        if (showfainiVikaoInput2) _buildFainiVikaoInputField('2'),
      ],
    );
  }

  Widget _buildNoFainiVikaoMessage() {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text(
          'Hakuna faini imewekwa',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFainiVikaoWithEditOption() {
    final formatCurrency = NumberFormat.simpleCurrency();
    final amount = double.tryParse(DataStore.fainiVikao ?? '0') ?? 0;

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.attach_money, color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Faini',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Text(
              "${formatCurrency.format(amount).replaceAll("\$", "")} /=",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            if (showfainiVikaoBadiliButton)
              TextButton(
                style: _whatsappButtonStyle(backgroundColor: Colors.white),
                onPressed: () {
                  _logger.d('Badili button pressed');
                  setState(() {
                    showfainiVikaoInput = true;
                    showfainiVikaoBadiliButton = false;
                  });
                },
                child: Text(
                  "Badili".toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF075E54),
                  ),
                ),
              ),
          ],
        ),
        if (showfainiVikaoInput) _buildFainiVikaoInputField('2'),
      ],
    );
  }

  Widget _buildFainiVikaoInfo() {
    return Row(
      children: [
        const Icon(Icons.attach_money, color: Color(0xFF075E54), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Shilingi ${DataStore.fainiVikao ?? '0'} /= tu.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetFainiVikao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            Text(
              'Je, kikoba hichi kina faini ya kila mwezi?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio(
              value: 0,
              groupValue: selectedRadioTilefainiVikao,
              onChanged: (val) {
                _logger.d('Radio Tile pressed $val');
                setSelectedRadioTilefainiVikao("$val");
              },
              activeColor: const Color(0xFF075E54),
            ),
            const Text('Ndio', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 16),
            Radio(
              value: 1,
              groupValue: selectedRadioTilefainiVikao,
              onChanged: (val) {
                _logger.d('Radio Tile pressed $val');
                setSelectedRadioTilefainiVikao("$val");
                _handleSaveFainiVikao("0", "1");
              },
              activeColor: const Color(0xFF075E54),
            ),
            const Text('Hapana', style: TextStyle(fontSize: 14)),
          ],
        ),
        if (showfainiVikaoInput) ...[
          const SizedBox(height: 8),
          Text(
            'Shilingi ngapi?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildFainiVikaoInputField('2'),
        ],
      ],
    );
  }

  Widget _buildAdviceMkititoSetFainiVikao() {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mwanzilishi wa hiki kikundi haja seti faini',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFainiVikaoInputField(String status) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: TextField(
              onChanged: (text) {
                DataStore.fainiVikao = text.replaceAll(",", "").replaceAll("TZS", "").trim();
                _logger.d('Faini vikao amount changed: ${DataStore.fainiVikao}');
              },
              inputFormatters: [
                CurrencyTextInputFormatter(
                  NumberFormat.currency(symbol: ''),
                ),
              ],
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF075E54)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF075E54)),
                ),
                hintStyle: TextStyle(color: Colors.grey[800]),
                labelText: status == '2' ? "Jaza kiasi kipya" : "Jaza kiasi",
                fillColor: Colors.white,
                filled: true,
                isDense: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          style: _whatsappButtonStyle(),
          onPressed: () {
            _logger.d('Save button pressed');
            if (DataStore.fainiVikao?.isNotEmpty ?? false) {
              _handleSaveFainiVikao(DataStore.fainiVikao!, status);
            }
          },
          child: Text(
            "SAVE".toUpperCase(),
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      ],
    );
  }

  ButtonStyle _whatsappButtonStyle({Color? backgroundColor}) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all<Color>(
        backgroundColor ?? const Color(0xFF075E54),
      ),
      padding: MaterialStateProperty.all<EdgeInsets>(
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}