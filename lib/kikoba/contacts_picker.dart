import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactPickerPage extends StatefulWidget {
  const ContactPickerPage({super.key});

  @override
  _ContactPickerPageState createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _pickContact();
  }

  Future<void> _pickContact() async {
    if (!await FlutterContacts.requestPermission()) {
      print('Permission denied');
      return;
    }

    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact != null) {
        final fullContact = await FlutterContacts.getContact(contact.id);
        setState(() {
          _contact = fullContact;
        });
      }
    } catch (e) {
      print('Error picking contact: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Picker Example')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickContact,
              child: const Text('Pick a contact'),
            ),
            if (_contact != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${_contact!.displayName}'),
                  if (_contact!.phones.isNotEmpty)
                    Text('Phone(s): ${_contact!.phones.map((p) => p.number).join(', ')}'),
                  Text('ID: ${_contact!.id}'),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
