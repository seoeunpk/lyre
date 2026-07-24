import 'package:flutter_test/flutter_test.dart';
import 'package:lyre/utils/auth_validation.dart';

void main() {
  group('validatePassword', () {
    test('rejects passwords shorter than six characters', () {
      expect(
          validatePassword('A1b2c'), 'Password must be at least 6 characters.');
    });

    test('rejects special characters', () {
      expect(validatePassword('valid!1'), 'Letters and numbers only.');
    });

    test('requires a letter', () {
      expect(validatePassword('123456'), 'Needs at least one letter.');
    });

    test('requires a number', () {
      expect(validatePassword('abcdef'), 'Needs at least one number.');
    });

    test('accepts a six-character alphanumeric password', () {
      expect(validatePassword('abc123'), isNull);
    });
  });
}
