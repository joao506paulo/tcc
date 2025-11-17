import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note_model.dart';
import '../models/graph_model.dart';
import 'note_local_data_source.dart';

class NoteLocalDataSourceImpl implements NoteLocalDataSource {
  static const String _databaseName = 'notes_database.db';
  static const int _databaseVersion = 1;
  
  static const String _notesTable = 'notes';
  static const String _graphsTable = 'graphs';
  
  Database? _database;
  static bool _ffiInitialized = false;

  // Inicializar FFI para desktop (Linux/Windows/macOS)
  static void initializeFfi() {
    if (!_ffiInitialized && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _ffiInitialized = true;
      print('✅ SQLite FFI inicializado para desktop');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Garantir que FFI está inicializado
    initializeFfi();

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    print('📂 Caminho do banco: $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🏗️ Criando tabelas do banco de dados...');
    
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

    print('✅ Tabelas criadas com sucesso!');
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
      
      print('✅ Nota salva: ${note.id}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar nota: $e');
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
      print('❌ Erro ao buscar nota: $e');
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
      print('❌ Erro ao buscar todas as notas: $e');
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
      
      print('✅ Nota deletada: $id');
      return count > 0;
    } catch (e) {
      print('❌ Erro ao deletar nota: $e');
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
      
      print('✅ Nota atualizada: ${note.id}');
      return count > 0;
    } catch (e) {
      print('❌ Erro ao atualizar nota: $e');
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
      
      print('✅ Grafo salvo: ${graph.id}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar grafo: $e');
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
      print('❌ Erro ao buscar grafo: $e');
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
      print('❌ Erro ao buscar grafos: $e');
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
      print('❌ Erro ao verificar existência da nota: $e');
      return false;
    }
  }

  @override
  Future<List<NoteModel>> getNotesByTag(String tag) async {
    try {
      final db = await database;
      final results = await db.query(_notesTable);

      final filteredNotes = results.where((map) {
        final metadata = jsonDecode(map['metadata'] as String) as Map;
        final tags = metadata['tags'] as List?;
        return tags?.contains(tag) ?? false;
      }).toList();

      return filteredNotes.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar notas por tag: $e');
      return [];
    }
  }

  @override
  Future<List<NoteModel>> searchNotesByTitle(String query) async {
    try {
      final db = await database;
      final results = await db.query(_notesTable);

      final filteredNotes = results.where((map) {
        final metadata = jsonDecode(map['metadata'] as String) as Map;
        final title = (metadata['title'] as String?)?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase());
      }).toList();

      return filteredNotes.map((map) => NoteModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Erro ao buscar notas por título: $e');
      return [];
    }
  }

  // Método para limpar banco (útil para testes)
  Future<void> clearDatabase() async {
    try {
      final db = await database;
      await db.delete(_notesTable);
      await db.delete(_graphsTable);
      print('✅ Banco de dados limpo');
    } catch (e) {
      print('❌ Erro ao limpar banco: $e');
    }
  }
}
