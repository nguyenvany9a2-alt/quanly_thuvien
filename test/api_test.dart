import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quanly_thuvien/core/api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Remembered session restores, then unauthorized response clears it',
    () async {
      FlutterSecureStorage.setMockInitialValues({});
      var expired = false;
      final user = {'id': 1, 'name': 'An', 'role': 'reader'};
      final client = MockClient((r) async {
        if (r.url.path == '/auth/login') {
          expect(jsonDecode(r.body)['remember'], true);
          return http.Response(
            jsonEncode({'token': 'test-token', 'user': user}),
            200,
          );
        }
        expect(
          r.headers.entries
              .where((e) => e.key.toLowerCase() == 'authorization')
              .single
              .value,
          'Bearer test-token',
        );
        return http.Response(
          jsonEncode(expired ? {'detail': 'Expired'} : user),
          expired ? 401 : 200,
        );
      });
      final api = Api(client: client);
      await api.login('an@mot.local', 'password123', true);
      expect(await api.storage.read(key: 'mot_token'), 'test-token');
      final restored = Api(client: client);
      await restored.restore();
      expect(restored.user?['id'], 1);
      expired = true;
      await expectLater(restored.call('/me'), throwsA(isA<ApiError>()));
      expect(restored.user, isNull);
      expect(await api.storage.read(key: 'mot_token'), isNull);
    },
  );
  test('Unremembered login removes old saved token', () async {
    FlutterSecureStorage.setMockInitialValues({'mot_token': 'old-token'});
    final api = Api(
      client: MockClient(
        (r) async => http.Response(
          jsonEncode({
            'token': 'new-token',
            'user': {'id': 2, 'role': 'reader'},
          }),
          200,
        ),
      ),
    );
    await api.login('a@mot.local', 'password123', false);
    expect(api.token, 'new-token');
    expect(await api.storage.read(key: 'mot_token'), isNull);
  });
}
