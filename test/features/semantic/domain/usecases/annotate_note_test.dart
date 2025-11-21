import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/ontology_class.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/ontology_property.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/semantic_template.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/semantic_annotation.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/repositories/semantic_repository.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/usecases/annotate_note.dart';

class MockSemanticRepository extends Mock implements SemanticRepository {}

void main() {
  late AnnotateNote usecase;
  late MockSemanticRepository mockRepository;

  setUp(() {
    mockRepository = MockSemanticRepository();
    usecase = AnnotateNote(mockRepository);
  });

  // Template de teste
  final tTemplate = SemanticTemplate(
    id: 'template-aula',
    name: 'Aula',
    mainClass: OntologyClass(
      uri: 'http://meuapp.com/ontology#Aula',
      label: 'Aula',
    ),
    properties: [
      OntologyProperty(
        uri: 'http://meuapp.com/ontology#temData',
        label: 'Data',
        type: PropertyType.dataProperty,
        domainUri: 'http://meuapp.com/ontology#Aula',
        rangeUri: XsdDatatype.date,
        isRequired: true,
      ),
      OntologyProperty(
        uri: 'http://meuapp.com/ontology#temLocal',
        label: 'Local',
        type: PropertyType.dataProperty,
        domainUri: 'http://meuapp.com/ontology#Aula',
        rangeUri: XsdDatatype.string,
        isRequired: false,
      ),
    ],
    createdAt: DateTime.now(),
  );

  final tParams = AnnotateNoteParams(
    noteId: 'note-123',
    templateId: 'template-aula',
    propertyValues: {
      'http://meuapp.com/ontology#temData': '2025-11-20',
      'http://meuapp.com/ontology#temLocal': 'Sala 101',
    },
  );

  setUpAll(() {
    registerFallbackValue(SemanticAnnotation(
      id: 'test',
      noteId: 'test',
      templateId: 'test',
      classUri: 'http://test.com#Test',
      createdAt: DateTime.now(),
    ));
    registerFallbackValue(RdfTriple(
      subject: 'http://test.com#s',
      predicate: 'http://test.com#p',
      object: 'test',
    ));
  });

  test('deve criar anotação semântica com sucesso', () async {
    when(() => mockRepository.getTemplate(any()))
        .thenAnswer((_) async => tTemplate);
    when(() => mockRepository.getAnnotationByNoteId(any()))
        .thenAnswer((_) async => null);
    when(() => mockRepository.saveAnnotation(any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.addTriple(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(tParams);

    expect(result.noteId, equals('note-123'));
    expect(result.templateId, equals('template-aula'));
    expect(result.classUri, equals('http://meuapp.com/ontology#Aula'));
    expect(result.propertyValues.length, equals(2));
    verify(() => mockRepository.saveAnnotation(any())).called(1);
  });

  test('deve gerar triplas RDF ao anotar', () async {
    when(() => mockRepository.getTemplate(any()))
        .thenAnswer((_) async => tTemplate);
    when(() => mockRepository.getAnnotationByNoteId(any()))
        .thenAnswer((_) async => null);
    when(() => mockRepository.saveAnnotation(any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.addTriple(any()))
        .thenAnswer((_) async => true);

    await usecase(tParams);

    // Deve adicionar triplas: 1 tipo + 2 propriedades = 3 triplas
    verify(() => mockRepository.addTriple(any())).called(3);
  });

  test('deve lançar exceção quando template não existe', () async {
    when(() => mockRepository.getTemplate(any()))
        .thenAnswer((_) async => null);

    expect(
      () => usecase(tParams),
      throwsA(isA<Exception>()),
    );
  });

  test('deve lançar ValidationException quando propriedade obrigatória falta', () async {
    when(() => mockRepository.getTemplate(any()))
        .thenAnswer((_) async => tTemplate);

    final paramsWithoutRequired = AnnotateNoteParams(
      noteId: 'note-123',
      templateId: 'template-aula',
      propertyValues: {
        // Faltando 'temData' que é obrigatório
        'http://meuapp.com/ontology#temLocal': 'Sala 101',
      },
    );

    expect(
      () => usecase(paramsWithoutRequired),
      throwsA(isA<ValidationException>()),
    );
  });

  test('deve atualizar anotação existente', () async {
    final existingAnnotation = SemanticAnnotation(
      id: 'existing-1',
      noteId: 'note-123',
      templateId: 'template-aula',
      classUri: 'http://meuapp.com/ontology#Aula',
      propertyValues: {'old': 'value'},
      createdAt: DateTime(2025, 1, 1),
    );

    when(() => mockRepository.getTemplate(any()))
        .thenAnswer((_) async => tTemplate);
    when(() => mockRepository.getAnnotationByNoteId(any()))
        .thenAnswer((_) async => existingAnnotation);
    when(() => mockRepository.saveAnnotation(any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.removeTriplesForNote(any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.addTriple(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(tParams);

    expect(result.id, equals('existing-1')); // Mantém ID original
    expect(result.updatedAt, isNotNull);
    verify(() => mockRepository.removeTriplesForNote('note-123')).called(1);
  });

  test('deve incluir relações na anotação', () async {
    when(() => mockRepository.getTemplate(any()))
        .thenAnswer((_) async => tTemplate);
    when(() => mockRepository.getAnnotationByNoteId(any()))
        .thenAnswer((_) async => null);
    when(() => mockRepository.saveAnnotation(any()))
        .thenAnswer((_) async => true);
    when(() => mockRepository.addTriple(any()))
        .thenAnswer((_) async => true);

    final paramsWithRelations = AnnotateNoteParams(
      noteId: 'note-123',
      templateId: 'template-aula',
      propertyValues: {
        'http://meuapp.com/ontology#temData': '2025-11-20',
      },
      relations: [
        NoteRelation(
          propertyUri: 'http://meuapp.com/ontology#temProfessor',
          targetNoteId: 'note-prof-1',
        ),
      ],
    );

    final result = await usecase(paramsWithRelations);

    expect(result.relations.length, equals(1));
    // 1 tipo + 1 propriedade + 1 relação = 3 triplas
    verify(() => mockRepository.addTriple(any())).called(3);
  });
}
