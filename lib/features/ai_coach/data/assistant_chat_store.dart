import '../../../core/constants/firestore_paths.dart';
import '../../../shared/services/database/document_database.dart';
import '../domain/models/assistant_reply.dart';
import 'assistant_reply_codec.dart';

/// Yerel sohbet satırı. Firebase koleksiyon listesinde yoktur.
class AssistantTranscript {
  const AssistantTranscript.user(this.text)
    : role = 'user',
      reply = null,
      code = null,
      question = null;

  const AssistantTranscript.assistant(this.reply)
    : role = 'assistant',
      text = null,
      code = null,
      question = null;

  const AssistantTranscript.error({required this.code, required this.question})
    : role = 'error',
      text = null,
      reply = null;

  final String role;
  final String? text;
  final AssistantReply? reply;
  final String? code;
  final String? question;
}

/// Sohbeti [DocumentDatabase] üzerinde tutar.
///
/// Çağıran, senkron kuyruğuna bağlı veritabanını değil cihazdaki
/// [PersistentDocumentDatabase] örneğini vermelidir.
class AssistantChatStore {
  const AssistantChatStore(this._database);

  static const collection = FirestorePaths.assistantChatLocal;
  static const metaCollection = FirestorePaths.assistantChatMetaLocal;
  static const metaId = 'session';

  final DocumentDatabase _database;

  Future<String?> loadCategory() async {
    final doc = await _database.getDocument('$metaCollection/$metaId');
    final id = doc?.data['categoryId'];
    if (id is! String || id.isEmpty) return null;
    return id;
  }

  Future<void> saveCategory(String? categoryId) async {
    final path = '$metaCollection/$metaId';
    if (categoryId == null || categoryId.isEmpty) {
      await _database.deleteDocument(path);
      return;
    }
    await _database.setDocument(path, {'categoryId': categoryId});
  }

  Future<List<AssistantTranscript>> load() async {
    final docs = await _database.getCollection(
      collection,
      query: const DocumentQuery(orderBy: 'seq'),
    );
    final items = <AssistantTranscript>[];
    for (final doc in docs) {
      final item = _decode(doc.data);
      if (item != null) items.add(item);
    }
    return items;
  }

  Future<void> replaceAll(List<AssistantTranscript> items) async {
    final existing = await _database.getCollection(collection);
    for (final doc in existing) {
      await _database.deleteDocument('$collection/${doc.id}');
    }
    for (var index = 0; index < items.length; index++) {
      await _database.addDocument(collection, {
        ..._encode(items[index]),
        'seq': index,
      });
    }
  }

  Map<String, dynamic> _encode(AssistantTranscript item) => switch (item.role) {
    'user' => {'role': 'user', 'text': item.text ?? ''},
    'assistant' => {
      'role': 'assistant',
      'reply': item.reply == null
          ? null
          : AssistantReplyCodec.encode(item.reply!),
    },
    _ => {
      'role': 'error',
      'code': item.code ?? AssistantErrorCodes.unavailable,
      'question': item.question ?? '',
    },
  };

  AssistantTranscript? _decode(Map<String, dynamic> json) {
    return switch (json['role']) {
      'user' => AssistantTranscript.user(json['text'] as String? ?? ''),
      'assistant' when json['reply'] is Map => AssistantTranscript.assistant(
        AssistantReplyCodec.decode(
              Map<String, dynamic>.from(json['reply'] as Map),
            ) ??
            const HelpReply(),
      ),
      'error' => AssistantTranscript.error(
        code: json['code'] as String? ?? AssistantErrorCodes.unavailable,
        question: json['question'] as String? ?? '',
      ),
      _ => null,
    };
  }
}
