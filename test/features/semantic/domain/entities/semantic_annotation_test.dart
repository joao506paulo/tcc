import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/semantic_annotation.dart';

void main() {
  group('SemanticAnnotation', () {
    final tAnnotation = SemanticAnnotation(
      id: '1',
      noteId: 'note-123',
      templateId: 'template-aula',
      classUri: 'http://meuapp.com/ontology#Aula',
      propertyValues: {
        'http://meuapp.com/ontology#temData': '2025-11-20',
        'http://meuapp.com/ontology#temLocal': 'Sala 101',
      },
      relations: [
        NoteRelation(
          propertyUri: 'http://meuapp.com/ontology#temProfessor',
          targetNoteId: 'note-prof-1',
          label: 'Professor João',
        ),
      ],
      createdAt: DateTime(2025, 11, 20),
    );

    test('deve criar anotação com todos os campos', () {
      expect(tAnnotation.id, equals('1'));
      expect(tAnnotation.noteId, equals('note-123'));
      expect(tAnnotation.templateId, equals('template-aula'));
      expect(tAnnotation.classUri, equals('http://meuapp.com/ontology#Aula'));
      expect(tAnnotation.propertyValues.length, equals(2));
      expect(tAnnotation.relations.length, equals(1));
    });

    test('deve gerar triplas RDF corretamente', () {
      final triples = tAnnotation.toTriples();
      
      // Deve ter: 1 tipo + 2 propriedades + 1 relação = 4 triplas
      expect(triples.length, equals(4));
      
      // Verificar tripla de tipo
      final typeTriple = triples.firstWhere(
        (t) => t.predicate.contains('rdf-syntax-ns#type'),
      );
      expect(typeTriple.object, equals('http://meuapp.com/ontology#Aula'));
      expect(typeTriple.isLiteral, isFalse);
      
      // Verificar tripla de data
      final dateTriple = triples.firstWhere(
        (t) => t.predicate.contains('temData'),
      );
      expect(dateTriple.object, equals('2025-11-20'));
      expect(dateTriple.isLiteral, isTrue);
      
      // Verificar tripla de relação
      final relationTriple = triples.firstWhere(
        (t) => t.predicate.contains('temProfessor'),
      );
      expect(relationTriple.object, contains('note-prof-1'));
      expect(relationTriple.isLiteral, isFalse);
    });

    test('deve gerar RDF/XML válido', () {
      final rdfXml = tAnnotation.toRdfXml();
      
      expect(rdfXml, contains('<?xml version="1.0"'));
      expect(rdfXml, contains('rdf:RDF'));
      expect(rdfXml, contains('xmlns:rdf='));
      expect(rdfXml, contains('xmlns:owl='));
      expect(rdfXml, contains('Aula'));
      expect(rdfXml, contains('temData'));
      expect(rdfXml, contains('2025-11-20'));
      expect(rdfXml, contains('temProfessor'));
      expect(rdfXml, contains('rdf:resource='));
    });

    test('deve escapar caracteres XML especiais', () {
      final annotationWithSpecialChars = SemanticAnnotation(
        id: '2',
        noteId: 'note-456',
        templateId: 'template-test',
        classUri: 'http://meuapp.com/ontology#Test',
        propertyValues: {
          'http://meuapp.com/ontology#descricao': 'Texto com <tags> & "aspas"',
        },
        createdAt: DateTime.now(),
      );
      
      final rdfXml = annotationWithSpecialChars.toRdfXml();
      
      expect(rdfXml, contains('&lt;tags&gt;'));
      expect(rdfXml, contains('&amp;'));
      expect(rdfXml, contains('&quot;'));
    });

    test('deve criar cópia com copyWith', () {
      final copy = tAnnotation.copyWith(
        propertyValues: {'nova': 'propriedade'},
      );
      
      expect(copy.id, equals(tAnnotation.id));
      expect(copy.noteId, equals(tAnnotation.noteId));
      expect(copy.propertyValues, equals({'nova': 'propriedade'}));
    });
  });

  group('NoteRelation', () {
    test('deve criar relação corretamente', () {
      final relation = NoteRelation(
        propertyUri: 'http://meuapp.com/ontology#temProfessor',
        targetNoteId: 'note-prof-1',
        label: 'Professor João',
      );
      
      expect(relation.propertyUri, isNotEmpty);
      expect(relation.targetNoteId, equals('note-prof-1'));
      expect(relation.label, equals('Professor João'));
    });

    test('deve comparar igualdade', () {
      final relation1 = NoteRelation(
        propertyUri: 'http://meuapp.com/ontology#temProfessor',
        targetNoteId: 'note-prof-1',
      );
      
      final relation2 = NoteRelation(
        propertyUri: 'http://meuapp.com/ontology#temProfessor',
        targetNoteId: 'note-prof-1',
        label: 'Label diferente', // Não afeta igualdade
      );
      
      expect(relation1, equals(relation2));
    });
  });

  group('RdfTriple', () {
    test('deve criar tripla com literal', () {
      final triple = RdfTriple(
        subject: 'http://meuapp.com/notes#1',
        predicate: 'http://meuapp.com/ontology#temNome',
        object: 'João',
        isLiteral: true,
        datatype: 'http://www.w3.org/2001/XMLSchema#string',
      );
      
      expect(triple.isLiteral, isTrue);
      expect(triple.datatype, isNotNull);
    });

    test('deve criar tripla com URI', () {
      final triple = RdfTriple(
        subject: 'http://meuapp.com/notes#1',
        predicate: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
        object: 'http://meuapp.com/ontology#Aula',
        isLiteral: false,
      );
      
      expect(triple.isLiteral, isFalse);
    });

    test('deve gerar formato N-Triples para literal', () {
      final triple = RdfTriple(
        subject: 'http://meuapp.com/notes#1',
        predicate: 'http://meuapp.com/ontology#temNome',
        object: 'João',
        isLiteral: true,
      );
      
      final ntriples = triple.toNTriples();
      
      expect(ntriples, contains('<http://meuapp.com/notes#1>'));
      expect(ntriples, contains('<http://meuapp.com/ontology#temNome>'));
      expect(ntriples, contains('"João"'));
      expect(ntriples, endsWith('.'));
    });

    test('deve gerar formato N-Triples para URI', () {
      final triple = RdfTriple(
        subject: 'http://meuapp.com/notes#1',
        predicate: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type',
        object: 'http://meuapp.com/ontology#Aula',
        isLiteral: false,
      );
      
      final ntriples = triple.toNTriples();
      
      expect(ntriples, contains('<http://meuapp.com/ontology#Aula>'));
      expect(ntriples, isNot(contains('"')));
    });

    test('deve incluir datatype em N-Triples', () {
      final triple = RdfTriple(
        subject: 'http://meuapp.com/notes#1',
        predicate: 'http://meuapp.com/ontology#temIdade',
        object: '25',
        isLiteral: true,
        datatype: 'http://www.w3.org/2001/XMLSchema#integer',
      );
      
      final ntriples = triple.toNTriples();
      
      expect(ntriples, contains('^^<http://www.w3.org/2001/XMLSchema#integer>'));
    });

    test('deve incluir language tag em N-Triples', () {
      final triple = RdfTriple(
        subject: 'http://meuapp.com/notes#1',
        predicate: 'http://meuapp.com/ontology#temDescricao',
        object: 'Uma descrição',
        isLiteral: true,
        language: 'pt-BR',
      );
      
      final ntriples = triple.toNTriples();
      
      expect(ntriples, contains('@pt-BR'));
    });
  });
}
