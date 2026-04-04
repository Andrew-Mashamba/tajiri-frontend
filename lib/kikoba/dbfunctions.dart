// Define a function that inserts dogs into the database
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'user.dart';




Future<void> insertUser(user user) async {
  // Get a reference to the database.

  final Future<Database> database = openDatabase(

    join(await getDatabasesPath(), 'vicoba_database.db'),

  );
  final Database db = await database;

  // Insert the Dog into the correct table. You might also specify the
  // `conflictAlgorithm` to use in case the same dog is inserted twice.
  //
  // In this case, replace any previous data.
  await db.insert(
    'user',
    user.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}