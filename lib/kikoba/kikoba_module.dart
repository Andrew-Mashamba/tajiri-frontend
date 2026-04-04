// lib/kikoba/kikoba_module.dart
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
      }

      DataStore.myVikobaList = await HttpService().getData2xp();

      if (mounted) setState(() => _isInitializing = false);
    } catch (e) {
      _logger.e('Kikoba module initialization failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
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
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: _kPrimary),
              SizedBox(height: 16),
              Text(
                'Inapakia Kikoba...',
                style: TextStyle(color: _kTertiary, fontSize: 13),
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
                  child: const Text('Jaribu Tena'),
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
