// lib/kikoba/kikoba_module.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'DataStore.dart';
import 'HttpService.dart';
import 'OfflineDatabase.dart';
import 'kikoba_firebase.dart';
import 'vicobaList.dart';
import '../services/local_storage_service.dart';

const Color _kPrimary = Color(0xFF1A1A1A);
const Color _kTertiary = Color(0xFF999999);
const Color _kBackground = Color(0xFFFAFAFA);

class KikobaModule extends StatefulWidget {
  final int userId;
  const KikobaModule({super.key, required this.userId});
  @override
  State<KikobaModule> createState() => _KikobaModuleState();
}

class _KikobaModuleState extends State<KikobaModule> {
  final Logger _logger = Logger();
  bool _isInitializing = true;
  bool _hasError = false;
  String _errorMessage = '';

  bool get _isSwahili =>
      LocalStorageService.instanceSync?.getLanguageCode() == 'sw';

  @override
  void initState() {
    super.initState();
    _initializeModule();
  }

  Future<void> _initializeModule() async {
    try {
      setState(() {
        _isInitializing = true;
        _hasError = false;
      });

      await KikobaFirebase.initialize();

      final storage = await LocalStorageService.getInstance();
      final user = storage.getUser();
      final phone = user?.phoneNumber ?? '';
      final userName = user?.fullName ?? '';

      if (phone.isEmpty) {
        throw Exception('Nambari ya simu haipatikani. Ingia tena kwenye TAJIRI.');
      }

      final db = OfflineDatabase();
      await db.open();
      final existingUser = await db.getCurrentUser();

      if (existingUser != null && existingUser.userId.isNotEmpty) {
        _populateDataStore(existingUser.userId, existingUser.name, existingUser.phone);
      } else {
        final response = await HttpService.tajiriBridgeLogin(phone, widget.userId);
        if (response == null || response['userId'] == null) {
          throw Exception('Imeshindwa kuunganisha akaunti ya Kikoba');
        }
        final vicobaUserId = response['userId'] as String;
        final vicobaUserName = response['name'] as String? ?? userName;
        _populateDataStore(vicobaUserId, vicobaUserName, phone);
        DataStore.userPresent = true;
        // Store TAJIRI profile photo if returned from bridge login
        if (response['tajiri_profile_photo'] != null) {
          DataStore.currentUserProfilePhoto = response['tajiri_profile_photo'] as String;
        }
      }

      DataStore.myVikobaList = await HttpService().getData2xp();

      if (mounted) setState(() => _isInitializing = false);
    } on SocketException catch (_) {
      _logger.e('Kikoba module initialization failed: no internet');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _isSwahili
              ? 'Hakuna mtandao. Angalia muunganisho wako ujaribue tena.'
              : 'No internet connection. Check your network and try again.';
          _isInitializing = false;
        });
      }
    } catch (e) {
      _logger.e('Kikoba module initialization failed: $e');
      if (mounted) {
        final msg = e.toString();
        String userMessage;
        if (msg.contains('simu') || msg.contains('phone')) {
          userMessage = _isSwahili
              ? 'Nambari ya simu haipatikani. Tafadhali sasisha wasifu wako.'
              : 'Phone number not found. Please update your profile.';
        } else if (msg.contains('bridge') || msg.contains('kuunganisha')) {
          userMessage = _isSwahili
              ? 'Imeshindwa kuunganisha na Kikoba. Tafadhali jaribu tena.'
              : 'Could not connect to Kikoba. Please try again.';
        } else {
          userMessage = _isSwahili
              ? 'Kuna tatizo limetokea. Tafadhali jaribu tena.'
              : 'Something went wrong. Please try again.';
        }
        setState(() {
          _hasError = true;
          _errorMessage = userMessage;
          _isInitializing = false;
        });
      }
    }
  }

  void _populateDataStore(String vicobaUserId, String name, String phone) {
    DataStore.currentUserId = vicobaUserId;
    DataStore.currentUserName = name;
    DataStore.userNumber = phone;
    DataStore.userPresent = true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              const SizedBox(height: 16),
              Text(
                _isSwahili ? 'Inapakia Kikoba...' : 'Loading Kikoba...',
                style: const TextStyle(color: _kTertiary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: _kTertiary),
                const SizedBox(height: 16),
                Text(
                  _errorMessage.replaceAll('Exception: ', ''),
                  style: const TextStyle(color: _kTertiary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _initializeModule,
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
                  child: Text(_isSwahili ? 'Jaribu Tena' : 'Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return const VikobaListPage();
  }
}
