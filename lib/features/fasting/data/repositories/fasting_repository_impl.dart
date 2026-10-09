import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/fasting_session.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/fasting_repository.dart';

final class FastingRepositoryImpl extends UserScopedRepository
    implements FastingRepository {
  const FastingRepositoryImpl(super.db, super.uid);

  @override
  Stream<List<FastingSession>> watchSessions() {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.fastingSessions(id),
          query: const DocumentQuery(orderBy: 'startedAt', descending: true),
        )
        .map(
          (docs) => [
            for (final d in docs)
              FastingSession.fromJson({...d.data, 'id': d.id}),
          ],
        );
  }

  @override
  Future<Result<FastingSession>> saveSession(FastingSession session) =>
      guard(() async {
        final collection = FirestorePaths.fastingSessions(requireUid());
        final saved = session.id.isEmpty
            ? session.copyWith(id: db.generateId(collection))
            : session;
        await db.setDocument('$collection/${saved.id}', saved.toJson());
        return saved;
      });

  @override
  Future<Result<void>> deleteSession(String id) => guard(
    () => db.deleteDocument(
      '${FirestorePaths.fastingSessions(requireUid())}/$id',
    ),
  );
}

final fastingRepositoryProvider = Provider<FastingRepository>(
  (ref) => FastingRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
  ),
);
