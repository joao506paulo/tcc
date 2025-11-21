import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/ontology.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/repositories/semantic_repository.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/usecases/create_ontology.dart';

class MockSemanticRepository extends Mock implements SemanticRepository {}

void main() {
  late CreateOntology usecase;
  late MockSemanticRepository mockRepository;

  setUp(() {
    mockRepository = MockSemanticRepository();
    usecase = CreateOntology(mockRepository);
  });

  final tParams = CreateOntologyParams(
    name: 'Minha Ontologia',
    description: 'Ontologia para aulas e eventos',
  );

  setUpAll(() {
    registerFallbackValue(Ontology(
      id: 'test',
      baseUri: 'http://test.com#',
      name: 'Test',
      createdAt: DateTime.now(),
    ));
  });

  test('deve criar uma ontologia com sucesso', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(tParams);

    expect(result.name, equals('Minha Ontologia'));
    expect(result.description, equals('Ontologia para aulas e eventos'));
    expect(result.baseUri, contains('minha-ontologia'));
    expect(result.id, isNotEmpty);
    expect(result.createdAt, isNotNull);
    verify(() => mockRepository.saveOntology(any())).called(1);
  });

  test('deve gerar URI base automaticamente a partir do nome', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => true);

    final params = CreateOntologyParams(name: 'Aulas e Eventos');
    final result = await usecase(params);

    expect(result.baseUri, contains('aulas-e-eventos'));
    expect(result.baseUri, startsWith('http://'));
    expect(result.baseUri, endsWith('#'));
  });

  test('deve usar URI base fornecido', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => true);

    final params = CreateOntologyParams(
      name: 'Test',
      baseUri: 'http://custom.com/ontology#',
    );
    final result = await usecase(params);

    expect(result.baseUri, equals('http://custom.com/ontology#'));
  });

  test('deve normalizar caracteres especiais no URI', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => true);

    final params = CreateOntologyParams(name: 'Ação & Reação');
    final result = await usecase(params);

    expect(result.baseUri, contains('acao-reacao'));
    expect(result.baseUri, isNot(contains('&')));
    expect(result.baseUri, isNot(contains('ç')));
  });

  test('deve lançar exceção quando salvar falha', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => false);

    expect(
      () => usecase(tParams),
      throwsA(isA<Exception>()),
    );
  });

  test('deve definir versão padrão como 1.0.0', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(tParams);

    expect(result.version, equals('1.0.0'));
  });

  test('deve inicializar com listas vazias', () async {
    when(() => mockRepository.saveOntology(any()))
        .thenAnswer((_) async => true);

    final result = await usecase(tParams);

    expect(result.classes, isEmpty);
    expect(result.properties, isEmpty);
    expect(result.imports, isEmpty);
  });
}
