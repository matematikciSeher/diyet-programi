import 'assistant_guides_nutrition.dart';
import 'assistant_guides_wellness.dart';
import 'guide_copy.dart';

/// Soru kimliğine göre iki dilli rehber metni.
abstract final class AssistantGuideLibrary {
  static LocalizedGuide? of(String id) => _all[id];

  static Map<String, LocalizedGuide> get all => _all;

  static final Map<String, LocalizedGuide> _all = {
    ...nutritionGuides,
    ...wellnessGuides,
  };
}
