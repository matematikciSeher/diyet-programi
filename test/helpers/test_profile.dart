import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/user_profile.dart';

final testNow = DateTime(2026, 9, 28, 14, 30);

UserProfile testProfile({
  String id = 'user-1',
  DateTime? now,
  GoalType goal = GoalType.loseWeight,
  DietType dietType = DietType.omnivore,
  List<String> allergies = const [],
  List<String> dislikedFoods = const [],
  int mealsPerDay = 4,
  FastingPreference fasting = FastingPreference.none,
  int dailyCalories = 1850,
  double? weight = 84,
  double? startWeight = 92,
  double? targetWeight = 75,
}) {
  final at = now ?? testNow;
  return UserProfile(
    id: id,
    createdAt: at,
    updatedAt: at,
    name: 'Seher',
    age: 30,
    gender: Gender.female,
    height: 165,
    weight: weight,
    startWeight: startWeight,
    targetWeight: targetWeight,
    activityLevel: ActivityLevel.light,
    goal: goal,
    dietType: dietType,
    allergies: allergies,
    dislikedFoods: dislikedFoods,
    mealsPerDay: mealsPerDay,
    breakfastPreference: BreakfastPreference.always,
    waterGoal: 2500,
    fastingPreference: fasting,
    eatingWindowStartMinutes: 12 * 60,
    dailyCalories: dailyCalories,
    proteinGoal: 120,
    carbGoal: 200,
    fatGoal: 60,
  );
}
