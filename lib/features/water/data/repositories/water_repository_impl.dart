import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/firestore_paths.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/utils/extensions/date_extensions.dart';
import '../../../../shared/models/water_log.dart';
import '../../../../shared/repositories/user_scoped_repository.dart';
import '../../../../shared/services/analytics/analytics_service.dart';
import '../../../../shared/services/database/document_database.dart';
import '../../../../shared/services/service_providers.dart';
import '../../domain/repositories/water_repository.dart';

final class WaterRepositoryImpl extends UserScopedRepository
    implements WaterRepository {
  const WaterRepositoryImpl(super.db, super.uid, {AnalyticsService? analytics})
    : _analytics = analytics;

  final AnalyticsService? _analytics;

  @override
  Stream<List<WaterLog>> watchDay(DateTime day) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.waterLogs(id),
          query: DocumentQuery(
            filters: [
              QueryFilter('dayKey', FilterOperator.isEqualTo, day.dayKey),
            ],
            orderBy: 'loggedAt',
          ),
        )
        .map(
          (docs) => docs
              .map((d) => WaterLog.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Stream<List<WaterLog>> watchRange(DateTime from, DateTime to) {
    final id = uid;
    if (id == null) return Stream.value(const []);
    return db
        .watchCollection(
          FirestorePaths.waterLogs(id),
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
              .map((d) => WaterLog.fromJson({...d.data, 'id': d.id}))
              .toList(),
        );
  }

  @override
  Future<Result<WaterLog>> addWater(int amountMl, {DateTime? at}) =>
      guard(() async {
        final collection = FirestorePaths.waterLogs(requireUid());
        final loggedAt = at ?? DateTime.now();
        final log = WaterLog(
          id: db.generateId(collection),
          dayKey: loggedAt.dayKey,
          amountMl: amountMl,
          loggedAt: loggedAt,
        );
        await db.setDocument('$collection/${log.id}', log.toJson());
        unawaited(_analytics?.logEvent(AnalyticsEvents.waterLogged));
        return log;
      });

  @override
  Future<Result<WaterLog>> updateLog(WaterLog log) => guard(() async {
    final saved = WaterLog(
      id: log.id,
      dayKey: log.loggedAt.dayKey,
      amountMl: log.amountMl,
      loggedAt: log.loggedAt,
    );
    await db.setDocument(
      '${FirestorePaths.waterLogs(requireUid())}/${log.id}',
      saved.toJson(),
    );
    return saved;
  });

  @override
  Future<Result<void>> deleteLog(String id) => guard(
    () => db.deleteDocument('${FirestorePaths.waterLogs(requireUid())}/$id'),
  );
}

final waterRepositoryProvider = Provider<WaterRepository>(
  (ref) => WaterRepositoryImpl(
    ref.watch(documentDatabaseProvider),
    ref.watch(currentUserIdProvider),
    analytics: ref.watch(analyticsServiceProvider),
  ),
);
