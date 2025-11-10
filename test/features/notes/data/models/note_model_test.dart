import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_tdd_app/features/notes/data/models/note_model.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';

void main() {
  final tNoteModel = NoteModel(
    id: '1',
    content: '# Teste\n\nConteúdo de teste',
    metadata: {
      'title': 'Teste',
      'tags': ['teste', 'exemplo'],
      'created_at': '2025-11-10',
    },
  );

  group('NoteModel', () {
    test('deve ser uma subclasse de Note', () {
      expect(tNoteModel, isA<Note>());
    });

    group('fromJson', () {
      test('deve retornar um NoteModel válido a partir de JSON', () {
        final json = {
          'id': '1',
          'content': '# Teste\n\nConteúdo de teste',
          'metadata': {
            'title': 'Teste',
            'tags': ['teste', 'exemplo'],
            'created_at': '2025-11-10',
          },
        };

        final result = NoteModel.fromJson(json);

        expect(result.id, equals('1'));
        expect(result.content, equals('# Teste\n\nConteúdo de teste'));
        expect(result.metadata['title'], equals('Teste'));
      });

      test('deve lidar com metadata nulo', () {
        final json = {
          'id': '1',
          'content': 'Conteúdo',
          'metadata': null,
        };

        final result = NoteModel.fromJson(json);

        expect(result.metadata, isEmpty);
      });
    });

    group('fromMap', () {
      test('deve retornar um NoteModel válido a partir de Map do database', () {
        final map = {
          'id': '1',
          'content': '# Teste\n\nConteúdo de teste',
          'metadata': jsonEncode({
            'title': 'Teste',
            'tags': ['teste', 'exemplo'],
            'created_at': '2025-11-10',
          }),
        };

        final result = NoteModel.fromMap(map);

        expect(result.id, equals('1'));
        expect(result.content, equals('# Teste\n\nConteúdo de teste'));
        expect(result.metadata['title'], equals('Teste'));
        expect(result.metadata['tags'], isA<List>());
      });
    });

    group('toJson', () {
      test('deve retornar um Map JSON válido', () {
        final result = tNoteModel.toJson();

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('1'));
        expect(result['content'], equals('# Teste\n\nConteúdo de teste'));
        expect(result['metadata'], isA<Map>());
        expect(result['metadata']['title'], equals('Teste'));
      });
    });

    group('toMap', () {
      test('deve retornar um Map válido para database', () {
        final result = tNoteModel.toMap();

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('1'));
        expect(result['content'], equals('# Teste\n\nConteúdo de teste'));
        expect(result['metadata'], isA<String>());
        
        final metadata = jsonDecode(result['metadata'] as String);
        expect(metadata['title'], equals('Teste'));
      });
    });

    group('toEntity', () {
      test('deve converter NoteModel para Note entity', () {
        final result = tNoteModel.toEntity();

        expect(result, isA<Note>());
        expect(result.id, equals(tNoteModel.id));
        expect(result.content, equals(tNoteModel.content));
        expect(result.metadata, equals(tNoteModel.metadata));
      });
    });

    group('fromEntity', () {
      test('deve criar NoteModel a partir de Note entity', () {
        final note = Note(
          id: '2',
          content: 'Conteúdo',
          metadata: {'key': 'value'},
        );

        final result = NoteModel.fromEntity(note);

        expect(result, isA<NoteModel>());
        expect(result.id, equals(note.id));
        expect(result.content, equals(note.content));
        expect(result.metadata, equals(note.metadata));
      });
    });

    group('copyWith', () {
      test('deve criar uma cópia com valores alterados', () {
        final result = tNoteModel.copyWith(
          content: 'Novo conteúdo',
        );

        expect(result.id, equals(tNoteModel.id));
        expect(result.content, equals('Novo conteúdo'));
        expect(result.metadata, equals(tNoteModel.metadata));
      });

      test('deve manter valores originais quando não especificados', () {
        final result = tNoteModel.copyWith();

        expect(result.id, equals(tNoteModel.id));
        expect(result.content, equals(tNoteModel.content));
        expect(result.metadata, equals(tNoteModel.metadata));
      });
    });
  });
}
