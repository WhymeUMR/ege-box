import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Простая локальная авторизация поверх SharedPreferences.
///
/// Хранит:
/// - `auth.users` — JSON-массив зарегистрированных пользователей
///   ({email, name, salt, hash}).
/// - `auth.token` — текущий токен сессии.
/// - `auth.current_email` — email авторизованного пользователя.
class AuthService extends ChangeNotifier {
  AuthService._(this._prefs) {
    _restore();
  }

  static const _kUsers = 'auth.users';
  static const _kToken = 'auth.token';
  static const _kCurrentEmail = 'auth.current_email';
  static const _kProgress = 'auth.progress';

  /// Жёсткие лимиты длины — используются и в UI (input formatters),
  /// и в серверной валидации.
  static const nameMaxLength = 30;
  static const passwordMaxLength = 64;

  /// Признак завершённого онбординга (выбран класс и т.д.) — пока хватает
  /// просто факта наличия `grade` у пользователя.
  bool get isOnboarded =>
      _currentUser?.grade != null &&
      (_currentUser?.subjects.isNotEmpty ?? false) &&
      _currentUser?.weeklyHours != null;

  final SharedPreferences _prefs;

  String? _token;
  AuthUser? _currentUser;
  String? _lastRoute;
  MockExamDraft? _mockExamDraft;

  bool get isAuthenticated => _token != null && _currentUser != null;
  String? get token => _token;
  AuthUser? get currentUser => _currentUser;
  String? get lastRoute => _lastRoute;
  MockExamDraft? get mockExamDraft => _mockExamDraft;

