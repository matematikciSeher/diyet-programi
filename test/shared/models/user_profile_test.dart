import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2026, 9, 1);

  final full = UserProfile(
    id: 'u1',
    name: 'Ayşe',
    age: 30,
    gender: Gender.female,
    height: 165,
    weight: 70,
    targetWeight: 62,
    activityLevel: ActivityLevel.moderate,
    exerciseFrequency: ExerciseFrequency.threeToFour,
    goal: GoalType.loseWeight,
    dietType: DietType.vegetarian,
    allergies: const ['gluten', 'Kivi'],
    dislikedFoods: const ['Patlıcan'],
    mealsPerDay: 3,
    breakfastPreference: BreakfastPreference.always,
    waterGoal: 2500,
    fastingPreference: FastingPreference.none,
    targetDate: DateTime(2027, 1, 1),
    maintenanceCalories: 2200,
    dailyCalories: 1650,
    proteinGoal: 126,
    carbGoal: 162,
    fatGoal: 55,
    createdAt: created,
    updatedAt: created,
  );

  test('toJson / fromJson gidiş-dönüş eşittir', () {
    expect(UserProfile.fromJson(full.toJson()), full);
  });

  test('boş ve bozuk JSON güvenle okunur', () {
    final p = UserProfile.fromJson({
      'id': 'u2',
      'age': 'abc',
      'gender': 'robot',
      'height': null,
      'allergies': 'gluten',
      'mealsPerDay': 42,
      'targetDate': 'not-a-date',
      'dailyCalories': 1800.6,
    });
    expect(p.id, 'u2');
    expect(p.age, isNull);
    expect(p.gender, isNull);
    expect(p.height, isNull);
    expect(p.allergies, isEmpty);
    expect(p.mealsPerDay, isNull);
    expect(p.targetDate, isNull);
    expect(p.dailyCalories, 1801);
    expect(p.nutritionTargets, isNull);
    expect(p.bmi, isNull);
  });

  test('türetilmiş değerler', () {
    expect(full.bmi, closeTo(25.7, 0.1));
    final t = full.nutritionTargets!;
    expect(t.calories, 1650);
    expect(t.waterMl, 2500);
  });

  test('Firestore Timestamp map createdAt okunur', () {
    final stamp = DateTime.utc(2026, 9, 1, 12);
    final p = UserProfile.fromJson({
      'id': 'u3',
      'gender': 'female',
      'createdAt': {
        'seconds': stamp.millisecondsSinceEpoch ~/ 1000,
        'nanoseconds': 0,
      },
    });
    expect(p.gender, Gender.female);
    expect(p.createdAt.toUtc(), stamp);
  });
}
