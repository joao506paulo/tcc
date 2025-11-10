import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note_model.dart';
import '../models/graph_model.dart';
import 'note_local_data_source.dart';

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  static const String _databaseName = 'notes_database.db';
  static const int _databaseVersion = 1;
  
  static const String _notesTable = 'notes';
  static const String _graphsTable = 'graphs';
  
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Criar tabela de notas
    await db.execute('''
      CREATE TABLE $_notesTable (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        metadata TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Criar tabela de grafos
    await db.execute('''
      CREATE TABLE $_graphsTable (
        id TEXT PRIMARY KEY,
        nodes TEXT NOT NULL,
        edges TEXT NOT NULL,
        metadata TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Criar índices para melhorar performance
    await db.execute('''
      CREATE INDEX idx_notes_created_at ON $_notesTable(created_at)
    ''');
  }

  @override
  Future<bool> saveNote(NoteModel note) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      final noteMap = note.toMap();
      noteMap['created_at'] = now;
      noteMap['updated_at'] = now;
      
      await db.insert(
        _notesTable,
        noteMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return true;
    } catch (e) {
      print('Error saving note: $e');
      return false;
    }
  }

  @override
  Future<NoteModel?> getNote(String id) async {
    try {
      final db = await database;
      final results = await db.query(
        _notesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return NoteModel.fromMap(results.first);
    } catch (e) {
      print('Error getting note: $e');
      return null;
    }
  }

  @override
  Future<List<NoteModel>> getAllNotes() async {
    try {
      final db = await database;
      final results = await db.query(
        _notesTable,
        orderBy: 'created_at DESC',
      );

      return results.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all notes: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteNote(String id) async {
    try {
      final db = await database;
      final count = await db.delete(
        _notesTable,
        where: 'id = ?',
        whereArgs: [id],
      );
      
      return count > 0;
    } catch (e) {
      print('Error deleting note: $e');
      return false;
    }
  }

  @override
  Future<bool> updateNote(NoteModel note) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      final noteMap = note.toMap();
      noteMap['updated_at'] = now;
      
      final count = await db.update(
        _notesTable,
        noteMap,
        where: 'id = ?',
        whereArgs: [note.id],
      );
      
      return count > 0;
    } catch (e) {
      print('Error updating note: $e');
      return false;
    }
  }

  @override
  Future<bool> saveGraph(GraphModel graph) async {
    try {
      final db = await database;
      final now = DateTime.now().toIso8601String();
      
      final graphMap = graph.toMap();
      graphMap['created_at'] = now;
      
      await db.insert(
        _graphsTable,
        graphMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      return true;
    } catch (e) {
      print('Error saving graph: $e');
      return false;
    }
  }

  @override
  Future<GraphModel?> getGraph(String id) async {
    try {
      final db = await database;
      final results = await db.query(
        _graphsTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;
      return GraphModel.fromMap(results.first);
    } catch (e) {
      print('Error getting graph: $e');
      return null;
    }
  }

  @override
  Future<List<GraphModel>> getAllGraphs() async {
    try {
      final db = await database;
      final results = await db.query(
        _graphsTable,
        orderBy: 'created_at DESC',
      );

      return results.map((map) => GraphModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting all graphs: $e');
      return [];
    }
  }

  @override
  Future<bool> noteExists(String id) async {
    try {
      final db = await database;
      final results = await db.query(
        _notesTable,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      return results.isNotEmpty;
    } catch (e) {
      print('Error checking note existence: $e');
      return false;
    }
  }

  @override
  Future<List<NoteModel>> getNotesByTag(String tag) async {
    try {
      final db = await database;
      final results = await db.query(_notesTable);

      // Filtrar notas que contêm a tag nos metadados
      final filteredNotes = results.where((map) {
        final metadata = jsonDecode(map['metadata'] as String) as Map;
        final tags = metadata['tags'] as List?;
        return tags?.contains(tag) ?? false;
      }).toList();

      return filteredNotes.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('Error getting notes by tag: $e');
      return [];
    }
  }

  @override
  Future<List<NoteModel>> searchNotesByTitle(String query) async {
    try {
      final db = await database;
      final results = await db.query(_notesTable);

      // Filtrar notas cujo título contém a query
      final filteredNotes = results.where((map) {
        final metadata = jsonDecode(map['metadata'] as String) as Map;
        final title = (metadata['title'] as String?)?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();

      return filteredNotes.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('Error searching notes by title: $e');
      return [];
    }
  }
}
