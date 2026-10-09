import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/features/water/data/repositories/water_repository_impl.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/local_first_harness.dart';

void main() {
  const uid = 'user-1';
  final day = DateTime(2026, 9, 29);

  test('Firebase yokken kilo ve su yerelde kullanılabilir', () async {
    final h = LocalFirstHarness(failRemote: true);
    addTearDown(h.dispose);
    final water = WaterRepositoryImpl(h.db, uid);
    final weights = WeightRepositoryImpl(h.db, uid);

    expect((await water.addWater(100, at: day)).isSuccess, isTrue);
    expect(
      (await weights.addEntry(weightKg: 80, recordedAt: day)).isSuccess,
      isTrue,
    );

    expect((await water.watchDay(day).first).single.amountMl, 100);
    expect((await weights.watchEntries().first).single.weightKg, 80);
    expect(
      await h.remote.getCollection(FirestorePaths.waterLogs(uid)),
      isEmpty,
    );
  });
}
