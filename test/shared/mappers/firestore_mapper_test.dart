import 'package:diyet_programi/shared/mappers/firestore_mapper.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime.utc(2026, 9, 1, 10, 30);

  test('ISO tarih encode/decode gidiş-dönüş', () {
    final encoded = FirestoreMapper.encode({
      'createdAt': created.toIso8601String(),
      'name': 'Ayşe',
    });
    expect(encoded['createdAt'], isA<DateTime>());
    final decoded = FirestoreMapper.decode(encoded);
    expect(decoded['createdAt'], created.toIso8601String());
    expect(decoded['name'], 'Ayşe');
  });

  test('Timestamp benzeri map DateTime ISO olur', () {
    final decoded = FirestoreMapper.decode({
      'updatedAt': {
        'seconds': created.millisecondsSinceEpoch ~/ 1000,
        'nanoseconds': 0,
      },
    });
    expect(DateTime.parse(decoded['updatedAt']! as String).toUtc(), created);
  });

  test('last-write-wins daha yeni updatedAt seçer', () {
    final older = {
      'value': 1,
      'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
    };
    final newer = {
      'value': 2,
      'updatedAt': DateTime(2026, 2, 1).toIso8601String(),
    };
    expect(LastWriteWins.resolve(older, newer)['value'], 2);
    expect(LastWriteWins.resolve(newer, older)['value'], 2);
  });

  test('UserProfile Timestamp map ile okunur, enum korunur', () {
    final profile = UserProfile.fromJson({
      'id': 'u1',
      'gender': 'female',
      'goal': 'loseWeight',
      'dietType': 'omnivore',
      'createdAt': {
        'seconds': created.millisecondsSinceEpoch ~/ 1000,
        'nanoseconds': 0,
      },
      'updatedAt': created.toIso8601String(),
    });
    expect(profile.gender, Gender.female);
    expect(profile.goal, GoalType.loseWeight);
    expect(profile.createdAt.toUtc(), created);
  });
}
