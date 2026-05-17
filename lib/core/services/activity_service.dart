import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сервис учёта дневной активности пользователя для UI «лента
/// активности» (как у GitHub) и стрика.
///
/// Хранит `Map<dateKey, count>` в SharedPreferences под ключом
/// `activity.log`, где `dateKey` — `YYYY-MM-DD` (локальное время).
/// Каждое сохранение ответа / завершение пробника инкрементирует
/// счётчик сегодняшнего дня.
class ActivityService extends ChangeNotifier {
  ActivityService._(this._prefs) {
    _load();
  }

  static const _kKey = 'activity.log';

  final SharedPreferences _prefs;
  Map<String, int> _log = {};

  static Future<ActivityService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ActivityService._(prefs);
  }

  void _load() {
    final raw = _prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      _log = decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(_kKey, jsonEncode(_log));
  }

  /// Зафиксировать активность за сегодня. Безопасно вызывать многократно.
  Future<void> logActivity({int amount = 1}) async {
    final key = _dateKey(DateTime.now());
    _log[key] = (_log[key] ?? 0) + amount;
    notifyListeners();
    await _persist();
  }

  /// Уровень активности 0..4 за указанную дату (для квадратиков heatmap).
  int levelForDate(DateTime date) {
    final c = _log[_dateKey(date)] ?? 0;
    if (c == 0) return 0;
    if (c < 2) return 1;
    if (c < 4) return 2;
    if (c < 7) return 3;
    return 4;
  }

  /// Количество активных дней (count > 0) на этой неделе (Пн–Вс).
  int daysActiveThisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    var n = 0;
    for (var i = 0; i < 7; i++) {
      if ((_log[_dateKey(monday.add(Duration(days: i)))] ?? 0) > 0) n++;
    }
    return n;
  }

  /// Текущий стрик: количество подряд идущих дней с активностью,
  /// включая сегодня (если сегодня нет — считаем с вчерашнего).
  int currentStreak() {
    var date = DateTime.now();
    if ((_log[_dateKey(date)] ?? 0) == 0) {
      date = date.subtract(const Duration(days: 1));
      if ((_log[_dateKey(date)] ?? 0) == 0) return 0;
    }
    var streak = 0;
    while ((_log[_dateKey(date)] ?? 0) > 0) {
      streak++;
      date = date.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _dateKey(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
