import '../models/assistant_context.dart';
import '../models/assistant_reply.dart';

/// Beslenme asistanı.
///
/// Debug/test (`useFakeServices`) kural tabanlı sahte servisi kullanır.
/// Release'te sahte yanıt üretilmez. Proxy adresi yoksa
/// `AI_SERVICE_NOT_CONFIGURED` döner. Adres varsa istek, kullanıcının kimlik
/// token'ıyla doğrulanan backend proxy'ye (`AiNutritionService`) gider;
/// sağlayıcı anahtarı uygulamada tutulmaz.
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
