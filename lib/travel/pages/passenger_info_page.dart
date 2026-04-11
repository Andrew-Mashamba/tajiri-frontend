import 'package:flutter/material.dart';
import '../models/travel_models.dart';
import '../widgets/mode_icon.dart';
import 'checkout_page.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kSecondary = Color(0xFF666666);

class PassengerInfoPage extends StatefulWidget {
  final TransportOption option;
  final int userId;
  final int passengers;

  const PassengerInfoPage({
    super.key,
    required this.option,
    required this.userId,
    required this.passengers,
  });

  @override
  State<PassengerInfoPage> createState() => _PassengerInfoPageState();
}

class _PassengerInfoPageState extends State<PassengerInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late final List<Passenger> _passengers;
  late final List<TextEditingController> _nameControllers;
  late final List<TextEditingController> _phoneControllers;
  late final List<TextEditingController> _idNumberControllers;
  late final List<String?> _idTypes;

  static const _idTypeOptions = [
    {'value': 'nida', 'label': 'Kitambulisho cha Taifa / NIDA'},
    {'value': 'passport', 'label': 'Passport'},
  ];

  @override
  void initState() {
    super.initState();
    final count = widget.passengers;
    _passengers = List.generate(count, (_) => Passenger());
    _nameControllers = List.generate(count, (_) => TextEditingController());
    _phoneControllers = List.generate(count, (_) => TextEditingController());
    _idNumberControllers = List.generate(count, (_) => TextEditingController());
    _idTypes = List.generate(count, (_) => null);
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _phoneControllers) {
      c.dispose();
    }
    for (final c in _idNumberControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) return;

    for (var i = 0; i < widget.passengers; i++) {
      _passengers[i].name = _nameControllers[i].text.trim();
      _passengers[i].phone = _phoneControllers[i].text.trim();
      _passengers[i].idType = _idTypes[i];
      _passengers[i].idNumber = _idNumberControllers[i].text.trim();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(
          option: widget.option,
          passengers: _passengers,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kPrimary,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taarifa za Abiria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              'Passenger Information',
              style: TextStyle(fontSize: 12, color: _kSecondary),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: widget.passengers,
          itemBuilder: (_, i) => _buildPassengerForm(i),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Endelea / Continue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPassengerForm(int index) {
    final isLead = index == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ModeIcon(mode: widget.option.mode, size: 18, color: _kSecondary),
              const SizedBox(width: 8),
              Text(
                isLead ? 'Abiria Mkuu / Lead Passenger' : 'Abiria ${index + 1} / Passenger ${index + 1}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          TextFormField(
            controller: _nameControllers[index],
            decoration: _inputDecoration(
              label: 'Jina Kamili / Full Name',
              hint: isLead ? 'Abiria Mkuu' : 'Jina la abiria',
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Jina linahitajika / Name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Phone
          TextFormField(
            controller: _phoneControllers[index],
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              label: 'Simu / Phone',
              hint: '0712 345 678',
            ),
          ),
          const SizedBox(height: 12),

          // ID Type dropdown
          DropdownButtonFormField<String>(
            initialValue: _idTypes[index],
            decoration: _inputDecoration(
              label: 'Aina ya Kitambulisho / ID Type',
            ),
            items: _idTypeOptions.map((opt) {
              return DropdownMenuItem(
                value: opt['value'],
                child: Text(
                  opt['label']!,
                  style: const TextStyle(fontSize: 14, color: _kPrimary),
                ),
              );
            }).toList(),
            onChanged: (v) {
              setState(() => _idTypes[index] = v);
            },
          ),
          const SizedBox(height: 12),

          // ID Number
          TextFormField(
            controller: _idNumberControllers[index],
            decoration: _inputDecoration(
              label: 'Nambari ya Kitambulisho / ID Number',
              hint: 'Nambari',
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13, color: _kSecondary),
      hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kPrimary),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
