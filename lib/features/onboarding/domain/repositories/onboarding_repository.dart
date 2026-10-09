import '../../../../core/errors/result.dart';
import '../models/onboarding_draft.dart';

/// Onboarding ilerlemesinin cihazdaki kaydı. Taslak her zaman yereldir;
/// tamamlanan profil `UserProfileRepository` üzerinden saklanır.
abstract interface class OnboardingRepository {
  bool get isCompleted;

  /// Kayıtlı taslak yoksa veya okunamıyorsa `null`.
  OnboardingDraft? readDraft();

  Future<Result<void>> saveDraft(OnboardingDraft draft);
  Future<Result<void>> clearDraft();
  Future<Result<void>> markCompleted();

  /// Onboarding'i baştan başlatır (taslak ve tamamlanma bayrağı silinir).
  Future<Result<void>> reset();
}
