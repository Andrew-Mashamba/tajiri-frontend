import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/services.dart';

import 'CurrencyTextInputFormatter.dart';
import 'DataStore.dart';
import 'HttpService.dart';

class FainiAdaSection extends StatefulWidget {
  const FainiAdaSection({Key? key}) : super(key: key);

  @override
  _FainiAdaSectionState createState() => _FainiAdaSectionState();
}

class _FainiAdaSectionState extends State<FainiAdaSection> {
  final Logger _logger = Logger();
  bool showInput = false;
  bool showInput2 = false;
  bool showWekaButton = true;
  bool showBadiliButton = true;
  int? selectedRadioTile;

  // WhatsApp color palette
  final Color _whatsappGreen = const Color(0xFF005AA9);
  final Color _whatsappLightGreen = const Color(0xFF128C7E);
  final Color _whatsappTeal = const Color(0xFF25D366);
  final Color _whatsappWhite = const Color(0xFFECE5DD);

  @override
  void initState() {
    super.initState();
    _logger.d('Initializing FainiAdaSection');
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      _logger.i('Initializing Faini Ada data');
      // Add any initialization logic here
    } catch (e) {
      _logger.e('Error initializing data', error: e);
    }
  }

  void _setSelectedRadioTile(String? val) {
    _logger.d('Setting selected radio tile to: $val');
    try {
      setState(() {
        selectedRadioTile = val != null ? int.tryParse(val) : null;
        if (selectedRadioTile == 0) {
          showInput = true;
        }
      });
    } catch (e) {
      _logger.e('Error setting radio tile', error: e);
    }
  }

  Future<void> _handleSaveFainiAda(String amount, String status) async {
    _logger.i('Saving faini ada: $amount, status: $status');
    try {
      final cleanedAmount = amount.replaceAll(",", "").replaceAll("TZS", "").trim();
      if (cleanedAmount.isEmpty) {
        _logger.w('Empty amount provided');
        return;
      }

      await HttpService.savefaini_ada(cleanedAmount, status);
      setState(() {
        showInput = false;
        showInput2 = false;
        showWekaButton = true;
        showBadiliButton = true;
      });
    } catch (e) {
      _logger.e('Error saving faini ada', error: e);
      // Show error to user if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _whatsappWhite,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: _buildContent(),
    );
  }


  Widget _buildContent() {
    try {
      final fainiAdaStatus = DataStore.faini_adaStatus ?? '0';
      _logger.d('Building faini ada content with status: $fainiAdaStatus');

      if (fainiAdaStatus == '1') {
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildAdviseToAdd()
            : _buildNoFainiAdaMessage();
      } else if (fainiAdaStatus == '2') {
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildFainiAdaWithEditOption()
            : _buildFainiAdaInfo();
      } else {
        return DataStore.userCheo == 'Mwenyekiti'
            ? _buildSetFainiAda()
            : _buildAdviceToSetFainiAda();
      }
    } catch (e) {
      _logger.e('Error building faini ada content', error: e);
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: const Text(
        'Error loading faini ada information',
        style: TextStyle(color: Color(0xFF005AA9)),
      ),
    );
  }

  Widget _buildAdviseToAdd() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Weka faini ada',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (showWekaButton)
              TextButton(
                style: _whatsappButtonStyle(),
                onPressed: () {
                  _logger.d('Weka button pressed');
                  setState(() {
                    showInput2 = true;
                    showWekaButton = false;
                  });
                },
                child: Text(
                  "Weka".toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        if (showInput2) _buildInputField('2'),
      ],
    );
  }

  Widget _buildNoFainiAdaMessage() {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Text(
          'Hakuna faini ada imewekwa',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFainiAdaWithEditOption() {
    final formatCurrency = NumberFormat.simpleCurrency();
    final amount = double.tryParse(DataStore.faini_ada ?? '0') ?? 0;

    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.attach_money, color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Faini ada',
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
            if (showBadiliButton)
              TextButton(
                style: _whatsappButtonStyle(backgroundColor: Colors.white),
                onPressed: () {
                  _logger.d('Badili button pressed');
                  setState(() {
                    showInput = true;
                    showBadiliButton = false;
                  });
                },
                child: Text(
                  "Badili".toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _whatsappGreen,
                  ),
                ),
              ),
          ],
        ),
        if (showInput) _buildInputField('2'),
      ],
    );
  }

  Widget _buildFainiAdaInfo() {
    return Row(
      children: [
        const Icon(Icons.attach_money, color: Color(0xFF075E54), size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Shilingi ${DataStore.faini_ada ?? '0'} /= tu.',
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

  Widget _buildSetFainiAda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.help_outline, color: Color(0xFF075E54), size: 20),
            const SizedBox(width: 8),
            Text(
              'Je, kikoba hichi kina faini ya ada?',
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
            Radio<int>(
              value: 0,
              groupValue: selectedRadioTile,
              onChanged: (int? val) {
                if (val != null) {
                  _setSelectedRadioTile(val as String?);
                  _handleSaveFainiAda("1", "0"); // Assuming 0 = Ndio, 1 = Hapana
                }
              },
              activeColor: _whatsappGreen,
            ),
            const Text('Ndio', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 16),
            Radio<int>(
              value: 1,
              groupValue: selectedRadioTile,
              onChanged: (int? val) {
                if (val != null) {
                  _setSelectedRadioTile(val as String?);
                  _handleSaveFainiAda("0", "1"); // Assuming 1 = Hapana
                }
              },
              activeColor: _whatsappGreen,
            ),
            const Text('Hapana', style: TextStyle(fontSize: 14)),
          ],
        )
        ,
        if (showInput) ...[
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
          _buildInputField('2'),
        ],
      ],
    );
  }

  Widget _buildAdviceToSetFainiAda() {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Mwanzilishi wa hiki kikundi haja seti faini ada',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String status) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: TextField(
              onChanged: (text) {
                DataStore.faini_ada = text.replaceAll(",", "").replaceAll("TZS", "").trim();
                _logger.d('Faini ada amount changed: ${DataStore.faini_ada}');
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
                  borderSide: BorderSide(color: _whatsappGreen),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: _whatsappGreen),
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
            if (DataStore.faini_ada?.isNotEmpty ?? false) {
              _handleSaveFainiAda(DataStore.faini_ada!, status);
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
        backgroundColor ?? _whatsappGreen,
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