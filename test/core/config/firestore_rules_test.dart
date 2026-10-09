import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kurallar varsayılan açık erişim içermez, sahibi zorunlu kılar', () {
    final rules = File('firestore.rules').readAsStringSync();
    expect(rules, contains('function isOwner'));
    expect(rules, contains('match /meal_plans/{document}'));
    expect(rules, contains('allow read, write: if isOwner(uid)'));
    expect(rules, contains('allow write: if false'));
    expect(rules.contains('allow read, write: if true'), isFalse);
  });
}
