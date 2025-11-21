import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ontology_model.dart';
import '../models/semantic_template_model.dart';
import '../models/semantic_annotation_model.dart';
import 'semantic_local_data_source.dart';

class SemanticLocalDataSourceImpl implements SemanticLocalDataSource {
  static const String _databaseName = 'semantic_database.db';
  static const int _databaseVersion = 1;

  // Tabelas
  static const String _ontologiesTable = 'ontologies';
  static const String _templatesTable = 'semantic_templates';
  static const String _annotationsTable = 'semantic_annotations';
  static const String _triplesTable = 'rdf_triples';

  Database? _database;

  /// Inicializa FFI para desktop (igual ao note_local_data_source_impl)
  static void initializeFfi() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print('✅ SQLite FFI inicializado para semantic database');
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      final appDir = await getApplicationSupportDirectory();
      path = join(appDir.path, _databaseName);
    } else {
      final databasesPath = await getDatabasesPath();
      path = join(databasesPath, _databaseName);
    }

    print('📂 Semantic DB path: $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('🏗️ Criando tabelas semânticas...');

    // Tabela de ontologias
    await db.execute('''
      CREATE TABLE $_ontologiesTable (
        id TEXT PRIMARY KEY,
        base_uri TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        version TEXT NOT NULL DEFAULT '1.0.0',
        classes TEXT NOT NULL DEFAULT '[]',
        properties TEXT NOT NULL DEFAULT '[]',
        imports TEXT NOT NULL DEFAULT '[]',
        prefixes TEXT NOT NULL DEFAULT '{}',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        metadata TEXT NOT NULL DEFAULT '{}'
      )
    ''');

    // Tabela de templates
    await db.execute('''
      CREATE TABLE $_templatesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        main_class TEXT NOT NULL,
        properties TEXT NOT NULL DEFAULT '[]',
        default_values TEXT NOT NULL DEFAULT '{}',
        owl_definition TEXT,
        icon_name TEXT,
        color_hex TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        metadata TEXT NOT NULL DEFAULT '{}'
      )
    ''');

    // Tabela de anotações
    await db.execute('''
      CREATE TABLE $_annotationsTable (
        id TEXT PRIMARY KEY,
        note_id TEXT NOT NULL UNIQUE,
        template_id TEXT NOT NULL,
        class_uri TEXT NOT NULL,
        property_values TEXT NOT NULL DEFAULT '{}',
        relations TEXT NOT NULL DEFAULT '[]',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        metadata TEXT NOT NULL DEFAULT '{}'
      )
    ''');

    // Tabela de triplas RDF
    await db.execute('''
      CREATE TABLE $_triplesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject TEXT NOT NULL,
        predicate TEXT NOT NULL,
        object TEXT NOT NULL,
        is_literal INTEGER NOT NULL DEFAULT 1,
        datatype TEXT,
        language TEXT,
        UNIQUE(subject, predicate, object)
      )
    ''');

    // Índices
    await db.execute('CREATE INDEX idx_annotations_note_id ON $_annotationsTable(note_id)');
    await db.execute('CREATE INDEX idx_annotations_template ON $_annotationsTable(template_id)');
    await db.execute('CREATE INDEX idx_annotations_class ON $_annotationsTable(class_uri)');
    await db.execute('CREATE INDEX idx_triples_subject ON $_triplesTable(subject)');
    await db.execute('CREATE INDEX idx_triples_predicate ON $_triplesTable(predicate)');
    await db.execute('CREATE INDEX idx_triples_object ON $_triplesTable(object)');

    print('✅ Tabelas semânticas criadas!');
  }

  // ============================================
  // Ontologias
  // ============================================

  @override
  Future<bool> saveOntology(OntologyModel ontology) async {
    try {
      final db = await database;
      await db.insert(_ontologiesTable, ontology.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      print('✅ Ontologia salva: ${ontology.id}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar ontologia: $e');
      return false;
    }
  }

  @override
  Future<OntologyModel?> getOntology(String id) async {
    try {
      final db = await database;
      final results = await db.query(_ontologiesTable,
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (results.isEmpty) return null;
      return OntologyModel.fromMap(results.first);
    } catch (e) {
      print('❌ Erro ao buscar ontologia: $e');
      return null;
    }
  }

  @override
  Future<List<OntologyModel>> getAllOntologies() async {
    try {
      final db = await database;
      final results = await db.query(_ontologiesTable, orderBy: 'name ASC');
      return results.map((m) => OntologyModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao listar ontologias: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteOntology(String id) async {
    try {
      final db = await database;
      final count = await db.delete(_ontologiesTable, where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      print('❌ Erro ao deletar ontologia: $e');
      return false;
    }
  }

  @override
  Future<bool> updateOntology(OntologyModel ontology) async {
    try {
      final db = await database;
      final count = await db.update(_ontologiesTable, ontology.toMap(),
          where: 'id = ?', whereArgs: [ontology.id]);
      return count > 0;
    } catch (e) {
      print('❌ Erro ao atualizar ontologia: $e');
      return false;
    }
  }

  // ============================================
  // Templates
  // ============================================

  @override
  Future<bool> saveTemplate(SemanticTemplateModel template) async {
    try {
      final db = await database;
      await db.insert(_templatesTable, template.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      print('✅ Template salvo: ${template.id}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar template: $e');
      return false;
    }
  }

  @override
  Future<SemanticTemplateModel?> getTemplate(String id) async {
    try {
      final db = await database;
      final results = await db.query(_templatesTable,
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (results.isEmpty) return null;
      return SemanticTemplateModel.fromMap(results.first);
    } catch (e) {
      print('❌ Erro ao buscar template: $e');
      return null;
    }
  }

  @override
  Future<List<SemanticTemplateModel>> getAllTemplates() async {
    try {
      final db = await database;
      final results = await db.query(_templatesTable, orderBy: 'name ASC');
      return results.map((m) => SemanticTemplateModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao listar templates: $e');
      return [];
    }
  }

  @override
  Future<List<SemanticTemplateModel>> getActiveTemplates() async {
    try {
      final db = await database;
      final results = await db.query(_templatesTable,
          where: 'is_active = ?', whereArgs: [1], orderBy: 'name ASC');
      return results.map((m) => SemanticTemplateModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao listar templates ativos: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteTemplate(String id) async {
    try {
      final db = await database;
      final count = await db.delete(_templatesTable, where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      print('❌ Erro ao deletar template: $e');
      return false;
    }
  }

  @override
  Future<bool> updateTemplate(SemanticTemplateModel template) async {
    try {
      final db = await database;
      final count = await db.update(_templatesTable, template.toMap(),
          where: 'id = ?', whereArgs: [template.id]);
      return count > 0;
    } catch (e) {
      print('❌ Erro ao atualizar template: $e');
      return false;
    }
  }

  // ============================================
  // Anotações
  // ============================================

  @override
  Future<bool> saveAnnotation(SemanticAnnotationModel annotation) async {
    try {
      final db = await database;
      await db.insert(_annotationsTable, annotation.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      print('✅ Anotação salva: ${annotation.id}');
      return true;
    } catch (e) {
      print('❌ Erro ao salvar anotação: $e');
      return false;
    }
  }

  @override
  Future<SemanticAnnotationModel?> getAnnotation(String id) async {
    try {
      final db = await database;
      final results = await db.query(_annotationsTable,
          where: 'id = ?', whereArgs: [id], limit: 1);
      if (results.isEmpty) return null;
      return SemanticAnnotationModel.fromMap(results.first);
    } catch (e) {
      print('❌ Erro ao buscar anotação: $e');
      return null;
    }
  }

  @override
  Future<SemanticAnnotationModel?> getAnnotationByNoteId(String noteId) async {
    try {
      final db = await database;
      final results = await db.query(_annotationsTable,
          where: 'note_id = ?', whereArgs: [noteId], limit: 1);
      if (results.isEmpty) return null;
      return SemanticAnnotationModel.fromMap(results.first);
    } catch (e) {
      print('❌ Erro ao buscar anotação por nota: $e');
      return null;
    }
  }

  @override
  Future<List<SemanticAnnotationModel>> getAllAnnotations() async {
    try {
      final db = await database;
      final results = await db.query(_annotationsTable, orderBy: 'created_at DESC');
      return results.map((m) => SemanticAnnotationModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao listar anotações: $e');
      return [];
    }
  }

  @override
  Future<List<SemanticAnnotationModel>> getAnnotationsByTemplate(String templateId) async {
    try {
      final db = await database;
      final results = await db.query(_annotationsTable,
          where: 'template_id = ?', whereArgs: [templateId]);
      return results.map((m) => SemanticAnnotationModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao buscar anotações por template: $e');
      return [];
    }
  }

  @override
  Future<List<SemanticAnnotationModel>> getAnnotationsByClass(String classUri) async {
    try {
      final db = await database;
      final results = await db.query(_annotationsTable,
          where: 'class_uri = ?', whereArgs: [classUri]);
      return results.map((m) => SemanticAnnotationModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao buscar anotações por classe: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteAnnotation(String id) async {
    try {
      final db = await database;
      final count = await db.delete(_annotationsTable, where: 'id = ?', whereArgs: [id]);
      return count > 0;
    } catch (e) {
      print('❌ Erro ao deletar anotação: $e');
      return false;
    }
  }

  @override
  Future<bool> deleteAnnotationByNoteId(String noteId) async {
    try {
      final db = await database;
      final count = await db.delete(_annotationsTable, where: 'note_id = ?', whereArgs: [noteId]);
      return count > 0;
    } catch (e) {
      print('❌ Erro ao deletar anotação por nota: $e');
      return false;
    }
  }

  // ============================================
  // Triplas RDF
  // ============================================

  @override
  Future<bool> saveTriple(RdfTripleModel triple) async {
    try {
      final db = await database;
      await db.insert(_triplesTable, triple.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      return true;
    } catch (e) {
      print('❌ Erro ao salvar tripla: $e');
      return false;
    }
  }

  @override
  Future<List<RdfTripleModel>> getAllTriples() async {
    try {
      final db = await database;
      final results = await db.query(_triplesTable);
      return results.map((m) => RdfTripleModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao listar triplas: $e');
      return [];
    }
  }

  @override
  Future<List<RdfTripleModel>> getTriplesBySubject(String subjectUri) async {
    try {
      final db = await database;
      final results = await db.query(_triplesTable,
          where: 'subject = ?', whereArgs: [subjectUri]);
      return results.map((m) => RdfTripleModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao buscar triplas por sujeito: $e');
      return [];
    }
  }

  @override
  Future<List<RdfTripleModel>> getTriplesByPredicate(String predicateUri) async {
    try {
      final db = await database;
      final results = await db.query(_triplesTable,
          where: 'predicate = ?', whereArgs: [predicateUri]);
      return results.map((m) => RdfTripleModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao buscar triplas por predicado: $e');
      return [];
    }
  }

  @override
  Future<List<RdfTripleModel>> getTriplesByObject(String object) async {
    try {
      final db = await database;
      final results = await db.query(_triplesTable,
          where: 'object = ?', whereArgs: [object]);
      return results.map((m) => RdfTripleModel.fromMap(m)).toList();
    } catch (e) {
      print('❌ Erro ao buscar triplas por objeto: $e');
      return [];
    }
  }

  @override
  Future<bool> removeTriplesBySubject(String subjectUri) async {
    try {
      final db = await database;
      await db.delete(_triplesTable, where: 'subject = ?', whereArgs: [subjectUri]);
      return true;
    } catch (e) {
      print('❌ Erro ao remover triplas: $e');
      return false;
    }
  }

  @override
  Future<bool> clearAllTriples() async {
    try {
      final db = await database;
      await db.delete(_triplesTable);
      return true;
    } catch (e) {
      print('❌ Erro ao limpar triplas: $e');
      return false;
    }
  }
}
