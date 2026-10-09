import 'dart:typed_data';

import 'package:diyet_programi/features/measurements/data/repositories/measurement_repository_impl.dart';
import 'package:diyet_programi/features/meals/data/repositories/meal_log_repository_impl.dart';
import 'package:diyet_programi/features/progress/data/repositories/progress_photo_repository_impl.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/shared/models/body_measurement.dart';
import 'package:diyet_programi/shared/models/enums.dart';
import 'package:diyet_programi/shared/models/meal_entry.dart';
import 'package:diyet_programi/shared/models/nutrition_facts.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/storage/file_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDocumentDatabase db;

  setUp(() => db = InMemoryDocumentDatabase());
  tearDown(() => db.dispose());

  test('ölçüler eskiden yeniye listelenir', () async {
    final repo = MeasurementRepositoryImpl(db, 'user-1');
    await repo.addMeasurement(
      BodyMeasurement(id: '', recordedAt: DateTime(2026, 9, 1), waistCm: 88),
    );
    await repo.addMeasurement(
      BodyMeasurement(id: '', recordedAt: DateTime(2026, 8, 1), waistCm: 91),
    );

    final list = await repo.watchMeasurements().first;
    expect(list.map((m) => m.waistCm), [91, 88]);
    expect(list.every((m) => m.id.isNotEmpty), isTrue);
  });

  test('öğün ve su kayıtları gün aralığına göre filtrelenir', () async {
    final meals = MealLogRepositoryImpl(db, 'user-1');
    final water = WaterRepositoryImpl(db, 'user-1');
    for (final day in [1, 5, 10]) {
      await meals.addEntry(
        MealEntry(
          id: '',
          dayKey: '',
          mealType: MealType.lunch,
          name: 'Yemek $day',
          quantityGrams: 100,
          nutrition: NutritionFacts.zero,
          loggedAt: DateTime(2026, 9, day, 12),
        ),
      );
      await water.addWater(250, at: DateTime(2026, 9, day, 9));
    }

    final from = DateTime(2026, 9, 5);
    final to = DateTime(2026, 9, 10, 23);
    final inRange = await meals.watchRange(from, to).first;
    expect(inRange.map((m) => m.name), ['Yemek 5', 'Yemek 10']);
    expect(await water.watchRange(from, to).first, hasLength(2));
  });

  test(
    'fotoğraf yüklenir, okunur ve silinince dosyası da kaldırılır',
    () async {
      final storage = InMemoryFileStorageService();
      final repo = ProgressPhotoRepositoryImpl(db, 'user-1', storage);
      final bytes = Uint8List.fromList(const [1, 2, 3]);

      final photo = (await repo.addPhoto(
        bytes: bytes,
        weightKg: 72,
      )).valueOrNull!;
      expect(await repo.watchPhotos().first, [photo]);
      expect((await repo.loadImage(photo)).valueOrNull, bytes);

      await repo.deletePhoto(photo);
      expect(await repo.watchPhotos().first, isEmpty);
      expect(await storage.download(photo.storagePath), isNull);
    },
  );
}
