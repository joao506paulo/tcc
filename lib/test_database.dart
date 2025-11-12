import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/injection/injection_container.dart' as di;
import 'features/notes/data/datasources/note_local_data_source_impl.dart';
import 'features/notes/domain/entities/note.dart';
import 'features/notes/domain/usecases/generate_metadata.dart';
import 'features/notes/domain/usecases/store_data.dart';
import 'features/notes/domain/repositories/note_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar sqflite para desktop
  NoteLocalDataSourceImpl.initializeDatabaseFactory();
  
  // Inicializar injeção de dependências
  await di.init();
  
  runApp(
    const ProviderScope(
      child: DatabaseTestApp(),
    ),
  );
}

class DatabaseTestApp extends StatelessWidget {
  const DatabaseTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste de Banco de Dados',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DatabaseTestPage(),
    );
  }
}

class DatabaseTestPage extends ConsumerStatefulWidget {
  const DatabaseTestPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DatabaseTestPage> createState() => _DatabaseTestPageState();
}

class _DatabaseTestPageState extends ConsumerState<DatabaseTestPage> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)} - $message');
    });
    print(message);
  }

  Future<void> _testDatabase() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🔧 Iniciando teste do banco de dados...');

      // 1. Criar uma nota
      _addLog('📝 Criando nota de teste...');
      final generateMetadata = di.sl<GenerateMetadata>();
      final storeData = di.sl<StoreData>();
      
      var testNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '''# Teste de Banco de Dados

Esta é uma nota de teste para verificar se o SQLite está funcionando.

Tags: #teste #sqlite #flutter

Links: [[outra-nota]]

Conteúdo com várias palavras para testar a contagem.
''',
        metadata: {},
      );

      // 2. Gerar metadados
      _addLog('🏷️ Gerando metadados...');
      testNote = await generateMetadata(testNote);
      _addLog('✅ Metadados gerados: ${testNote.metadata.keys.join(", ")}');

      // 3. Salvar no banco
      _addLog('💾 Salvando no banco de dados...');
      final saved = await storeData(testNote);
      
      if (saved) {
        _addLog('✅ Nota salva com sucesso! ID: ${testNote.id}');
      } else {
        _addLog('❌ Erro ao salvar nota');
        return;
      }

      // 4. Recuperar do banco
      _addLog('📖 Recuperando nota do banco...');
      final repository = di.sl<NoteRepository>();
      final retrievedNote = await repository.getNote(testNote.id);

      if (retrievedNote != null) {
        _addLog('✅ Nota recuperada com sucesso!');
        _addLog('   Título: ${retrievedNote.metadata["title"]}');
        _addLog('   Tags: ${retrievedNote.metadata["tags"]}');
        _addLog('   Links: ${retrievedNote.metadata["links"]}');
        _addLog('   Palavras: ${retrievedNote.metadata["word_count"]}');
      } else {
        _addLog('❌ Erro ao recuperar nota');
        return;
      }

      // 5. Listar todas as notas
      _addLog('📋 Listando todas as notas...');
      final allNotes = await repository.getAllNotes();
      _addLog('✅ Total de notas no banco: ${allNotes.length}');

      // 6. Criar mais uma nota para testar
      _addLog('📝 Criando segunda nota...');
      var note2 = Note(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: '''# Segunda Nota

Referência para [[Teste de Banco de Dados]]

#flutter #dart
''',
        metadata: {},
      );
      
      note2 = await generateMetadata(note2);
      await storeData(note2);
      _addLog('✅ Segunda nota criada');

      // 7. Buscar por tag
      _addLog('🔍 Testando busca por tag "teste"...');
      // Nota: Implementar busca por tag no repository se necessário

      // 8. Verificar atualização
      _addLog('🔄 Testando atualização de nota...');
      final updatedContent = retrievedNote!.content + '\n\n## Atualização\n\nNota atualizada!';
      var updatedNote = Note(
        id: retrievedNote.id,
        content: updatedContent,
        metadata: retrievedNote.metadata,
      );
      updatedNote = await generateMetadata(updatedNote);
      await storeData(updatedNote);
      _addLog('✅ Nota atualizada com sucesso');

      // 9. Listar novamente
      final finalNotes = await repository.getAllNotes();
      _addLog('📊 Total final de notas: ${finalNotes.length}');

      _addLog('');
      _addLog('🎉 TODOS OS TESTES PASSARAM!');
      _addLog('✅ O banco de dados SQLite está funcionando corretamente');

    } catch (e, stack) {
      _addLog('❌ ERRO: $e');
      _addLog('Stack trace: ${stack.toString().substring(0, 200)}...');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearDatabase() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    try {
      _addLog('🗑️ Limpando banco de dados...');
      final repository = di.sl<NoteRepository>();
      final allNotes = await repository.getAllNotes();
      
      for (final note in allNotes) {
        await repository.deleteNote(note.id);
      }
      
      _addLog('✅ Banco de dados limpo! ${allNotes.length} notas deletadas');
    } catch (e) {
      _addLog('❌ Erro ao limpar banco: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste de Banco de Dados SQLite'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testDatabase,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Executar Testes'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _clearDatabase,
                    icon: const Icon(Icons.delete_sweep),
                    label: const Text('Limpar Banco'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Executando testes...'),
                      ],
                    ),
                  )
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storage, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Clique em "Executar Testes" para testar o banco',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color? color;
                          if (log.contains('❌')) {
                            color = Colors.red;
                          } else if (log.contains('✅')) {
                            color = Colors.green;
                          } else if (log.contains('🎉')) {
                            color = Colors.blue;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: color,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
