// lib/kikoba/kikoba_firebase.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'kikoba_firebase_options.dart';

/// Manages VICOBA's secondary Firebase app instance.
class KikobaFirebase {
  static const String _appName = 'vicoba';
  static final Logger _logger = Logger();

  static FirebaseApp? _app;
  static FirebaseFirestore? _firestore;
  static FirebaseDatabase? _database;
  static FirebaseAuth? _auth;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      _app = await Firebase.initializeApp(
        name: _appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _auth = FirebaseAuth.instanceFor(app: _app!);
      _firestore = FirebaseFirestore.instanceFor(app: _app!);
      _database = FirebaseDatabase.instanceFor(
        app: _app!,
        databaseURL: 'https://vicoba-c89a7-default-rtdb.firebaseio.com',
      );

      _database!.setPersistenceEnabled(true);
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      if (_auth!.currentUser == null) {
        await _auth!.signInAnonymously();
      }

      _initialized = true;
      _logger.i('VICOBA Firebase initialized as secondary app "$_appName"');
    } catch (e) {
      _logger.e('Failed to initialize VICOBA Firebase: $e');
      rethrow;
    }
  }

  static FirebaseFirestore get firestore {
    assert(_initialized, 'Call KikobaFirebase.initialize() first');
    return _firestore!;
  }

  static FirebaseDatabase get database {
    assert(_initialized, 'Call KikobaFirebase.initialize() first');
    return _database!;
  }

  static FirebaseAuth get auth {
    assert(_initialized, 'Call KikobaFirebase.initialize() first');
    return _auth!;
  }

  static FirebaseApp get app {
    assert(_initialized, 'Call KikobaFirebase.initialize() first');
    return _app!;
  }
}
