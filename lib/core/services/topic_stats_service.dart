import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Агрегат статистики по конкретной теме.
class TopicStats {
  const TopicStats({
    required this.topic,
    required this.attempts,
    required this.errors,
  });

  final String topic;
  final int attempts;
  final int errors;

  double get errorRate => attempts == 0 ? 0 : errors / attempts;
}

/// Сервис накопительной статистики по темам/типам заданий.
///
/// Каждая задача в банке снабжена ярлыком темы (например, «Орфоэпия»,
/// «Производная»). После решения мы сохраняем в SharedPreferences
/// две карты: попытки и ошибки. По ним строим «Слабые темы»
/// — те, где ошибок больше всего относительно числа попыток.
class TopicStatsService extends ChangeNotifier {
  TopicStatsService._(this._prefs) {
    _load();
  }

  static const _kKey = 'topic_stats';

  final SharedPreferences _prefs;
  Map<String, int> _attempts = {};
  Map<String, int> _errors = {};

  Map<String, int> get attempts => Map.unmodifiable(_attempts);
  Map<String, int> get errors => Map.unmodifiable(_errors);

  static Future<TopicStatsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return TopicStatsService._(prefs);
  }

  void _load() {
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      final a = decoded['attempts'];
      final e = decoded['errors'];
      if (a is Map<String, dynamic>) {
        _attempts = a.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      if (e is Map<String, dynamic>) {
        _errors = e.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _kKey,
      jsonEncode({'attempts': _attempts, 'errors': _errors}),
    );
  }

  /// Зафиксировать попытку решения задачи по теме. `correct == false`
  /// добавит +1 к счётчику ошибок.
  Future<void> recordAttempt({
    required String topic,
    required bool correct,
  }) async {
    if (topic.isEmpty) return;
    _attempts[topic] = (_attempts[topic] ?? 0) + 1;
    if (!correct) {
      _errors[topic] = (_errors[topic] ?? 0) + 1;
    }
    notifyListeners();
    await _persist();
  }

  /// Топ-N слабых тем — где ошибок ≥ 1 и доля ошибок выше. При равной
  /// доле выигрывает тема с большим числом попыток.
  List<TopicStats> weakest({int limit = 3}) {
    final stats = <TopicStats>[
      for (final t in _attempts.keys)
        TopicStats(
          topic: t,
          attempts: _attempts[t] ?? 0,
          errors: _errors[t] ?? 0,
        ),
    ]..removeWhere((s) => s.errors == 0);
    stats.sort((a, b) {
      final byRate = b.errorRate.compareTo(a.errorRate);
      if (byRate != 0) return byRate;
      return b.attempts.compareTo(a.attempts);
    });
    return stats.take(limit).toList(growable: false);
  }
}
