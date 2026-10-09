import 'dart:convert';

import '../models/vision_food_candidate.dart';
import 'food_capture_codes.dart';

/// `POST /v1/food/vision` gövdesini aday listesine çevirir.
///
/// Kalori, protein, karbonhidrat ve yağ alanları okunmaz. AI besin değeri
/// otorite değildir.
List<VisionFoodCandidate> parseVisionPayload(
  Object? data, {
  int maxChars = 65536,
  int maxItems = 12,
}) {
  if (data is String) {
    if (data.length > maxChars) {
      throw foodCaptureException(FoodCaptureCodes.malformed);
    }
    Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException {
      throw foodCaptureException(FoodCaptureCodes.malformed);
    }
    return parseVisionPayload(decoded, maxChars: maxChars, maxItems: maxItems);
  }
  if (data is! Map) {
    throw foodCaptureException(FoodCaptureCodes.malformed);
  }
  final encoded = jsonEncode(data);
  if (encoded.length > maxChars) {
    throw foodCaptureException(FoodCaptureCodes.malformed);
  }
  final rawItems = data['items'];
  if (rawItems is! List) {
    throw foodCaptureException(FoodCaptureCodes.malformed);
  }
  if (rawItems.isEmpty) {
    throw foodCaptureException(FoodCaptureCodes.emptyResponse);
  }
  final items = <VisionFoodCandidate>[];
  for (final raw in rawItems.take(maxItems)) {
    if (raw is! Map) {
      throw foodCaptureException(FoodCaptureCodes.malformed);
    }
    final name = raw['name'];
    if (name is! String || name.trim().isEmpty) {
      throw foodCaptureException(FoodCaptureCodes.invalidResponse);
    }
    final id = raw['foodId'];
    if (id != null && id is! String) {
      throw foodCaptureException(FoodCaptureCodes.malformed);
    }
    items.add(
      VisionFoodCandidate(
        name: name.trim(),
        foodId: id is String && id.trim().isNotEmpty ? id.trim() : null,
        confidence: _confidence(raw['confidence']),
        estimatedGrams: _grams(raw['estimatedGrams']),
        source: raw['source'] is String && (raw['source'] as String).isNotEmpty
            ? raw['source'] as String
            : 'vision',
      ),
    );
  }
  if (items.isEmpty) {
    throw foodCaptureException(FoodCaptureCodes.emptyResponse);
  }
  return items;
}

double _confidence(Object? value) {
  if (value == null) return 0;
  if (value is! num) {
    throw foodCaptureException(FoodCaptureCodes.malformed);
  }
  final number = value.toDouble();
  if (number.isNaN) return 0;
  if (number < 0) return 0;
  if (number > 1) return 1;
  return number;
}

double? _grams(Object? value) {
  if (value == null) return null;
  if (value is! num) {
    throw foodCaptureException(FoodCaptureCodes.malformed);
  }
  final grams = value.toDouble();
  if (grams <= 0 || grams.isNaN) return null;
  return grams;
}
