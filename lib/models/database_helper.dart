import 'package:music_app/constants.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database name
  static const String _dbName = 'app_database.db';

  // Initialize the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute(dropSongs);
    await db.execute(buildSongs);
    await db.execute(dropArtists);
    await db.execute(buildArtists);
    await db.execute(dropAlbums);
    await db.execute(buildAlbums);
    await db.execute(dropGenres);
    await db.execute(buildGenres);
    await db.execute(dropSongArtists);
    await db.execute(buildSongArtists);
    await db.execute(dropSongGenres);
    await db.execute(buildSongGenres);
    await db.execute(dropPlaylists);
    await db.execute(buildPlaylists);
    await db.execute(dropPlaylistSongs);
    await db.execute(buildPlaylistSongs);
    await db.execute(dropPlaylistSort);
    await db.execute(buildPlaylistSort);
    await db.execute(dropBackupSort);
    await db.execute(buildBackupSort);
    await db.execute(dropQueue);
    await db.execute(buildQueue);
    await db.execute(dropSettings);
    await db.execute(buildSettings);
    print(buildSeparateFieldSettings);
    await db.execute(dropSeparateFieldSettings);
    await db.execute(buildSeparateFieldSettings);
    await db.execute(dropFieldContainerSettings);
    await db.execute(buildFieldContainerSettings);
  }

  Future<void> rebuildDb() async {
    final db = await database;

    print("Rebuilding db");
    await _onCreate(db, 1);
  }

  // Insert data
  Future<int> insert(String tableName, Map<String, dynamic> data) async {
    final db = await database;
    return await db.insert(tableName, data);
  }

  // Query all items
  Future<List<Map<String, dynamic>>> getAllItems(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // Query a specific item by ID
  Future<Map<String, dynamic>?> getItemById(String tableName, int id) async {
    final db = await database;
    final results = await db.query(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  // Runs short single selection/projection query
  Future<String> easyShortQuery(String table, String projection,
      String selection, String selectionArgs) async {
    List<String> shortSelectionArgs = [selectionArgs];
    List<String> list =
        await easyQuery(table, projection, selection, shortSelectionArgs);
    String value = "";
    if (list.isNotEmpty) {
      value = list[0];
    }
    return value;
  }

  // Runs query to grab one column
  Future<List<String>> easyQuery(String table, String projection,
      String selection, List<String> selectionArgs) async {
    final db = await database;
    List<String> columns = [projection];

    List<Map<String, Object?>> results = await db.query(table,
        columns: columns, where: selection, whereArgs: selectionArgs);

    List<String> items = <String>[];
    Iterator iterator = results.iterator;
    while (iterator.moveNext()) {
      Map<String, Object?> row = iterator.current;
      items.add(row[projection]!.toString());
    }

    return items;
  }

  // Runs query to grab one column
  Future<List<String>> easyQueryWithSort(String table, String projection,
      String selection, List<String> selectionArgs, String sortOrder) async {
    final db = await database;
    List<String> columns = [projection];

    List<Map<String, Object?>> results = await db.query(table,
        columns: columns,
        where: selection,
        whereArgs: selectionArgs,
        orderBy: sortOrder);

    List<String> items = <String>[];
    Iterator iterator = results.iterator;
    while (iterator.moveNext()) {
      Map<String, String> row = iterator.current;
      items.add(row[projection]!);
    }

    return items;
  }

  // Runs query to grab all columns
  Future<List<Map<String, Object?>>> normalQuery(
      String table,
      List<String> projection,
      String selection,
      List<String> selectionArgs,
      String sortOrder) async {
    final db = await database;

    List<Map<String, Object?>> results = await db.query(table,
        columns: projection,
        where: selection,
        whereArgs: selectionArgs,
        orderBy: sortOrder);

    return results;
  }

  // Runs query to grab all columns
  Future<List<Map<String, Object?>>> customQuery(
      String query, List<String> selectionArgs) async {
    final db = await database;

    List<Map<String, Object?>> results =
        await db.rawQuery(query, selectionArgs);

    return results;
  }

  // Update an item
  Future<int> update(
      String tableName, int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      tableName,
      data,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateSetting(String name, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update(
      tableSettings,
      data,
      where: '$columnName = ?',
      whereArgs: [name],
    );
  }

  // Delete an item
  Future<int> delete(String tableName, int id) async {
    final db = await database;
    return await db.delete(
      tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  // Close the database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }

  Future<bool> isDatabasePopulated() async {
    final db = await database;
    List<Map<String, Object?>> result = <Map<String, Object?>>[];
    result = await db.rawQuery(
      '''
    SELECT name 
    FROM sqlite_master 
    WHERE type = 'table' AND name = ?;
    ''',
      [tableSongs],
    );
    print("Songs exists");
    print(result.isNotEmpty);
    if (result.isNotEmpty) {
      result =
          await db.rawQuery('SELECT EXISTS(SELECT 1 FROM $tableSongs LIMIT 1)');
    }
    print("Songs is populated");
    print(result.isNotEmpty && result.first.values.first == 1);
    return result.isNotEmpty && result.first.values.first == 1;
  }
}
