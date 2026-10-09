import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/shared/services/sync/user_data_hydrator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/local_first_harness.dart';

void main() {
  test('hydrate uzak koleksiyonu last-write-wins ile yerele çeker', () async {
    const uid = 'user-1';
    final h = LocalFirstHarness();
    addTearDown(h.dispose);
    await h.remote.setDocument('${FirestorePaths.waterLogs(uid)}/w1', {
      'amountMl': 400,
      'updatedAt': DateTime(2026, 9, 29).toIso8601String(),
    });
    await UserDataHydrator(
      sync: h.sync,
      local: h.local,
    ).hydrate(uid);
    final local = await h.local.getCollection(FirestorePaths.waterLogs(uid));
    expect(local.single.data['amountMl'], 400);
  });
}
