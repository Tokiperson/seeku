import 'package:flutter_test/flutter_test.dart';
import 'package:seeku/features/ai/data/moonshot_embedded_credential.dart';

void main() {
  test('embedded Moonshot credential decrypts to an API key shape', () {
    final apiKey = MoonshotEmbeddedCredential.resolveApiKey();

    expect(apiKey, startsWith('sk-'));
    expect(apiKey.length, greaterThan(20));
  });
}
