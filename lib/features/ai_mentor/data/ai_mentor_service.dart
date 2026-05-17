import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Сообщение в чате AI-ментора.
class AiMessage {
  const AiMessage({required this.role, required this.content});

  /// `user` или `assistant`.
  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Контекст задачи, передаваемый AI-ментору как часть system prompt.
class AiTaskContext {
  const AiTaskContext({
    required this.subjectTitle,
    required this.taskSource,
    required this.taskPrompt,
    required this.correctAnswer,
    this.userAnswer,
  });

  final String subjectTitle;
  final String taskSource;
  final String taskPrompt;
  final String correctAnswer;
  final String? userAnswer;
}

/// Клиент OpenRouter Chat Completions API. Использует бесплатную
/// быструю модель Google Gemini Flash. Намеренно не стримим, чтобы
/// упростить интеграцию — ответ возвращается целиком, а анимацию
/// «печатания» рисует UI.
class AiMentorService {
  AiMentorService({http.Client? client}) : _client = client ?? http.Client();

  static const _endpoint = 'https://openrouter.ai/api/v1/chat/completions';
  static String get _apiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  // `openrouter/free` — авто-роутер OpenRouter, сам выбирает доступную
  // бесплатную модель. Так не зависим от устаревания конкретных моделей.
  static const _model = 'openrouter/free';

  final http.Client _client;

  /// Запрос к модели: даём системный промпт с контекстом задачи и
  /// историю диалога. Возвращаем текст ответа модели.
  Future<String> ask({
    required AiTaskContext task,
    required List<AiMessage> history,
  }) async {
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': _buildSystemPrompt(task)},
      for (final m in history) m.toJson(),
    ];

    final res = await _client
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://ege-box.app',
            'X-Title': 'Ege Box',
          },
          body: jsonEncode({
            'model': _model,
            'messages': messages,
            'temperature': 0.4,
            'max_tokens': 800,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      String detail = '';
      try {
        final err = jsonDecode(utf8.decode(res.bodyBytes));
        detail = (err is Map && err['error'] is Map)
            ? (err['error']['message']?.toString() ?? '')
            : '';
      } catch (_) {}
      throw AiMentorException(
        detail.isEmpty
            ? 'Не удалось получить ответ (код ${res.statusCode}).'
            : 'OpenRouter: $detail',
      );
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const AiMentorException('Пустой ответ модели.');
    }
    final content =
        (choices.first as Map<String, dynamic>)['message']?['content']
            as String?;
    if (content == null || content.trim().isEmpty) {
      throw const AiMentorException('Модель не вернула текст.');
    }
    return content.trim();
  }

  String _buildSystemPrompt(AiTaskContext task) {
    return '''
Ты — AI-ментор по подготовке к ЕГЭ. Помогаешь школьнику разобраться с задачей.

Правила:
1. Объясняй шаг за шагом, на русском, простыми словами.
2. Не вываливай готовый ответ сразу — сначала идея и метод решения.
3. Если ученик прямо просит «дай ответ» — можешь дать, но всё равно с разбором.
4. Если ученик уже дал свой ответ — сравни с правильным и объясни ошибку, если она есть.
5. Используй короткие абзацы, можно нумерованные списки. Никаких лишних вступлений вроде «Конечно!», «Отличный вопрос!».

Контекст задачи:
- Предмет: ${task.subjectTitle}
- Источник: ${task.taskSource}
- Условие: ${task.taskPrompt}
- Правильный ответ: ${task.correctAnswer}
${task.userAnswer != null && task.userAnswer!.trim().isNotEmpty ? '- Ответ ученика: ${task.userAnswer}' : '- Ученик ответ ещё не вводил.'}
''';
  }

  void dispose() => _client.close();
}

class AiMentorException implements Exception {
  const AiMentorException(this.message);
  final String message;

  @override
  String toString() => message;
}
