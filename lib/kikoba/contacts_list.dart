import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:vicoba/waitDialog.dart';
import 'HttpService.dart';
import 'DataStore.dart';
import 'package:vicoba/appColor.dart';
import 'sms_launcher.dart';


class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    refreshContacts();
  }

  Future<void> refreshContacts() async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        setState(() => _isLoading = false);
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withThumbnail: false,
      );

      setState(() {
        _contacts = contacts;
        _isLoading = false;
      });

      // Load thumbnails after initial render
      for (final contact in contacts) {
        if (contact.thumbnail == null) {
          final fullContact = await FlutterContacts.getContact(contact.id);
          if (fullContact?.thumbnail != null) {
            setState(() => contact.thumbnail = fullContact?.thumbnail);
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contacts'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.create),
            onPressed: () async {
              await FlutterContacts.openExternalInsert();
              refreshContacts();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed("/add").then((_) {
            refreshContacts();
          });
        },
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: _contacts.length,
          itemBuilder: (BuildContext context, int index) {
            final contact = _contacts[index];
            return ListTile(
              onTap: () {
                dataStorage.contactsData = contact;
                dataStorage.onContactDeviceSaveData = contactOnDeviceHasBeenUpdated;
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => ContactDetailsPage()));
              },
              leading: (contact.thumbnail != null && contact.thumbnail!.isNotEmpty)
                  ? CircleAvatar(backgroundImage: MemoryImage(contact.thumbnail!))
                  : CircleAvatar(child: Text(contact.initials())),
              title: Text(contact.displayName),
            );
          },
        ),
      ),
    );
  }

  void contactOnDeviceHasBeenUpdated(Contact contact) {
    setState(() {
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact;
      }
    });
  }
}

extension ContactInitials on Contact {
  String initials() {
    if (name.first.isEmpty && name.last.isEmpty) {
      return '?';
    }

    final firstInitial = name.first.isNotEmpty ? name.first[0].toUpperCase() : '';
    final lastInitial = name.last.isNotEmpty ? name.last[0].toUpperCase() : '';

    return (firstInitial + lastInitial).trim();
  }
}

class ContactDetailsPage extends StatefulWidget {
  const ContactDetailsPage({super.key});

  @override
  ContactDetailsPagex createState() => ContactDetailsPagex();
}

class ContactDetailsPagex extends State<ContactDetailsPage> {
  final Contact _contact = dataStorage.contactsData;
  final Function(Contact) onContactDeviceSave = dataStorage.onContactDeviceSaveData;

  late final TextEditingController numberController;
  late final TextEditingController jinaController;

  String _status = "";
  late String _buttonText;
  bool _loading = false;
  bool _numberInput = true;
  bool _statusView = false;
  bool _submitButton = true;
  late String _currentHeader = "Jaza namba ya simu ya mwanachama unaye mualika";
  var _result = "Mjumbe";

  @override
  void initState() {
    super.initState();
    numberController = TextEditingController();
    jinaController = TextEditingController();

    // Initialize fields from contact
    jinaController.text = [
      _contact.name.first,
      _contact.name.middle,
      _contact.name.last
    ].where((part) => part.isNotEmpty).join(" ");

    final phone = _contact.phones.isNotEmpty
        ? _contact.phones.first.number
        : "";
    numberController.text = _formatPhoneNumber(phone);
  }

