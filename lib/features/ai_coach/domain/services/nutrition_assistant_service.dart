import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';

/// Beslenme asistanı.
///
/// İlk sürüm, kayıtlı uygulama verisine bakan yerel kural servisini kullanır.
/// Proxy adresi tanımlı değilse tahmin veya sahte övgü üretilmez; yanıt
/// kayıtlardan gelir. Adres varsa ve sahte servisler kapalıysa istek,
/// kullanıcının kimlik token'ıyla doğrulanan backend proxy'ye
/// (`AiNutritionService`) gider; sağlayıcı anahtarı uygulamada tutulmaz.
///
/// Her implementasyon güvenlik kurallarına uymalıdır: tıbbi teşhis
/// koymaz, ilaç/doktor önerisinin yerine geçmez, aşırı kısıtlamayı veya
/// yeme bozukluğu davranışlarını teşvik etmez ve gerektiğinde bir sağlık
/// profesyoneline yönlendirir.
abstract interface class NutritionAssistantService {
  Future<AssistantReply> reply(String question, AssistantContext context);
}

/// Kullanıcı verisini tek bir anlık görüntüde toplar.
abstract interface class AssistantContextRepository {
  Future<AssistantContext> snapshot();
}
