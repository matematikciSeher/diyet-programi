import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/meal_entry.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/meal_log_repository.dart';

final class MealLogRepositoryImpl extends UserScopedRepository
    implements MealLogRepository {
  const MealLogRepositoryImpl(
    super.db,
    super.uid, {
    DateTime Function() clock = DateTime.now,
    AnalyticsService? analytics,
  }) : _clock = clock,
       _analytics = analytics;

  final DateTime Function() _clock;
  final AnalyticsService? _analytics;

  @override
  Stream<List<MealEntry>> watchDay(DateTime day) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.mealEntries(id),
          query: DocumentQuery(
            filters: [
              QueryFilter('dayKey', FilterOperator.isEqualTo, day.dayKey),
            ],
            orderBy: 'loggedAt',
          ),
        )
        .map(
          (docs) => docs
              .map((d) => MealEntry.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Stream<List<MealEntry>> watchRange(DateTime from, DateTime to) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.mealEntries(id),
          query: DocumentQuery(
            filters: [
              QueryFilter(
                'dayKey',
                FilterOperator.isGreaterThanOrEqualTo,
                from.dayKey,
              ),
              QueryFilter(
                'dayKey',
                FilterOperator.isLessThanOrEqualTo,
                to.dayKey,
              ),
            ],
            orderBy: 'dayKey',
          ),
        )
        .map(
          (docs) => docs
              .map((d) => MealEntry.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Future<Result<MealEntry>> addEntry(MealEntry entry) => guard(() async {
    final collection = FirestorePaths.mealEntries(requireUid());
    final saved = entry.copyWith(
      id: entry.id.isEmpty ? db.generateId(collection) : entry.id,
      dayKey: entry.loggedAt.dayKey,
    );
    await db.setDocument('$collection/${saved.id}', saved.toJson());
    unawaited(_analytics?.logEvent(AnalyticsEvents.foodAdded));
    return saved;
  });

  @override
  Future<Result<MealEntry>> updateEntry(MealEntry entry) => guard(() async {
    final path = '${FirestorePaths.mealEntries(requireUid())}/${entry.id}';
    if (await db.getDocument(path) == null) throw NotFoundException(path);
    final saved = entry.copyWith(
      dayKey: entry.loggedAt.dayKey,
      updatedAt: _clock(),
    );
    await db.setDocument(path, saved.toJson());
    return saved;
  });

  @override
  Future<Result<void>> deleteEntry(String id) => guard(
    () => db.deleteDocument('${FirestorePaths.mealEntries(requireUid())}/$id'),
  );
}

final mealLogRepositoryProvider = Provider<MealLogRepository>(
  (ref) => MealLogRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    clock: ref.watch(clockProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);
