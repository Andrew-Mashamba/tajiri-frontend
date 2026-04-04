import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:intl/intl.dart';

class KiingilioSection extends StatefulWidget {
  const KiingilioSection({Key? key}) : super(key: key);

  @override
  _KiingilioSectionState createState() => _KiingilioSectionState();
}

class _KiingilioSectionState extends State<KiingilioSection> {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  // WhatsApp-like colors
  final Color _whatsappGreen = const Color(0xFF005AA9);
  final Color _whatsappLightGreen = const Color(0xFF128C7E);
  final Color _whatsappTealGreen = const Color(0xFF005AA9);
  final Color _whatsappChatBackground = const Color(0xFFECE5DD);
  final Color _whatsappGrey = const Color(0xFF808080);

  // State variables
  int selectedRadioTile = 1;
  bool showKiingilioInput = false;
  bool showKiingilioInput2 = false;
  bool showKiingilioWekaButton = true;
  bool showKiingilioBadiliButton = true;

  @override
  void initState() {
    super.initState();
    _logger.i("KiingilioSection initialized");
  }

  void _handleRadioValueChange(int? val) {
    if (val == null) return;

    _logger.d("Radio value changed: $val");
    setState(() {
      selectedRadioTile = val;
      showKiingilioInput = val == 0;

      if (val == 1) {
        _saveKiingilio("0", "1");
      }
    });
  }

  Future<void> _saveKiingilio(String amount, String status) async {
    try {
      _logger.i("Saving kiingilio: $amount, status: $status");
      // var result = await HttpService.saveKiingilio(amount, status);
      // DataStore.kiingilio = amount;
      // DataStore.kiingilioStatus = status;
      _logger.i("Kiingilio saved successfully");
    } catch (e) {
      _logger.e("Error saving kiingilio: $e");
      // Handle error appropriately
    }
  }

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCurrencyInputField({
    required String label,
    required ValueChanged<String> onChanged,
    String? initialValue,
  }) {
    return SizedBox(
      height: 50.0,
      child: TextField(
        onChanged: (text) {
          final cleanedText = text.replaceAll(",", "").replaceAll("TZS", "").trim();
          onChanged(cleanedText);
          _logger.d("Kiingilio amount changed: $cleanedText");
        },
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          filled: true,
          fillColor: _whatsappChatBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String text,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? _whatsappTealGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRadioOption(String label, int value) {
    return RadioListTile<int>(
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14.0,
          color: Colors.black87,
        ),
      ),
      value: value,
      groupValue: selectedRadioTile,
      onChanged: _handleRadioValueChange,
      activeColor: _whatsappTealGreen,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAddKiingilioSection() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: _buildSectionTitle('Weka Kiingilio'),
            ),
            Visibility(
              visible: showKiingilioWekaButton,
              child: _buildActionButton(
                text: "Weka",
                onPressed: () {
                  _logger.d("Weka kiingilio button pressed");
                  setState(() {
                    showKiingilioInput2 = true;
                    showKiingilioWekaButton = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        if (showKiingilioInput2) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyInputField(
                  label: "Jaza kiasi",
                  onChanged: (text) {
                    // DataStore.kiingilio = text;
                    // _saveKiingilio(text, "2");
                  },
                ),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                text: "SAVE",
                onPressed: () {
                  _logger.d("Save kiingilio button pressed");
                  setState(() {
                    showKiingilioInput2 = false;
                    showKiingilioWekaButton = true;
                    // DataStore.kiingilioStatus = '2';
                  });
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKiingilioInfoWithEdit() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: _buildSectionTitle('Kiingilio'),
            ),
            Text(
              "${NumberFormat.currency(symbol: '').format(double.tryParse("DataStore.kiingilio") ?? 0)} /=",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.0,
                color: _whatsappGreen,
              ),
            ),
            const SizedBox(width: 8),
            Visibility(
              visible: showKiingilioBadiliButton,
              child: _buildActionButton(
                text: "Badili",
                onPressed: () {
                  _logger.d("Badili kiingilio button pressed");
                  setState(() {
                    showKiingilioInput = true;
                    showKiingilioBadiliButton = false;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
        if (showKiingilioInput) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyInputField(
                  label: "Jaza kiasi kipya",
                  onChanged: (text) {
                    // DataStore.kiingilio = text;
                    // _saveKiingilio(text, "2");
                  },
                ),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                text: "SAVE",
                onPressed: () {
                  _logger.d("Save edited kiingilio button pressed");
                  setState(() {
                    showKiingilioInput = false;
                    showKiingilioBadiliButton = true;
                    // DataStore.kiingilioStatus = '2';
                  });
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildKiingilioInfo() {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Shilingi ${"DataStore.kiingilio"} /- tu.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
              color: _whatsappGreen,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildSetKiingilioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Je, kikoba hichi kina kiingilio?'),
        _buildRadioOption('Ndio', 0),
        _buildRadioOption('Hapana', 1),
        if (showKiingilioInput) ...[
          const SizedBox(height: 10),
          _buildSectionTitle('Shilingi ngapi?'),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: _buildCurrencyInputField(
                  label: "Jaza kiasi",
                  onChanged: (text) {
                    // DataStore.kiingilio = text;
                    // _saveKiingilio(text, "2");
                  },
                ),
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                text: "SAVE",
                onPressed: () {
                  _logger.d("Save new kiingilio button pressed");
                  setState(() {
                    showKiingilioInput = false;
                  });
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdviceToSetKiingilio() {
    return Row(
      children: [
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Mwanzilishi wa hiki kikundi haja set kiingilio',
            style: TextStyle(
              fontSize: 14.0,
              color: _whatsappGrey,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  Widget _buildContent() {
    // Replace these with actual DataStore checks
    final kiingilioStatus = "1"; // DataStore.kiingilioStatus
    final userCheo = "Mwenyekiti"; // DataStore.userCheo

    _logger.d("Building content with status: $kiingilioStatus, user role: $userCheo");

    if (kiingilioStatus == '1') {
      if (userCheo == 'Mwenyekiti') {
        return _buildAddKiingilioSection();
      } else {
        return _buildKiingilioInfo();
      }
    } else if (kiingilioStatus == '2') {
      if (userCheo == 'Mwenyekiti') {
        return _buildKiingilioInfoWithEdit();
      } else {
        return _buildKiingilioInfo();
      }
    } else if (kiingilioStatus == '0') {
      if (userCheo == 'Mwenyekiti') {
        return _buildSetKiingilioSection();
      } else {
        return _buildAdviceToSetKiingilio();
      }
    }

    return Container(); // Fallback
  }

  @override
  Widget build(BuildContext context) {
    _logger.d("Building KiingilioSection");
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: _buildContent(),
      ),
    );
  }
}