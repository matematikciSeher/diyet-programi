import 'package:diyet_programi/core/errors/failures.dart';
import 'package:diyet_programi/features/weight/data/repositories/weight_repository_impl.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryDocumentDatabase db;

  setUp(() => db = InMemoryDocumentDatabase());
  tearDown(() => db.dispose());

  test('kayıtlar en yeniden eskiye listelenir', () async {
    final repo = WeightRepositoryImpl(db, 'user-1');
    await repo.addEntry(weightKg: 80, recordedAt: DateTime(2026, 1, 1));
    await repo.addEntry(weightKg: 78.5, recordedAt: DateTime(2026, 2, 1));

    final entries = await repo.watchEntries().first;
    expect(entries.map((e) => e.weightKg), [78.5, 80]);
  });

  test('oturum yoksa AuthFailure döner', () async {
    final repo = WeightRepositoryImpl(db, null);
    final result = await repo.addEntry(weightKg: 70);
    expect(result.failureOrNull, isA<AuthFailure>());
  });
}