  static Future<AuthService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AuthService._(prefs);
  }

  void _restore() {
    final token = _prefs.getString(_kToken);
    final email = _prefs.getString(_kCurrentEmail);
    if (token == null || email == null) return;
    final user = _findUser(email);
    if (user == null) return;
    _token = token;
    _currentUser = user;
    _loadProgress(email);
  }

  void _loadProgress(String email) {
    final raw = _prefs.getString(_kProgress);
    if (raw == null || raw.isEmpty) return;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final entry = json[email];
    if (entry is! Map<String, dynamic>) return;
    _lastRoute = entry['lastRoute'] as String?;
    final draftJson = entry['mockExamDraft'];
    if (draftJson is Map<String, dynamic>) {
      _mockExamDraft = MockExamDraft.fromJson(draftJson);
    }
  }

  Future<void> _persistProgress() async {
    final email = _currentUser?.email;
    if (email == null) return;
    final raw = _prefs.getString(_kProgress);
    final root = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
    root[email] = {
      'lastRoute': _lastRoute,
      'mockExamDraft': _mockExamDraft?.toJson(),
    };
    await _prefs.setString(_kProgress, jsonEncode(root));
  }

  Future<void> setLastRoute(String routeName) async {
    if (_currentUser == null) return;
    _lastRoute = routeName;
    await _persistProgress();
  }

  Future<void> saveMockExamDraft(MockExamDraft draft) async {
    if (_currentUser == null) return;
    _mockExamDraft = draft;
    await _persistProgress();
  }

  Future<void> clearMockExamDraft() async {
    if (_currentUser == null) return;
    _mockExamDraft = null;
    await _persistProgress();
  }

  /// Форсируем сохранение текущего прогресса маршрута/пробника.
  Future<void> flushProgress() async {
    await _persistProgress();
  }

  List<_StoredUser> _readUsers() {
    final raw = _prefs.getString(_kUsers);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => _StoredUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeUsers(List<_StoredUser> users) async {
    await _prefs.setString(
      _kUsers,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  AuthUser? _findUser(String email) {
    final users = _readUsers();
    for (final u in users) {
      if (u.email == email.toLowerCase()) {
        return AuthUser(
          email: u.email,
          name: u.name,
          grade: u.grade,
          subjects: u.subjects,
          weeklyHours: u.weeklyHours,
          mockExamScores: u.mockExamScores,
        );
      }
    }
    return null;
  }

  /// Сохранить класс пользователя (9/10/11) — шаг онбординга.
  Future<void> setGrade(int grade) async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Нет активной сессии');
    }
    final users = _readUsers();
    final idx = users.indexWhere((u) => u.email == user.email);
    if (idx == -1) {
      throw const AuthException('Пользователь не найден');
    }
    final old = users[idx];
    users[idx] = _StoredUser(
      email: old.email,
      name: old.name,
      salt: old.salt,
      hash: old.hash,
      grade: grade,
      subjects: old.subjects,
      weeklyHours: old.weeklyHours,
      mockExamScores: old.mockExamScores,
    );
    await _writeUsers(users);
    _currentUser = AuthUser(
      email: user.email,
      name: user.name,
      grade: grade,
      subjects: user.subjects,
      weeklyHours: user.weeklyHours,
      mockExamScores: user.mockExamScores,
    );
    notifyListeners();
  }

  /// Сохранить недельную нагрузку — финальный шаг онбординга.
  Future<void> setWeeklyHours(int hours) async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Нет активной сессии');
    }
    final users = _readUsers();
    final idx = users.indexWhere((u) => u.email == user.email);
    if (idx == -1) {
      throw const AuthException('Пользователь не найден');
    }
    final old = users[idx];
    users[idx] = _StoredUser(
      email: old.email,
      name: old.name,
      salt: old.salt,
      hash: old.hash,
      grade: old.grade,
      subjects: old.subjects,
      weeklyHours: hours,
      mockExamScores: old.mockExamScores,
    );
    await _writeUsers(users);
    _currentUser = AuthUser(
      email: user.email,
      name: user.name,
      grade: user.grade,
      subjects: user.subjects,
      weeklyHours: hours,
      mockExamScores: user.mockExamScores,
    );
    notifyListeners();
  }

  /// Сохранить балл пробника по предмету.
  Future<void> setMockExamScore({
    required String subjectId,
    required int score,
  }) async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Нет активной сессии');
    }
    final users = _readUsers();
    final idx = users.indexWhere((u) => u.email == user.email);
    if (idx == -1) {
      throw const AuthException('Пользователь не найден');
    }
    final old = users[idx];
    final nextScores = <String, int>{
      ...old.mockExamScores,
      subjectId: score.clamp(0, 100),
    };
    users[idx] = _StoredUser(
      email: old.email,
      name: old.name,
      salt: old.salt,
      hash: old.hash,
      grade: old.grade,
      subjects: old.subjects,
      weeklyHours: old.weeklyHours,
      mockExamScores: Map.unmodifiable(nextScores),
    );
    await _writeUsers(users);
    _currentUser = AuthUser(
      email: user.email,
      name: user.name,
      grade: user.grade,
      subjects: user.subjects,
      weeklyHours: user.weeklyHours,
      mockExamScores: Map.unmodifiable(nextScores),
    );
    notifyListeners();
  }

  /// Сохранить выбранные предметы ЕГЭ — шаг онбординга.
  Future<void> setSubjects(List<String> subjects) async {
    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Нет активной сессии');
    }
    final users = _readUsers();
    final idx = users.indexWhere((u) => u.email == user.email);
    if (idx == -1) {
      throw const AuthException('Пользователь не найден');
    }
    final old = users[idx];
    users[idx] = _StoredUser(
      email: old.email,
      name: old.name,
      salt: old.salt,
      hash: old.hash,
      grade: old.grade,
      subjects: List.unmodifiable(subjects),
      weeklyHours: old.weeklyHours,
      mockExamScores: old.mockExamScores,
    );
    await _writeUsers(users);
    _currentUser = AuthUser(
      email: user.email,
      name: user.name,
      grade: user.grade,
      subjects: List.unmodifiable(subjects),
      weeklyHours: user.weeklyHours,
      mockExamScores: user.mockExamScores,
    );
    notifyListeners();
  }

  /// Регистрация. Бросает [AuthException] с понятным сообщением при ошибке.
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordRepeat,
  }) async {
    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    if (trimmedName.isEmpty) {
      throw const AuthException('Введите имя');
    }
    if (trimmedName.length > nameMaxLength) {
      throw AuthException('Имя должно быть не длиннее $nameMaxLength символов');
    }
    if (password.length > passwordMaxLength) {
      throw AuthException(
        'Пароль должен быть не длиннее $passwordMaxLength символов',
      );
    }
    if (normalizedEmail.isEmpty) {
      throw const AuthException('Введите почту');
    }
    if (password != passwordRepeat) {
      throw const AuthException('Пароли не совпадают');
    }
    final passwordError = validatePassword(password);
    if (passwordError != null) {
      throw AuthException(passwordError);
    }

    final users = _readUsers();
    if (users.any((u) => u.email == normalizedEmail)) {
      throw const AuthException('Пользователь с такой почтой уже есть');
    }

    final salt = _generateSalt();
    final hash = _hashPassword(password, salt);
    users.add(
      _StoredUser(
        email: normalizedEmail,
        name: trimmedName,
        salt: salt,
        hash: hash,
      ),
    );
    await _writeUsers(users);

    await _startSession(normalizedEmail, trimmedName);
  }

  /// Логин по email/паролю.
  Future<void> login({required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const AuthException('Введите почту и пароль');
    }

    final users = _readUsers();
    final user = users
        .where((u) => u.email == normalizedEmail)
        .cast<_StoredUser?>()
        .firstWhere((_) => true, orElse: () => null);
    if (user == null) {
      throw const AuthException('Неверная почта или пароль');
    }
    final hash = _hashPassword(password, user.salt);
    if (hash != user.hash) {
      throw const AuthException('Неверная почта или пароль');
    }

    await _startSession(user.email, user.name);
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    _lastRoute = null;
    _mockExamDraft = null;
    await _prefs.remove(_kToken);
    await _prefs.remove(_kCurrentEmail);
    notifyListeners();
  }

  Future<void> _startSession(String email, String name) async {
    final token = _generateToken();
    await _prefs.setString(_kToken, token);
    await _prefs.setString(_kCurrentEmail, email);
    _token = token;
    final stored = _readUsers().firstWhere(
      (u) => u.email == email,
      orElse: () => _StoredUser(email: email, name: name, salt: '', hash: ''),
    );
    _currentUser = AuthUser(
      email: email,
      name: name,
      grade: stored.grade,
      subjects: stored.subjects,
      weeklyHours: stored.weeklyHours,
      mockExamScores: stored.mockExamScores,
    );
    _loadProgress(email);
    notifyListeners();
  }

  // ----- helpers -----

  static String _generateSalt() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _generateToken() {
    final r = Random.secure();
    final bytes = List<int>.generate(32, (_) => r.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt::$password');
    return sha256.convert(bytes).toString();
  }

  /// Валидация пароля. Возвращает текст ошибки или `null`, если всё ок.
  /// Требования: ≥8 символов, минимум одна буква, одна цифра и один спецсимвол.
  static String? validatePassword(String password) {
    if (password.length < 8) {
      return 'Пароль должен быть не короче 8 символов';
    }
    if (!RegExp(r'[A-Za-zА-Яа-яЁё]').hasMatch(password)) {
      return 'Пароль должен содержать хотя бы одну букву';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Пароль должен содержать хотя бы одну цифру';
    }
    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=\[\]/\\;`~]').hasMatch(password)) {
      return 'Пароль должен содержать хотя бы один спецсимвол';
    }
    return null;
  }
}

class AuthUser {
  const AuthUser({
    required this.email,
    required this.name,
    this.grade,
    this.subjects = const [],
    this.weeklyHours,
    this.mockExamScores = const {},
  });
  final String email;
  final String name;

  /// Школьный класс пользователя (9/10/11). `null`, пока не выбран в онбординге.
  final int? grade;

  /// Предметы ЕГЭ, выбранные на втором шаге онбординга. Пусто, пока не выбраны.
  final List<String> subjects;

  /// Сколько часов в неделю пользователь готов уделять подготовке.
  /// `null`, пока не задано.
  final int? weeklyHours;

  /// Баллы пробников по предметам, ключ — id предмета.
  final Map<String, int> mockExamScores;
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MockExamDraft {
  const MockExamDraft({
    required this.subjectId,
    required this.subjectTitle,
    required this.index,
    required this.answers,
  });

  final String subjectId;
  final String subjectTitle;
  final int index;
  final Map<String, String> answers;

  Map<String, dynamic> toJson() => {
    'subjectId': subjectId,
    'subjectTitle': subjectTitle,
    'index': index,
    'answers': answers,
  };

  factory MockExamDraft.fromJson(Map<String, dynamic> json) => MockExamDraft(
    subjectId: json['subjectId'] as String,
    subjectTitle: json['subjectTitle'] as String,
    index: (json['index'] as num).toInt(),
    answers: (json['answers'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as String),
    ),
  );
}

class _StoredUser {
  _StoredUser({
    required this.email,
    required this.name,
    required this.salt,
    required this.hash,
    this.grade,
    this.subjects = const [],
    this.weeklyHours,
    this.mockExamScores = const {},
  });

  final String email;
  final String name;
  final String salt;
  final String hash;
  final int? grade;
  final List<String> subjects;
  final int? weeklyHours;
  final Map<String, int> mockExamScores;

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'salt': salt,
    'hash': hash,
    if (grade != null) 'grade': grade,
    if (subjects.isNotEmpty) 'subjects': subjects,
    if (weeklyHours != null) 'weeklyHours': weeklyHours,
    if (mockExamScores.isNotEmpty) 'mockExamScores': mockExamScores,
  };

  factory _StoredUser.fromJson(Map<String, dynamic> json) => _StoredUser(
    email: json['email'] as String,
    name: json['name'] as String,
    salt: json['salt'] as String,
    hash: json['hash'] as String,
    grade: (json['grade'] as num?)?.toInt(),
    subjects:
        (json['subjects'] as List?)
            ?.map((e) => e as String)
            .toList(growable: false) ??
        const [],
    weeklyHours: (json['weeklyHours'] as num?)?.toInt(),
    mockExamScores:
        (json['mockExamScores'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        const {},
  );
}
