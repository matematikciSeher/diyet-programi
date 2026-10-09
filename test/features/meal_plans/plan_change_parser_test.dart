import 'package:diyet_programi/features/meal_plans/domain/models/plan_ingredient.dart';
import 'package:diyet_programi/features/meal_plans/domain/services/plan_change_parser.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = PlanChangeParser();

  group('sevilmeyen / istenmeyen', () {
    final cases = {
      'Tavuğu sevmiyorum': {PlanIngredient.chicken},
      'TAVUĞU SEVMİYORUM': {PlanIngredient.chicken},
      'tavugu sevmiyorum': {PlanIngredient.chicken},
      "Tavuk'u hiç yemem": {PlanIngredient.chicken},
      'Balığa alerjim var': {PlanIngredient.fish},
      'Glutensiz olsun': {PlanIngredient.gluten},
      'Et yemiyorum': {PlanIngredient.redMeat},
      'Beyaz et istemiyorum': {PlanIngredient.chicken},
      'Süt ürünleri dokunuyor': PlanIngredient.dairy,
      'Mercimek köftesini beğenmedim': {
        PlanIngredient.legumes,
        PlanIngredient.gluten,
      },
      "I don't like chicken": {PlanIngredient.chicken},
      'No nuts please': {PlanIngredient.nuts},
    };
    for (final MapEntry(key: text, value: expected) in cases.entries) {
      test(text, () {
        final request = parser.parse(text);
        expect(request.excluded, expected);
        expect(request.preferred, isEmpty);
        expect(request.regenerateAll, isFalse);
      });
    }
  });

  test('öğüne özel kısıt', () {
    final request = parser.parse('Kahvaltıda yumurta olmasın');
    expect(request.excluded, {PlanIngredient.egg});
    expect(request.mealTypes, {MealType.breakfast});
  });

  test('istenen bileşen', () {
    final request = parser.parse('Akşam balık olsun');
    expect(request.preferred, {PlanIngredient.fish});
    expect(request.excluded, isEmpty);
    expect(request.mealTypes, {MealType.dinner});
  });

  test('öğün değiştirme', () {
    final request = parser.parse('Akşam yemeğini değiştir');
    expect(request.mealTypes, {MealType.dinner});
    expect(request.excluded, isEmpty);
    expect(request.regenerateAll, isFalse);
  });

  test('"yemek" kelimesi olumsuz sayılmaz, "nohut" "no" ile karışmaz', () {
    expect(parser.parse('Öğle yemeğine nohut ekle').preferred, {
      PlanIngredient.legumes,
    });
  });

  test('tüm planı değiştir', () {
    expect(parser.parse('Bu planı değiştir').regenerateAll, isTrue);
    expect(parser.parse('Hepsini yenile').regenerateAll, isTrue);
  });

  test('diyet tipi', () {
    expect(parser.parse('Vejetaryen olsun').diet, DietType.vegetarian);
    expect(parser.parse('Vegan besleniyorum').diet, DietType.vegan);
  });

  test('anlaşılmayan metin boş istek döner', () {
    expect(parser.parse('Merhaba nasılsın').isEmpty, isTrue);
  });

  test('profil metinleri bileşenlere çevrilir', () {
    expect(PlanChangeParser.ingredientsIn('mantar'), {PlanIngredient.mushroom});
    expect(PlanChangeParser.ingredientsIn('kırmızı et'), {
      PlanIngredient.redMeat,
    });
    expect(PlanChangeParser.ingredientsIn('bamya'), isEmpty);
  });
}
