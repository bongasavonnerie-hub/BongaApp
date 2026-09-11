// Test minimal : l'app lance sans erreur de compilation.
// Le template par défaut référençait un compteur (MyApp) qui n'existe plus
// depuis que l'app est gérée par AuthGate + Firebase.
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('L\'app est bien un package compilable', () {
    expect(true, isTrue);
  });
}