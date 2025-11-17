import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  // Inicializar FFI ANTES de qualquer coisa
  sqfliteFfiInit();
  
  runApp(const MemoryDatabaseTestApp());
}

class MemoryDatabaseTestApp extends StatelessWidget {
  const MemoryDatabaseTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste SQLite em Memória',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MemoryDatabaseTestPage(),
    );
  }
}

class MemoryDatabaseTestPage extends StatefulWidget {
  const MemoryDatabaseTestPage({Key? key}) : super(key: key);

  @override
  State<MemoryDatabaseTestPage> createState() => _MemoryDatabaseTestPageState();
}

class _MemoryDatabaseTestPageState extends State<MemoryDatabaseTestPage> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  Future<void> _testMemoryDatabase() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    Database? db;

    try {
      _addLog('🔧 Iniciando teste com banco em memória...');

      // 1. Criar banco EM MEMÓRIA usando databaseFactoryFfi
      _addLog('🗄️ Criando banco de dados em memória...');
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath, // Banco em memória!
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (Database db, int version) async {
            _addLog('🏗️ Criando tabela...');
            await db.execute('''
              CREATE TABLE test_notes (
                id TEXT PRIMARY KEY,
                content TEXT NOT NULL,
                metadata TEXT NOT NULL,
                created_at TEXT NOT NULL
              )
            ''');
            _addLog('✅ Tabela criada!');
          },
        ),
      );
      _addLog('✅ Banco em memória criado com sucesso!');

      // 2. Inserir uma nota de teste
      _addLog('📝 Inserindo nota...');
      final now = DateTime.now().toIso8601String();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      await db.insert(
        'test_notes',
        {
          'id': id,
          'content': '# Teste de Nota\n\nConteúdo com #tag e [[link]]',
          'metadata': '{"title":"Teste","tags":["tag"],"links":["link"]}',
          'created_at': now,
        },
      );
      _addLog('✅ Nota inserida! ID: $id');

      // 3. Ler a nota
      _addLog('📖 Lendo nota...');
      final notes = await db.query('test_notes');
      _addLog('✅ Encontradas ${notes.length} nota(s)');
      
      if (notes.isNotEmpty) {
        final note = notes.first;
        _addLog('   ID: ${note['id']}');
        _addLog('   Content: ${note['content']}');
        _addLog('   Metadata: ${note['metadata']}');
      }

      // 4. Atualizar a nota
      _addLog('🔄 Atualizando nota...');
      await db.update(
        'test_notes',
        {'content': '# Nota Atualizada\n\nConteúdo modificado'},
        where: 'id = ?',
        whereArgs: [id],
      );
      _addLog('✅ Nota atualizada!');

      // 5. Verificar atualização
      final updated = await db.query('test_notes', where: 'id = ?', whereArgs: [id]);
      _addLog('📖 Conteúdo após update: ${updated.first['content']}');

      // 6. Inserir mais notas
      _addLog('📝 Inserindo mais notas...');
      for (int i = 1; i <= 3; i++) {
        await db.insert('test_notes', {
          'id': '${DateTime.now().millisecondsSinceEpoch + i}',
          'content': '# Nota $i',
          'metadata': '{"title":"Nota $i"}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
      _addLog('✅ 3 notas adicionais inseridas');

      // 7. Contar total
      final allNotes = await db.query('test_notes');
      _addLog('📊 Total de notas: ${allNotes.length}');

      // 8. Deletar uma nota
      _addLog('🗑️ Deletando nota original...');
      await db.delete('test_notes', where: 'id = ?', whereArgs: [id]);
      _addLog('✅ Nota deletada!');

      // 9. Verificar deleção
      final remaining = await db.query('test_notes');
      _addLog('📊 Notas restantes: ${remaining.length}');

      _addLog('');
      _addLog('🎉 TODOS OS TESTES PASSARAM!');
      _addLog('✅ SQLite em memória funciona perfeitamente!');
      _addLog('');
      _addLog('💡 Agora podemos usar em arquivo também');

    } catch (e, stackTrace) {
      _addLog('❌ ERRO: $e');
      final stackLines = stackTrace.toString().split('\n');
      for (int i = 0; i < 3 && i < stackLines.length; i++) {
        _addLog('   ${stackLines[i]}');
      }
    } finally {
      await db?.close();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste SQLite em Memória'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green[50],
            padding: const EdgeInsets.all(16),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Este teste usa banco em memória (mais simples e rápido)',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _testMemoryDatabase,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Executar Teste em Memória'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
              ),
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
                            const Text('Clique para executar teste'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          Color? color;
                          FontWeight? weight;
                          
                          if (log.contains('❌')) {
                            color = Colors.red;
                            weight = FontWeight.bold;
                          } else if (log.contains('✅')) {
                            color = Colors.green;
                          } else if (log.contains('🎉')) {
                            color = Colors.blue;
                            weight = FontWeight.bold;
                          } else if (log.contains('💡')) {
                            color = Colors.orange;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: color,
                                fontWeight: weight,
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
