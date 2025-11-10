import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/entities/note.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/repositories/note_repository.dart';
import 'package:flutter_clean_tdd_app/features/notes/domain/usecases/create_template.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

void main() {
  late CreateTemplate usecase;
  late MockNoteRepository mockRepository;

  setUp(() {
    mockRepository = MockNoteRepository();
    usecase = CreateTemplate(mockRepository);
  });

  final tParams = TemplateParams(
    templateType: 'daily-note',
    variables: {
      'date': '2025-11-10',
      'day_of_week': 'Segunda-feira',
    },
  );

  final tTemplateNote = Note(
    id: 'template-daily-2025-11-10',
    content: '''---
title: Daily Note - 2025-11-10
date: 2025-11-10
day_of_week: Segunda-feira
template: daily-note
---

# 2025-11-10 - Segunda-feira

## Tarefas
- [ ] 

## Notas do Dia


## Reflexões


## Links
- [[2025-11-09]]
- [[2025-11-11]]
''',
    metadata: {
      'title': 'Daily Note - 2025-11-10',
      'date': '2025-11-10',
      'template': 'daily-note',
      'is_template': false,
    },
  );

  setUpAll(() {
    registerFallbackValue(tParams);
  });

  test('deve criar uma nota a partir de um template', () async {
    when(() => mockRepository.createFromTemplate(any()))
        .thenAnswer((_) async => tTemplateNote);

    final result = await usecase(tParams);

    expect(result.content, isNotEmpty);
    expect(result.metadata['template'], equals('daily-note'));
    verify(() => mockRepository.createFromTemplate(tParams)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('deve substituir variáveis no template', () async {
    when(() => mockRepository.createFromTemplate(any()))
        .thenAnswer((_) async => tTemplateNote);

    final result = await usecase(tParams);

    expect(result.content.contains('2025-11-10'), isTrue);
    expect(result.content.contains('Segunda-feira'), isTrue);
  });

  test('deve criar template de nota diária', () async {
    when(() => mockRepository.createFromTemplate(any()))
        .thenAnswer((_) async => tTemplateNote);

    final result = await usecase(tParams);

    expect(result.content.contains('Tarefas'), isTrue);
    expect(result.content.contains('Notas do Dia'), isTrue);
    expect(result.content.contains('Reflexões'), isTrue);
  });

  test('deve criar template de projeto', () async {
    final projectParams = TemplateParams(
      templateType: 'project',
      variables: {
        'project_name': 'Novo Projeto',
        'start_date': '2025-11-10',
      },
    );

    final projectNote = Note(
      id: 'template-project-novo-projeto',
      content: '''---
title: Novo Projeto
type: project
start_date: 2025-11-10
template: project
---

# Novo Projeto

## Objetivo


## Tarefas
- [ ] 

## Recursos


## Timeline

''',
      metadata: {
        'title': 'Novo Projeto',
        'type': 'project',
        'template': 'project',
      },
    );

    when(() => mockRepository.createFromTemplate(any()))
        .thenAnswer((_) async => projectNote);

    final result = await usecase(projectParams);

    expect(result.content.contains('Objetivo'), isTrue);
    expect(result.content.contains('Timeline'), isTrue);
    expect(result.metadata['type'], equals('project'));
  });

  test('deve criar template de reunião', () async {
    final meetingParams = TemplateParams(
      templateType: 'meeting',
      variables: {
        'meeting_title': 'Reunião de Planejamento',
        'date': '2025-11-10',
        'participants': 'João, Maria, Pedro',
      },
    );

    final meetingNote = Note(
      id: 'template-meeting-planejamento',
      content: '''---
title: Reunião de Planejamento
date: 2025-11-10
participants: João, Maria, Pedro
template: meeting
---

# Reunião de Planejamento

**Data:** 2025-11-10
**Participantes:** João, Maria, Pedro

## Pauta


## Discussão


## Ações
- [ ] 

## Próximos Passos

''',
      metadata: {
        'title': 'Reunião de Planejamento',
        'template': 'meeting',
      },
    );

    when(() => mockRepository.createFromTemplate(any()))
        .thenAnswer((_) async => meetingNote);

    final result = await usecase(meetingParams);

    expect(result.content.contains('Pauta'), isTrue);
    expect(result.content.contains('Ações'), isTrue);
  });

  test('deve incluir metadados do template na nota criada', () async {
    when(() => mockRepository.createFromTemplate(any()))
        .thenAnswer((_) async => tTemplateNote);

    final result = await usecase(tParams);

    expect(result.metadata, isNotEmpty);
    expect(result.metadata['template'], isNotNull);
    expect(result.metadata['date'], isNotNull);
  });
}
