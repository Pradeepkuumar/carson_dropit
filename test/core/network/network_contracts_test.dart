import 'package:carson_zyppy/core/network/api_exceptions.dart';
import 'package:carson_zyppy/core/network/api_keys.dart';
import 'package:carson_zyppy/core/network/api_urls.dart';
import 'package:carson_zyppy/core/network/base_api_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('API constants', () {
    test('keys and endpoints expose expected wire values', () {
      expect(ApiKeys().apiToken, 'api_token');
      expect(ApiKeys().userID, 'user_id');
      expect(ApiUrls().login, 'login');
      expect(ApiUrls().verifyOtp, 'driver/whatsapp/verify-otp');
    });
  });

  group('BaseApiResponse', () {
    test('round trips supported data values', () {
      final values = <dynamic>[
        <String, dynamic>{'id': 4},
        <dynamic>[1, 2],
        'message',
        null,
      ];

      for (final value in values) {
        final response = BaseApiResponse.fromJson({
          'success': true,
          'status_code': 200,
          'method': 'GET',
          'status': 'ok',
          'data': value,
          'message': 'done',
        });
        expect(response.toJson()['data'], value);
        expect(response.toJson()['success'], isTrue);
      }
    });

    test('ignores unsupported data values', () {
      final response = BaseApiResponse.fromJson({'data': 42});
      expect(response.data, isNull);
    });
  });

  group('API exceptions', () {
    test('formats each public exception with its prefix', () {
      expect(FetchDataException('offline').toString(),
          'Error During Communication: offline');
      expect(BadRequestException('invalid').toString(),
          'Invalid Request: invalid');
      expect(UnauthorizedException('denied').toString(),
          'Unauthorized Request: denied');
      expect(InvalidInputException('missing').toString(),
          'Invalid Input: missing');
    });
  });
}