  @override
  void dispose() {
    numberController.dispose();
    jinaController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length >= 9) {
      return phone.substring(phone.length - 9);
    }
    return phone;
  }

  Future<void> _openExistingContactOnDevice() async {
    try {
      final edited = await FlutterContacts.openExternalEdit(_contact.id);
      final updated = await FlutterContacts.getContact(_contact.id);
      if (updated != null) {
        onContactDeviceSave(updated);
        Navigator.of(context).pop();
      }
        } catch (e) {
      print('Error editing contact: $e');
    }
  }

  void addData(String namba, String jinalamwalikwa, String cheo) {
    final postComment = "${DataStore.currentUserName} amemwalika mjumbe mpya, ndugu $jinalamwalikwa kama $cheo, kwenye kikoba hichi.";
    final uuid = Uuid();
    final dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final thedate = dateFormat.format(DateTime.now());

    FirebaseFirestore.instance
        .collection('${DataStore.currentKikobaId}barazaMessages')
        .add({
      'posterName': DataStore.currentUserName,
      'posterId': DataStore.currentUserId,
      'posterNumber': DataStore.userNumber,
      'posterPhoto': "",
      'postComment': postComment,
      'postImage': '',
      'postType': 'taarifaYamualiko',
      'postId': uuid.v4(),
      'postTime': thedate,
      'kikobaId': DataStore.currentKikobaId
    })
        .catchError((error) => print("Failed to add user: $error"));
  }

  Future<void> _submitPhoneNumber() async {
    setState(() {
      _loading = true;
      _numberInput = false;
      _submitButton = false;
      _currentHeader = "Tafadhali subiri...";
    });

    final phoneNumber = "+255${numberController.text.trim()}";
    print(phoneNumber);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DataStore.waitTitle = "Tafadhali Subiri";
        DataStore.waitDescription = "Mualikwa ana taarifiwa...";
        return waitDialog(
          title: "Tafadhali Subiri",
          descriptions: "Mualikwa ana taarifiwa...",
          text: "",
        );
      },
    );

    try {
      final response = await HttpService.registerMobileNo2(
          phoneNumber, jinaController.text, _result);

      // Dismiss loading dialog
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
      }

      if (response.isSuccess) {
        // Success - registered or added_to_kikoba
        print("Registration successful: ${response.message}");
        print("User ID: ${response.userId}");
        if (response.otp != null) {
          print("OTP: ${response.otp}");
          print("OTP expires at: ${response.otpExpiresAt}");
          print("WhatsApp sent: ${response.whatsappSent}");
        }

        // Store the new user ID if needed
        if (response.userId != null) {
          DataStore.lastRegisteredUserId = response.userId;
        }

        // Open SMS app if manual sending is required
        if (response.requiresManualSend) {
          await SmsLauncher.openSmsApp(
            phoneNumber: response.manualSend!.recipientPhone,
            message: response.manualSend!.message,
          );
        }

        // Post to baraza
        addData(phoneNumber, jinaController.text, _result);

        // Navigate back
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(context);
        }
      } else {
        _handleRegistrationError(response.message);
      }
    } catch (ex) {
      print('Query error: $ex');
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        _handleRegistrationError("Unexpected Error");
      }
    }
  }

  void _handleRegistrationError(String error) {
    setState(() {
      _statusView = true;
      _loading = false;
      _numberInput = true;
      _submitButton = true;
      _currentHeader = "Jaza namba ya simu ya mwanachama unaye mualika";

      switch (error) {
        case "present":
          _status = 'Namba ulio jaza sio imesajiriwa na mtu mwingine, Jaribu namba nyingingine\n';
          _buttonText = 'Jaribu Tena';
          break;
        case "Network Error":
          _status = 'Kuna matatizo ya mtandao, Jaribu tena\n';
          _buttonText = 'Jaribu Tena';
          break;
        case "Device Offline":
          _status = 'Hauna Internet, Tafadhali washa data\n';
          _buttonText = 'Jaribu Tena';
          break;
        case "Server Error":
          _status = 'Hauna tatizo la kiufundi, jaribu tena baadae\n';
          _buttonText = 'Jaribu Tena Baadae';
          break;
        default:
          _status = 'Hauna tatizo la kiufundi, jaribu tena baadae\n';
          _buttonText = 'Jaribu Tena Baadae';
          //HttpService.reportBug("no error", "registerMobileNo", "nobody", error, "no device");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contact.displayName),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await FlutterContacts.deleteContact(_contact.id as Contact);
              Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openExistingContactOnDevice,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 10),
            const Text(
              "Alika Mwanachama",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 26,
                  height: 1.5,
                  color: AppColors.primary),

            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: jinaController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary)),
                  hintText: '',
                  helperText: '',
                  labelText: 'Jina la mualikwa',
                  prefixIcon: Icon(Icons.person_outline, color: Colors.green),
                  suffixStyle: TextStyle(color: Colors.green),
                ),
                maxLength: 100,
                keyboardType: TextInputType.name,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _numberInput ? TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary)),
                  hintText: '',
                  helperText: 'Bila sifuri ya mwanzo mf. 712444576',
                  labelText: 'Namba ya simu ya mualikwa',
                  prefixIcon: Icon(Icons.phone, color: Colors.green),
                  prefixText: ' +255 ',
                  suffixText: 'TZ',
                  suffixStyle: TextStyle(color: Colors.green),
                ),
                maxLength: 9,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
              ) : null,
            ),
            Column(
              children: [
                const SizedBox(height: 10),
                const Text("Cheo cha mualikwa", style: TextStyle(fontSize: 15.0)),
                RadioListTile(
                  title: const Text('Mwenyekiti'),
                  subtitle: const Text("Kitambulisho chake kita hitajika"),
                  value: "Mwenyekiti",
                  groupValue: _result,
                  onChanged: (value) => setState(() => _result = value.toString()),
                ),
                RadioListTile(
                  title: const Text('Katibu'),
                  subtitle: const Text("Kitambulisho chake kita hitajika"),
                  value: "Katibu",
                  groupValue: _result,
                  onChanged: (value) => setState(() => _result = value.toString()),
                ),
                RadioListTile(
                  title: const Text('Mjumbe'),
                  subtitle: const Text("Kitambulisho chake hakita hitajika"),
                  selected: true,
                  value: "Mjumbe",
                  groupValue: _result,
                  onChanged: (value) => setState(() => _result = value.toString()),
                ),
                const SizedBox(height: 25),
              ],
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.all(25),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(color: Colors.blue, width: 1.0),
                      ),
                      side: const BorderSide(color: Colors.black, width: 1.0)),
                  onPressed: (numberController.text.length >= 8)
                      ? _submitPhoneNumber
                      : null,
                  child: const Text("Twende", style: TextStyle(fontSize: 20.0)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<StatefulWidget> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _contact = Contact();
  final _address = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a contact"),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                _contact.addresses = "" as List<Address>;
                await FlutterContacts.insertContact(_contact);
                Navigator.of(context).pop();
              }
            },
            child: const Icon(Icons.save, color: Colors.white),
          )
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) => _contact.name.first = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) => _contact.name.middle = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) => _contact.name.last = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) => _contact.phones.add(Phone(v ?? '')),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSaved: (v) => _contact.emails.add(Email(v ?? '')),
                keyboardType: TextInputType.emailAddress,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class PostalAddress {
}

class UpdateContactsPage extends StatefulWidget {
  final Contact contact;

  const UpdateContactsPage({super.key, required this.contact});

  @override
  _UpdateContactsPageState createState() => _UpdateContactsPageState();
}

class _UpdateContactsPageState extends State<UpdateContactsPage> {
  late Contact _contact;
  late PostalAddress _address;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
    _address = _contact.addresses.first as PostalAddress;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Contact"),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                if (_contact.addresses.isEmpty) {
                  _contact.addresses.add(_address as Address);
                }
                await FlutterContacts.updateContact(_contact);
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => ContactListPage()));
              }
            },
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _contact.name.first,
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) => _contact.name.first = v ?? '',
              ),
              TextFormField(
                initialValue: _contact.name.middle,
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) => _contact.name.middle = v ?? '',
              ),
              TextFormField(
                initialValue: _contact.name.last,
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) => _contact.name.last = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) => _contact.phones.add(Phone(v ?? '')),
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSaved: (v) => _contact.emails.add(Email(v ?? '')),
                keyboardType: TextInputType.emailAddress,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class dataStorage {
  static late Contact contactsData;
  static late Function(Contact) onContactDeviceSaveData;
}