import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/injection/injection_container.dart' as di;
import 'features/notes/presentation/pages/home_page.dart';
import 'features/notes/data/datasources/note_local_data_source_impl.dart';
import 'features/semantic/data/datasources/semantic_local_data_source_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔧 Inicializar SQLite FFI ANTES de tudo
  NoteLocalDataSourceImpl.initializeFfi();
  SemanticLocalDataSourceImpl.initializeFfi(); 

  // Inicializar injeção de dependências
  await di.init();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App - Web Semântica',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(  // CORRIGIDO: CardTheme -> CardThemeData
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const HomePage(),
    );
  }
}
