import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const SimpleDatabaseTestApp());
}

class SimpleDatabaseTestApp extends StatelessWidget {
  const SimpleDatabaseTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Teste Simples SQLite',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SimpleDatabaseTestPage(),
    );
  }
}

class SimpleDatabaseTestPage extends StatefulWidget {
  const SimpleDatabaseTestPage({Key? key}) : super(key: key);

  @override
  State<SimpleDatabaseTestPage> createState() => _SimpleDatabaseTestPageState();
}

class _SimpleDatabaseTestPageState extends State<SimpleDatabaseTestPage> {
  final List<String> _logs = [];
  bool _isLoading = false;

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message);
  }

  Future<void> _testBasicDatabase() async {
    setState(() {
      _isLoading = true;
      _logs.clear();
    });

    Database? db;

    try {
      _addLog('🔧 Iniciando teste básico do SQLite...');

      // 1. Criar banco de dados
      _addLog('📂 Obtendo diretório...');
      final directory = await getApplicationDocumentsDirectory();
      final path = join(directory.path, 'test_db.db');
      _addLog('📍 Caminho: $path');

      // 2. Abrir/Criar banco
      _addLog('🗄️ Abrindo banco de dados...');
      db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          _addLog('🏗️ Criando tabela...');
          await db.execute('''
            CREATE TABLE test_table (
              id TEXT PRIMARY KEY,
              content TEXT NOT NULL,
              created_at TEXT NOT NULL
            )
          ''');
          _addLog('✅ Tabela criada!');
        },
      );
      _addLog('✅ Banco aberto com sucesso!');

      // 3. Inserir dados
      _addLog('📝 Inserindo registro...');
      final now = DateTime.now().toIso8601String();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      await db.insert(
        'test_table',
        {
          'id': id,
          'content': 'Teste de conteúdo',
          'created_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      _addLog('✅ Registro inserido! ID: $id');

      // 4. Ler dados
      _addLog('📖 Lendo registros...');
      final List<Map<String, dynamic>> results = await db.query('test_table');
      _addLog('✅ Encontrados ${results.length} registro(s)');
      
      for (var row in results) {
        _addLog('   ID: ${row['id']}');
        _addLog('   Content: ${row['content']}');
      }

      // 5. Atualizar
      _addLog('🔄 Atualizando registro...');
      await db.update(
        'test_table',
        {'content': 'Conteúdo atualizado'},
        where: 'id = ?',
        whereArgs: [id],
      );
      _addLog('✅ Registro atualizado!');

      // 6. Verificar atualização
      final updated = await db.query('test_table', where: 'id = ?', whereArgs: [id]);
      _addLog('📖 Conteúdo após update: ${updated.first['content']}');

      // 7. Deletar
      _addLog('🗑️ Deletando registro...');
      await db.delete('test_table', where: 'id = ?', whereArgs: [id]);
      _addLog('✅ Registro deletado!');

      // 8. Verificar deleção
      final remaining = await db.query('test_table');
      _addLog('📊 Registros restantes: ${remaining.length}');

      _addLog('');
      _addLog('🎉 TESTE BÁSICO PASSOU!');
      _addLog('✅ SQLite está funcionando corretamente');

    } catch (e, stackTrace) {
      _addLog('❌ ERRO: $e');
      _addLog('Stack: ${stackTrace.toString().substring(0, 200)}...');
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
        title: const Text('Teste Simples SQLite'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _testBasicDatabase,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Executar Teste Básico'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? const Center(
                        child: Text('Clique para executar teste'),
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
