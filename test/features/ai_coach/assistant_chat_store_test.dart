import 'dart:async';

import 'package:diyet_programi/core/constants/firestore_paths.dart';
import 'package:diyet_programi/features/ai_coach/data/assistant_chat_store.dart';
import 'package:diyet_programi/features/ai_coach/data/repositories/assistant_context_repository_impl.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_context.dart';
import 'package:diyet_programi/features/ai_coach/domain/models/assistant_reply.dart';
import 'package:diyet_programi/features/ai_coach/domain/services/nutrition_assistant_service.dart';
import 'package:diyet_programi/features/ai_coach/presentation/providers/assistant_providers.dart';
import 'package:diyet_programi/shared/models/nutrition_targets.dart';
import 'package:diyet_programi/shared/services/database/in_memory_document_database.dart';
import 'package:diyet_programi/shared/services/database/persistent_document_database.dart';
import 'package:diyet_programi/shared/services/local_storage/in_memory_key_value_storage.dart';
import 'package:diyet_programi/shared/services/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/subscription_overrides.dart';
import '../../helpers/test_profile.dart';

void main() {
  test('sohbet geçmişi yeniden açılınca durur ve temizlenir', () async {
    final storage = InMemoryKeyValueStorage();
    final db = PersistentDocumentDatabase.load(storage);
    final store = AssistantChatStore(db);
    await store.replaceAll(const [
      AssistantTranscript.user('Bugün nasıl besleniyorum?'),
      AssistantTranscript.error(
        code: AssistantErrorCodes.offline,
        question: 'Bugün nasıl besleniyorum?',
      ),
    ]);
    await db.flush();

    final restored = await AssistantChatStore(
      PersistentDocumentDatabase.load(storage),
    ).load();
    expect(restored, hasLength(2));
    expect(restored.first.text, 'Bugün nasıl besleniyorum?');
    expect(restored.last.code, AssistantErrorCodes.offline);

    await store.replaceAll(const []);
    await db.flush();
    final cleared = await AssistantChatStore(
      PersistentDocumentDatabase.load(storage),
    ).load();
    expect(cleared, isEmpty);
    await db.dispose();
  });

  test('sohbet koleksiyonu Firebase kullanıcı yollarında yoktur', () async {
    final db = InMemoryDocumentDatabase();
    addTearDown(db.dispose);
    await AssistantChatStore(
      db,
    ).replaceAll(const [AssistantTranscript.user('Su hedefime ulaştım mı?')]);
    expect(db.snapshot().keys, [AssistantChatStore.collection]);
    expect(
      FirestorePaths.userCollectionPaths(
        'user-1',
      ).any((path) => path.contains(AssistantChatStore.collection)),
      isFalse,
    );
  });

  test(
    'boş mesaj ve çift dokunuş istek üretmez, çevrimdışı geçmiş kalır',
    () async {
      final db = InMemoryDocumentDatabase();
      final ai = _HoldAssistant();
      final container = ProviderContainer(
        overrides: [
          premiumOverride,
          localDocumentDatabaseProvider.overrideWithValue(db),
          nutritionAssistantServiceProvider.overrideWithValue(ai),
          assistantContextRepositoryProvider.overrideWithValue(_FixedContext()),
        ],
      );
      addTearDown(() {
        container.dispose();
        db.dispose();
      });
      container.listen(subscriptionStatusProvider, (_, _) {});
      await container.read(subscriptionStatusProvider.future);
      final notifier = container.read(assistantChatProvider.notifier);
      await notifier.ready;
      await notifier.send('   ');
      expect(container.read(assistantChatProvider).messages, isEmpty);
      expect(ai.calls, 0);

      final first = notifier.send('Bugün nasıl besleniyorum?');
      for (var i = 0; i < 50 && ai.calls == 0; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(container.read(assistantChatProvider).busy, isTrue);
      await notifier.send('ikinci');
      expect(ai.calls, 1);
      ai.release();
      await first;

      await notifier.clear();
      expect(container.read(assistantChatProvider).messages, isEmpty);
      expect(await AssistantChatStore(db).load(), isEmpty);
    },
  );

  test('çevrimdışı hata geçmişi uygulama yeniden açılınca durur', () async {
    final db = InMemoryDocumentDatabase();
    final container = ProviderContainer(
      overrides: [
        premiumOverride,
        localDocumentDatabaseProvider.overrideWithValue(db),
        nutritionAssistantServiceProvider.overrideWithValue(
          const _FixedReplyAssistant(
            AssistantFailureReply(
              code: AssistantErrorCodes.offline,
              question: 'Su hedefime ulaştım mı?',
            ),
          ),
        ),
        assistantContextRepositoryProvider.overrideWithValue(_FixedContext()),
      ],
    );
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(subscriptionStatusProvider.future);
    final notifier = container.read(assistantChatProvider.notifier);
    await notifier.ready;
    await notifier.send('Su hedefime ulaştım mı?');
    container.dispose();

    final reopened = ProviderContainer(
      overrides: [
        premiumOverride,
        localDocumentDatabaseProvider.overrideWithValue(db),
        nutritionAssistantServiceProvider.overrideWithValue(
          const _FixedReplyAssistant(HelpReply()),
        ),
        assistantContextRepositoryProvider.overrideWithValue(_FixedContext()),
      ],
    );
    addTearDown(() {
      reopened.dispose();
      db.dispose();
    });
    await reopened.read(assistantChatProvider.notifier).ready;
    final messages = reopened.read(assistantChatProvider).messages;
    expect(messages, hasLength(2));
    expect(messages.first, isA<AssistantUserMessage>());
    final failure =
        (messages.last as AssistantBotMessage).reply as AssistantFailureReply;
    expect(failure.code, AssistantErrorCodes.offline);
  });

  test('premium olmayan kullanıcının sorusu asistanı çağırmaz', () async {
    final db = InMemoryDocumentDatabase();
    final ai = _HoldAssistant();
    final container = ProviderContainer(
      overrides: [
        localDocumentDatabaseProvider.overrideWithValue(db),
        nutritionAssistantServiceProvider.overrideWithValue(ai),
        assistantContextRepositoryProvider.overrideWithValue(_FixedContext()),
      ],
    );
    addTearDown(() {
      container.dispose();
      db.dispose();
    });
    container.listen(subscriptionStatusProvider, (_, _) {});
    await container.read(subscriptionStatusProvider.future);
    final notifier = container.read(assistantChatProvider.notifier);
    await notifier.ready;
    await notifier.send('Bugün ne yemeliyim?');
    expect(ai.calls, 0);
    expect(container.read(assistantChatProvider).messages, isEmpty);
    expect(await AssistantChatStore(db).load(), isEmpty);
  });
}

class _FixedContext implements AssistantContextRepository {
  @override
  Future<AssistantContext> snapshot() async => AssistantContext(
    now: testNow,
    targets: const NutritionTargets(
      calories: 1850,
      proteinG: 120,
      carbsG: 200,
      fatG: 60,
    ),
  );
}

class _HoldAssistant implements NutritionAssistantService {
  int calls = 0;
  final _gate = Completer<void>();

  void release() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<AssistantReply> reply(
    String question,
    AssistantContext context,
  ) async {
    calls++;
    await _gate.future;
    return const HelpReply();
  }
}

class _FixedReplyAssistant implements NutritionAssistantService {
  const _FixedReplyAssistant(this.response);

  final AssistantReply response;

  @override
  Future<AssistantReply> reply(
    String question,
    AssistantContext context,
  ) async => response;
}
