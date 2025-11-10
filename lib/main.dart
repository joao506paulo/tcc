// lib/main.dart

import 'package:flutter/material.dart';
import 'core/injection/injection_container.dart' as di;


class MyTypeFake extends Fake implements MyType {}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Clean TDD App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Placeholder(), // Substituir pela home page
    );
  }
  
  
    setUpAll(() {
      registerFallbackValue(MyTypeFake());
    });
    
    
}
