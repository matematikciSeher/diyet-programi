import '../../../../core/errors/result.dart';
import '../../../../shared/models/weight_entry.dart';
import '../../../../shared/repositories/user_profile_repository.dart';
import '../repositories/weight_repository.dart';

/// Kilo kayıtlarını ekler/siler ve [UserProfile.weight]'i en yeni kayıtla
/// eşitler. Günlük, İlerleme ve Kilo Takibi ekranları kiloyu yalnızca bu
/// sınıf üzerinden kaydeder; böylece dashboard, plan ve asistan her zaman
/// aynı güncel kiloyu görür.
///
/// Kalori hedefi burada otomatik değiştirilmez; yeni kiloya göre öneri
/// `ProfileTargetsService` ile hesaplanıp kullanıcı onayıyla uygulanır.
class WeightTracker {
  const WeightTracker({
    required WeightRepository weights,
    required UserProfileRepository profiles,
    required DateTime Function() clock,
  }) : _weights = weights,
       _profiles = profiles,
       _clock = clock;

  final WeightRepository _weights;
  final UserProfileRepository _profiles;
  final DateTime Function() _clock;

  Future<Result<WeightEntry>> add(
    double kg, {
    DateTime? at,
    String? note,
  }) async {
    final trimmed = note?.trim();
    final result = await _weights.addEntry(
      weightKg: kg,
      recordedAt: at ?? _clock(),
      note: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    if (result.isSuccess) await syncProfile();
    return result;
  }

  Future<Result<void>> delete(String id) async {
    final result = await _weights.deleteEntry(id);
    if (result.isSuccess) await syncProfile();
    return result;
  }

  /// Silinen kaydı aynı değerlerle geri ekler.
  Future<Result<WeightEntry>> restore(WeightEntry entry) =>
      add(entry.weightKg, at: entry.recordedAt, note: entry.note);

  /// Profildeki güncel kiloyu en yeni tarihli kayda eşitler. Başlangıç
  /// kilosu ilk güncellemede sabitlenir, sonra değişmez.
  Future<void> syncProfile() async {
    final latest = (await _weights.watchEntries(limit: 1).first).firstOrNull;
    if (latest == null) return;
    final profile = (await _profiles.getProfile()).valueOrNull;
    if (profile == null) return;
    final start = profile.startWeight ?? profile.weight ?? latest.weightKg;
    if (profile.weight == latest.weightKg && profile.startWeight == start) {
      return;
    }
    await _profiles.saveProfile(
      profile.copyWith(weight: latest.weightKg, startWeight: start),
    );
  }
}
