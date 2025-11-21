import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/injection/injection_container.dart' as di;
import 'features/notes/presentation/pages/home_page.dart';
import 'features/notes/data/datasources/note_local_data_source_impl.dart';
import 'features/semantic/data/datasources/semantic_local_data_source_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar SQLite FFI para desktop
  NoteLocalDataSourceImpl.initializeFfi();
  SemanticLocalDataSourceImpl.initializeFfi();
  
  // Inicializar injeção de dependências
  await di.init();
  
  print('✅ Aplicativo inicializado com sucesso!');
  
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
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
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
