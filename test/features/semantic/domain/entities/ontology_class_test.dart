import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/ontology_class.dart';

void main() {
  group('OntologyClass', () {
    final tClass = OntologyClass(
      uri: 'http://meuapp.com/ontology#Aula',
      label: 'Aula',
      description: 'Representa uma aula',
      parentClassUri: 'http://meuapp.com/ontology#Evento',
      propertyUris: [
        'http://meuapp.com/ontology#temProfessor',
        'http://meuapp.com/ontology#temData',
      ],
      restrictions: [
        OntologyRestriction(
          type: RestrictionType.maxCardinality,
          propertyUri: 'http://meuapp.com/ontology#temProfessor',
          value: 1,
        ),
      ],
    );

    test('deve criar uma classe com todos os campos', () {
      expect(tClass.uri, equals('http://meuapp.com/ontology#Aula'));
      expect(tClass.label, equals('Aula'));
      expect(tClass.description, equals('Representa uma aula'));
      expect(tClass.parentClassUri, equals('http://meuapp.com/ontology#Evento'));
      expect(tClass.propertyUris.length, equals(2));
      expect(tClass.restrictions.length, equals(1));
    });

    test('deve extrair nome local da URI com #', () {
      expect(tClass.localName, equals('Aula'));
    });

    test('deve extrair nome local da URI com /', () {
      final classWithSlash = OntologyClass(
        uri: 'http://meuapp.com/ontology/Pessoa',
        label: 'Pessoa',
      );
      expect(classWithSlash.localName, equals('Pessoa'));
    });

    test('deve verificar se é subclasse', () {
      expect(
        tClass.isSubclassOf('http://meuapp.com/ontology#Evento'),
        isTrue,
      );
      expect(
        tClass.isSubclassOf('http://meuapp.com/ontology#Pessoa'),
        isFalse,
      );
    });

    test('deve criar cópia com copyWith', () {
      final copy = tClass.copyWith(label: 'Aula Atualizada');
      
      expect(copy.label, equals('Aula Atualizada'));
      expect(copy.uri, equals(tClass.uri)); // Mantém original
      expect(copy.description, equals(tClass.description)); // Mantém original
    });

    test('deve comparar igualdade por URI', () {
      final sameClass = OntologyClass(
        uri: 'http://meuapp.com/ontology#Aula',
        label: 'Outro Label', // Diferente
      );
      
      expect(tClass, equals(sameClass));
    });

    test('deve ter hashCode baseado na URI', () {
      expect(tClass.hashCode, equals(tClass.uri.hashCode));
    });
  });

  group('OntologyRestriction', () {
    test('deve formatar maxCardinality corretamente', () {
      final restriction = OntologyRestriction(
        type: RestrictionType.maxCardinality,
        propertyUri: 'http://meuapp.com/ontology#temProfessor',
        value: 1,
      );
      
      expect(
        restriction.toString(),
        equals('max 1 http://meuapp.com/ontology#temProfessor'),
      );
    });

    test('deve formatar minCardinality corretamente', () {
      final restriction = OntologyRestriction(
        type: RestrictionType.minCardinality,
        propertyUri: 'http://meuapp.com/ontology#temAluno',
        value: 5,
      );
      
      expect(
        restriction.toString(),
        equals('min 5 http://meuapp.com/ontology#temAluno'),
      );
    });

    test('deve formatar someValuesFrom corretamente', () {
      final restriction = OntologyRestriction(
        type: RestrictionType.someValuesFrom,
        propertyUri: 'http://meuapp.com/ontology#temProfessor',
        value: 'http://meuapp.com/ontology#Professor',
      );
      
      expect(
        restriction.toString(),
        contains('some'),
      );
    });
  });

  group('RestrictionType', () {
    test('deve ter todos os tipos definidos', () {
      expect(RestrictionType.values.length, equals(6));
      expect(RestrictionType.values, contains(RestrictionType.maxCardinality));
      expect(RestrictionType.values, contains(RestrictionType.minCardinality));
      expect(RestrictionType.values, contains(RestrictionType.exactCardinality));
      expect(RestrictionType.values, contains(RestrictionType.someValuesFrom));
      expect(RestrictionType.values, contains(RestrictionType.allValuesFrom));
      expect(RestrictionType.values, contains(RestrictionType.hasValue));
    });
  });
}
