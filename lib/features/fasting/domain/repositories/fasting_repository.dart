import '../../../../core/errors/result.dart';
import '../../../../shared/models/fasting_session.dart';

abstract interface class FastingRepository {
  /// En yeni başlayan önce.
  Stream<List<FastingSession>> watchSessions();

  /// Id boşsa yeni id üretilir.
  Future<Result<FastingSession>> saveSession(FastingSession session);

  Future<Result<void>> deleteSession(String id);
}
