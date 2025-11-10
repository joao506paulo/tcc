import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Configurações globais para testes.
/// Use este arquivo para registrar fallback values e configurar mocks.

class FakeParams extends Fake {}

void setupTestEnvironment() {
  setUpAll(() {
    registerFallbackValue(FakeParams());
  });

  tearDown(() {
    // Executado após cada teste
  });

  tearDownAll(() {
    // Executado após todos os testes
  });
}
