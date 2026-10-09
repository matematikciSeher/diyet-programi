import 'dart:convert';

import '../models/assistant_reply.dart';

class ParsedAssistantResponse {
  const ParsedAssistantResponse({
    required this.text,
    required this.actions,
  });

  final String text;
  final List<ParsedAssistantAction> actions;
}

class ParsedAssistantAction {
  const ParsedAssistantAction({required this.type, this.recipeId});

  final String type;
  final String? recipeId;
}

enum AssistantParseProblem { empty, malformed, invalid }

class AssistantParseException implements Exception {
  const AssistantParseException(this.problem);

  final AssistantParseProblem problem;
}

abstract final class AssistantResponseParser {
  static ParsedAssistantResponse parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const AssistantParseException(AssistantParseProblem.empty);
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(_stripFence(trimmed));
    } on FormatException {
      throw const AssistantParseException(AssistantParseProblem.malformed);
    }
    if (decoded is! Map) {
      throw const AssistantParseException(AssistantParseProblem.malformed);
    }
    final text = decoded['text'];
    if (text != null && text is! String) {
      throw const AssistantParseException(AssistantParseProblem.invalid);
    }
    final actionsRaw = decoded['actions'];
    if (actionsRaw != null && actionsRaw is! List) {
      throw const AssistantParseException(AssistantParseProblem.invalid);
    }
    final actions = <ParsedAssistantAction>[];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is! Map) {
          throw const AssistantParseException(AssistantParseProblem.invalid);
        }
        final type = item['type'];
        if (type is! String || type.trim().isEmpty) {
          throw const AssistantParseException(AssistantParseProblem.invalid);
        }
        final recipeId = item['recipeId'];
        if (recipeId != null && recipeId is! String) {
          throw const AssistantParseException(AssistantParseProblem.invalid);
        }
        actions.add(
          ParsedAssistantAction(
            type: type.trim(),
            recipeId: recipeId is String ? recipeId.trim() : null,
          ),
        );
      }
    }
    return ParsedAssistantResponse(text: (text as String?)?.trim() ?? '', actions: actions);
  }

  static String failureCode(AssistantParseProblem problem) => switch (problem) {
    AssistantParseProblem.empty => AssistantErrorCodes.emptyResponse,
    AssistantParseProblem.malformed => AssistantErrorCodes.malformed,
    AssistantParseProblem.invalid => AssistantErrorCodes.invalidResponse,
  };

  static String _stripFence(String raw) {
    var text = raw.trim();
    if (!text.startsWith('```')) return text;
    final newline = text.indexOf('\n');
    if (newline != -1) text = text.substring(newline + 1);
    if (text.endsWith('```')) {
      text = text.substring(0, text.length - 3);
    }
    return text.trim();
  }
}
