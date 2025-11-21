import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_clean_tdd_app/features/semantic/domain/entities/ontology_property.dart';

void main() {
  group('OntologyProperty', () {
    final tObjectProperty = OntologyProperty(
      uri: 'http://meuapp.com/ontology#temProfessor',
      label: 'tem Professor',
      description: 'Relaciona uma aula a um professor',
      type: PropertyType.objectProperty,
      domainUri: 'http://meuapp.com/ontology#Aula',
      rangeUri: 'http://meuapp.com/ontology#Pessoa',
      isRequired: true,
      isFunctional: true,
      inversePropertyUri: 'http://meuapp.com/ontology#lecionaEm',
    );

    final tDataProperty = OntologyProperty(
      uri: 'http://meuapp.com/ontology#temData',
      label: 'tem Data',
      type: PropertyType.dataProperty,
      domainUri: 'http://meuapp.com/ontology#Evento',
      rangeUri: XsdDatatype.date,
      isRequired: true,
    );

    test('deve criar ObjectProperty com todos os campos', () {
      expect(tObjectProperty.uri, equals('http://meuapp.com/ontology#temProfessor'));
      expect(tObjectProperty.label, equals('tem Professor'));
      expect(tObjectProperty.type, equals(PropertyType.objectProperty));
      expect(tObjectProperty.isRequired, isTrue);
      expect(tObjectProperty.isFunctional, isTrue);
      expect(tObjectProperty.inversePropertyUri, isNotNull);
    });

    test('deve criar DataProperty corretamente', () {
      expect(tDataProperty.type, equals(PropertyType.dataProperty));
      expect(tDataProperty.rangeUri, equals(XsdDatatype.date));
    });

    test('deve identificar ObjectProperty', () {
      expect(tObjectProperty.isObjectProperty, isTrue);
      expect(tObjectProperty.isDataProperty, isFalse);
    });

    test('deve identificar DataProperty', () {
      expect(tDataProperty.isObjectProperty, isFalse);
      expect(tDataProperty.isDataProperty, isTrue);
    });

    test('deve extrair nome local da URI', () {
      expect(tObjectProperty.localName, equals('temProfessor'));
      expect(tDataProperty.localName, equals('temData'));
    });

    test('deve criar cópia com copyWith', () {
      final copy = tObjectProperty.copyWith(isRequired: false);
      
      expect(copy.isRequired, isFalse);
      expect(copy.uri, equals(tObjectProperty.uri));
      expect(copy.label, equals(tObjectProperty.label));
    });

    test('deve comparar igualdade por URI', () {
      final sameProperty = OntologyProperty(
        uri: 'http://meuapp.com/ontology#temProfessor',
        label: 'Outro Label',
        type: PropertyType.objectProperty,
        domainUri: 'http://outro.com/Classe',
        rangeUri: 'http://outro.com/Range',
      );
      
      expect(tObjectProperty, equals(sameProperty));
    });
  });

  group('PropertyType', () {
    test('deve ter dois tipos', () {
      expect(PropertyType.values.length, equals(2));
      expect(PropertyType.values, contains(PropertyType.objectProperty));
      expect(PropertyType.values, contains(PropertyType.dataProperty));
    });
  });

  group('XsdDatatype', () {
    test('deve ter todos os datatypes definidos', () {
      expect(XsdDatatype.string, isNotEmpty);
      expect(XsdDatatype.integer, isNotEmpty);
      expect(XsdDatatype.decimal, isNotEmpty);
      expect(XsdDatatype.boolean, isNotEmpty);
      expect(XsdDatatype.date, isNotEmpty);
      expect(XsdDatatype.dateTime, isNotEmpty);
      expect(XsdDatatype.time, isNotEmpty);
      expect(XsdDatatype.anyUri, isNotEmpty);
    });

    test('deve retornar label legível', () {
      expect(XsdDatatype.getLabel(XsdDatatype.string), equals('Texto'));
      expect(XsdDatatype.getLabel(XsdDatatype.integer), equals('Número Inteiro'));
      expect(XsdDatatype.getLabel(XsdDatatype.date), equals('Data'));
      expect(XsdDatatype.getLabel(XsdDatatype.boolean), equals('Verdadeiro/Falso'));
    });

    test('deve retornar nome local para datatype desconhecido', () {
      final label = XsdDatatype.getLabel('http://custom.com/type#MeuTipo');
      expect(label, equals('MeuTipo'));
    });

    test('deve listar todos os datatypes', () {
      expect(XsdDatatype.all.length, equals(8));
      expect(XsdDatatype.all, contains(XsdDatatype.string));
      expect(XsdDatatype.all, contains(XsdDatatype.date));
    });
  });
}
