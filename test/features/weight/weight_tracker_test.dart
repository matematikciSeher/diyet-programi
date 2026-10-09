import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/features/weight/domain/usecases/weight_tracker.dart';
import 'package:diyet_programi/shared/repositories/local_user_profile_repository.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_profile.dart';

void main() {
  late InMemoryDocumentDatabase db;
  late LocalUserProfileRepository profiles;
  late WeightRepositoryImpl weights;
  late WeightTracker tracker;

  setUp(() {
    db = InMemoryDocumentDatabase();
    profiles = LocalUserProfileRepository(InMemoryKeyValueStorage());
    weights = WeightRepositoryImpl(db, 'user-1');
    tracker = WeightTracker(
      weights: weights,
      profiles: profiles,
      clock: () => testNow,
    );
  });

  tearDown(() {
    db.dispose();
    profiles.dispose();
  });

  test('kilo eklenince profildeki güncel kilo güncellenir', () async {
    await profiles.saveProfile(testProfile());
    final saved = (await tracker.add(83.2, at: testNow, note: 'sabah')).valueOrNull!;
    expect(saved.weightKg, 83.2);
    expect(saved.note, 'sabah');

    final profile = (await profiles.getProfile()).valueOrNull!;
    expect(profile.weight, 83.2);
    expect(profile.startWeight, 92);
    expect(await weights.watchEntries().first, [saved]);
  });

  test('aynı kiloda bile başlangıç kilosu sabitlenir', () async {
    await profiles.saveProfile(testProfile(startWeight: null, weight: 84));
    await tracker.add(84, at: testNow);
    final profile = (await profiles.getProfile()).valueOrNull!;
    expect(profile.weight, 84);
    expect(profile.startWeight, 84);
  });

  test('kilo silinince güncel kilo bir önceki kayda döner', () async {
    await profiles.saveProfile(testProfile());
    final first = (await tracker.add(
      84,
      at: testNow.subtract(const Duration(days: 2)),
    )).valueOrNull!;
    final second = (await tracker.add(83, at: testNow)).valueOrNull!;
    expect((await profiles.getProfile()).valueOrNull!.weight, 83);

    await tracker.delete(second.id);
    expect((await profiles.getProfile()).valueOrNull!.weight, 84);
    expect(await weights.watchEntries().first, [first]);
  });
}
