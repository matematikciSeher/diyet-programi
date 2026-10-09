import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/weight_repository.dart';

final class WeightRepositoryImpl extends UserScopedRepository
    implements WeightRepository {
  const WeightRepositoryImpl(super.db, super.uid, {AnalyticsService? analytics})
    : _analytics = analytics;

  final AnalyticsService? _analytics;

  @override
  Stream<List<WeightEntry>> watchEntries({int? limit}) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.weightEntries(id),
          query: DocumentQuery(
            orderBy: 'recordedAt',
            descending: true,
            limit: limit,
          ),
        )
        .map(
          (docs) => docs
              .map((d) => WeightEntry.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Future<Result<WeightEntry>> addEntry({
    required double weightKg,
    DateTime? recordedAt,
    String? note,
  }) => guard(() async {
    final collection = FirestorePaths.weightEntries(requireUid());
    final entry = WeightEntry(
      id: db.generateId(collection),
      weightKg: weightKg,
      recordedAt: recordedAt ?? DateTime.now(),
      note: note,
    );
    await db.setDocument('$collection/${entry.id}', entry.toJson());
    unawaited(_analytics?.logEvent(AnalyticsEvents.weightLogged));
    return entry;
  });

  @override
  Future<Result<void>> deleteEntry(String id) => guard(
    () =>
        db.deleteDocument('${FirestorePaths.weightEntries(requireUid())}/$id'),
  );
}

final weightRepositoryProvider = Provider<WeightRepository>(
  (ref) => WeightRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);
