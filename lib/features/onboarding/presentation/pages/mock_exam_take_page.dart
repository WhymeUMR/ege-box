import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../../../../core/services/activity_service.dart';
import '../../../../core/services/topic_stats_service.dart';
import '../../../ai_mentor/data/ai_mentor_service.dart';
import '../../../ai_mentor/presentation/ai_mentor_sheet.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/mock_exam_bank.dart';

class MockExamTakeArgs {
  const MockExamTakeArgs({
    required this.subjectId,
    required this.subjectTitle,
    required this.initialScore,
    this.isPractice = false,
  });

  final String subjectId;
  final String subjectTitle;
  final int initialScore;

  /// `true` — режим тренировки (запуск из Tasks). В этом режиме внизу
  /// показываем кнопку «Спросить у AI ментора». `false` — пробник.
  final bool isPractice;
}

class MockExamTakePage extends StatefulWidget {
  const MockExamTakePage({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    required this.initialScore,
    this.isPractice = false,
  });

  final String subjectId;
  final String subjectTitle;
  final int initialScore;
  final bool isPractice;

  @override
  State<MockExamTakePage> createState() => _MockExamTakePageState();
}

class _MockExamTakePageState extends State<MockExamTakePage> {
  late final List<MockExamTask> _tasks =
      mockExamBankBySubject[widget.subjectId] ?? const <MockExamTask>[];
  final Map<String, String> _answers = <String, String>{};
  late List<String> _visibleTaskIds = _tasks.map((t) => t.id).toList();
  final TextEditingController _answerCtl = TextEditingController();
  int _index = 0;
  bool _finished = false;
  late AuthService _auth;
  late ActivityService _activity;
  late TopicStatsService _topicStats;
  final Set<String> _loggedAttempts = <String>{};
  late final Timer _timer;
  int _remainingSeconds = 4 * 60 * 60;
  bool _mistakesMode = false;
  int? _resultScore;
  List<int> _resultWrong = const [];

  MockExamTask get _task =>
      _tasks.firstWhere((t) => t.id == _visibleTaskIds[_index]);

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
    _activity = context.read<ActivityService>();
    _topicStats = context.read<TopicStatsService>();
    final draft = _auth.mockExamDraft;
    if (draft != null && draft.subjectId == widget.subjectId) {
      _answers.addAll(draft.answers);
      _index = draft.index.clamp(0, _tasks.length - 1);
    }
    _answerCtl.text = _answers[_task.id] ?? '';
    _auth.setLastRoute(AppRouter.mockExamTake);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _remainingSeconds <= 0) return;
      setState(() => _remainingSeconds -= 1);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    if (!_finished) {
      _persistTypedAnswer();
      _persistDraft();
    }
    _answerCtl.dispose();
    super.dispose();
  }

  void _selectTask(int index) {
    AppHaptics.select();
    _persistTypedAnswer();
    setState(() {
      _index = index;
      _answerCtl.text = _answers[_task.id] ?? '';
    });
    _persistDraft();
  }

  void _persistTypedAnswer() {
    final typed = _answerCtl.text.trim();
    if (typed.isEmpty) return;
    _answers[_task.id] = typed;
  }

  void _saveAnswer() {
    final typed = _answerCtl.text.trim();
    if (typed.isEmpty) return;
    AppHaptics.tap();
    final task = _task;
    setState(() {
      _answers[task.id] = typed;
    });
    // Лог активности + statы по теме — фиксируем один раз на задачу.
    _activity.logActivity();
    if (_loggedAttempts.add(task.id)) {
      final correct = _normalize(typed) == _normalize(task.correctAnswer);
      _topicStats.recordAttempt(topic: task.topic, correct: correct);
    }
    if (_index < _visibleTaskIds.length - 1) {
      _selectTask(_index + 1);
    } else {
      _persistDraft();
      _finishExam();
    }
  }

  void _openAiMentor() {
    _persistTypedAnswer();
    AppHaptics.tap();
    showAiMentorSheet(
      context: context,
      task: AiTaskContext(
        subjectTitle: widget.subjectTitle,
        taskSource: _task.source,
        taskPrompt: _task.prompt,
        correctAnswer: _task.correctAnswer,
        userAnswer: _answers[_task.id],
      ),
    );
  }

  void _persistDraft() {
    _auth.saveMockExamDraft(
      MockExamDraft(
        subjectId: widget.subjectId,
        subjectTitle: widget.subjectTitle,
        index: _index,
        answers: Map.unmodifiable(_answers),
      ),
    );
  }

  int _calculateScore() {
    if (_tasks.isEmpty) return widget.initialScore;
    var correct = 0;
    for (final t in _tasks) {
      final userAnswer = _normalize(_answers[t.id] ?? '');
      final expected = _normalize(t.correctAnswer);
      if (userAnswer == expected) correct++;
    }
    return ((correct / _tasks.length) * 100).round();
  }

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(',', '.');
  }

  List<int> _wrongTaskNumbers() {
    final wrong = <int>[];
    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      final userAnswer = _normalize(_answers[task.id] ?? '');
      final expected = _normalize(task.correctAnswer);
      if (userAnswer != expected) wrong.add(i + 1);
    }
    return wrong;
  }

  Future<bool> _confirmFinish() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Завершить пробник?',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          content: const Text(
            'Ты точно уверен, что хочешь завершить пробник сейчас?',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
              color: AppColors.text,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppHaptics.select();
                Navigator.of(context).pop(false);
              },
              child: const Text('Продолжить'),
            ),
            TextButton(
              onPressed: () {
                AppHaptics.tap();
                Navigator.of(context).pop(true);
              },
              child: const Text('Завершить'),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _finishExam() async {
    final shouldFinish = await _confirmFinish();
    if (!mounted || !shouldFinish) return;
    _persistTypedAnswer();
    final score = _calculateScore();
    final wrong = _wrongTaskNumbers();
    // Также залогируем темы для тех задач, что ученик не открывал
    // явно через _saveAnswer (например, пропустил → пустой ответ).
    for (final t in _tasks) {
      if (_loggedAttempts.contains(t.id)) continue;
      final answer = _normalize(_answers[t.id] ?? '');
      final correct = answer == _normalize(t.correctAnswer);
      _topicStats.recordAttempt(topic: t.topic, correct: correct);
      _loggedAttempts.add(t.id);
    }
    AppHaptics.success();
    setState(() {
      _resultScore = score;
      _resultWrong = wrong;
    });
  }

  Future<void> _finalizeAndClose() async {
    _finished = true;
    final score = _resultScore ?? widget.initialScore;
    await _auth.setMockExamScore(
      subjectId: widget.subjectId,
      score: score,
    );
    await _auth.clearMockExamDraft();
    await _auth.setLastRoute(AppRouter.onboardingMock);
    if (!mounted) return;
    Navigator.of(context).pop(score);
  }

  void _enterMistakesMode() {
    setState(() {
      _mistakesMode = true;
      _visibleTaskIds = _resultWrong.map((n) => _tasks[n - 1].id).toList();
      _index = 0;
      _resultScore = null;
      _resultWrong = const [];
      _answerCtl.text = _answers[_task.id] ?? '';
    });
    _persistDraft();
  }

  void _explainWithAi(MockExamTask task) {
    AppHaptics.tap();
    showAiMentorSheet(
      context: context,
      task: AiTaskContext(
        subjectTitle: widget.subjectTitle,
        taskSource: task.source,
        taskPrompt: task.prompt,
        correctAnswer: task.correctAnswer,
        userAnswer: _answers[task.id],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_resultScore != null) {
      return _ResultsView(
        score: _resultScore!,
        wrong: _resultWrong,
        tasks: _tasks,
        answers: _answers,
        subjectTitle: widget.subjectTitle,
        mistakesMode: _mistakesMode,
        onMistakes: _resultWrong.isNotEmpty && !_mistakesMode
            ? _enterMistakesMode
            : null,
        onFinish: _finalizeAndClose,
        onExplain: _explainWithAi,
      );
    }
    if (_tasks.isEmpty) {
      return SwipeBack(
        child: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Пробник: ${widget.subjectTitle}',
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: AppColors.text,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Для этого предмета пока нет задач в локальном банке.',
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      color: AppColors.text.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  PillPrimaryButton(
                    label: 'Назад',
                    onPressed: () =>
                        Navigator.of(context).pop(widget.initialScore),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final answeredCount = _visibleTaskIds
        .where((id) => (_answers[id] ?? '').trim().isNotEmpty)
        .length;
    final progress = _visibleTaskIds.isEmpty
        ? 0.0
        : answeredCount / _visibleTaskIds.length;

    return SwipeBack(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Row(
                  children: [
                    Image.asset('assets/logo_main.png', width: 34, height: 34),
                    const SizedBox(width: 10),
                    const Text(
                      'Ege Box',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                        height: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.text.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _formatTimer(_remainingSeconds),
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _remainingSeconds <= 300
                              ? const Color(0xFFB05A00)
                              : AppColors.text.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _finishExam,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: AppColors.text.withValues(
                            alpha: 0.08,
                          ),
                          foregroundColor: AppColors.text,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text(
                          'Завершить',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 1,
                color: AppColors.text.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  itemCount: _visibleTaskIds.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final taskId = _visibleTaskIds[i];
                    final selected = i == _index;
                    final taskNumber =
                        _tasks.indexWhere((t) => t.id == taskId) + 1;
                    return InkWell(
                      onTap: () => _selectTask(i),
                      borderRadius: BorderRadius.circular(14),
                      child: Ink(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.text
                              : AppColors.text.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            '$taskNumber',
                            style: TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? AppColors.background
                                  : AppColors.text,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  value: progress,
                  color: AppColors.primary,
                  backgroundColor: AppColors.text.withValues(alpha: 0.12),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.text.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0.04, 0),
                                  end: Offset.zero,
                                ).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slide,
                                    child: child,
                                  ),
                                );
                              },
                              child: Column(
                                key: ValueKey(_task.id),
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Задание ${_tasks.indexWhere((t) => t.id == _task.id) + 1}',
                                        style: const TextStyle(
                                          fontFamily: 'SpaceGrotesk',
                                          color: AppColors.text,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.link_rounded,
                                        size: 18,
                                        color: AppColors.text.withValues(
                                          alpha: 0.45,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _task.source,
                                    style: TextStyle(
                                      fontFamily: 'SpaceGrotesk',
                                      color: AppColors.text.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Text(
                                        _task.prompt,
                                        style: const TextStyle(
                                          fontFamily: 'SpaceGrotesk',
                                          color: AppColors.text,
                                          fontSize: 16,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _answerCtl,
                            style: const TextStyle(
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.text,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Введите ответ',
                              hintStyle: TextStyle(
                                fontFamily: 'SpaceGrotesk',
                                color: AppColors.text.withValues(alpha: 0.45),
                                fontSize: 16,
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.text.withValues(alpha: 0.15),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: AppColors.text.withValues(alpha: 0.15),
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(16),
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _saveAnswer,
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              child: const Text(
                                'Сохранить ответ',
                                style: TextStyle(
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          if (widget.isPractice) ...[
                            const SizedBox(height: 10),
                            _AskAiButton(
                              onPressed: _openAiMentor,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatTimer(int seconds) {
  final s = seconds.clamp(0, 4 * 60 * 60);
  final h = (s ~/ 3600).toString().padLeft(2, '0');
  final m = ((s % 3600) ~/ 60).toString().padLeft(2, '0');
  final sec = (s % 60).toString().padLeft(2, '0');
  return '$h:$m:$sec';
}

/// Кнопка вызова AI-ментора, видна только в режиме тренировки.
/// Стиль: пилюля с primary-обводкой, иконка sparkles, лёгкая
/// анимация нажатия — соответствует общему языку приложения.
class _AskAiButton extends StatefulWidget {
  const _AskAiButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_AskAiButton> createState() => _AskAiButtonState();
}

class _AskAiButtonState extends State<_AskAiButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.primary.withValues(alpha: 0.14)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: _pressed ? 0.55 : 0.35),
              width: 1.4,
            ),
          ),
          alignment: Alignment.center,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Спросить у AI ментора',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Экран результатов пробника с разбором ошибок.
/// По каждой неверной задаче пользователь может вызвать AI-ментора,
/// чтобы получить персональный разбор ошибки.
class _ResultsView extends StatelessWidget {
  const _ResultsView({
    required this.score,
    required this.wrong,
    required this.tasks,
    required this.answers,
    required this.subjectTitle,
    required this.mistakesMode,
    required this.onMistakes,
    required this.onFinish,
    required this.onExplain,
  });

  final int score;
  final List<int> wrong;
  final List<MockExamTask> tasks;
  final Map<String, String> answers;
  final String subjectTitle;
  final bool mistakesMode;
  final VoidCallback? onMistakes;
  final VoidCallback onFinish;
  final ValueChanged<MockExamTask> onExplain;

  String _wrongWord(int n) {
    final m10 = n % 10;
    final m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'ошибка';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'ошибки';
    return 'ошибок';
  }

  @override
  Widget build(BuildContext context) {
    final correctCount = tasks.length - wrong.length;
    return SwipeBack(
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  children: [
                    _HeroResult(
                      score: score,
                      subjectTitle: subjectTitle,
                      correctCount: correctCount,
                      total: tasks.length,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        wrong.isEmpty
                            ? 'Все задания решены верно'
                            : '${wrong.length} ${_wrongWord(wrong.length)}'
                                ' · разбери с AI ментором',
                        style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    for (var i = 0; i < tasks.length; i++) ...[
                      _ResultRow(
                        index: i + 1,
                        task: tasks[i],
                        userAnswer: answers[tasks[i].id] ?? '',
                        isCorrect: !wrong.contains(i + 1),
                        onExplain: () => onExplain(tasks[i]),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  children: [
                    if (onMistakes != null) ...[
                      _ResultPill(
                        label: 'Работа над ошибками',
                        outline: true,
                        onTap: onMistakes!,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _ResultPill(
                      label: mistakesMode ? 'К результатам' : 'Завершить',
                      outline: false,
                      onTap: onFinish,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroResult extends StatelessWidget {
  const _HeroResult({
    required this.score,
    required this.subjectTitle,
    required this.correctCount,
    required this.total,
  });

  final int score;
  final String subjectTitle;
  final int correctCount;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subjectTitle.toUpperCase(),
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.background.withValues(alpha: 0.85),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: AppColors.background,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '/ 100',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.background.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Решено верно: $correctCount из $total',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.background.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.index,
    required this.task,
    required this.userAnswer,
    required this.isCorrect,
    required this.onExplain,
  });

  final int index;
  final MockExamTask task;
  final String userAnswer;
  final bool isCorrect;
  final VoidCallback onExplain;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.04),
        borderRadius: radius,
        border: Border.all(
          color: isCorrect
              ? AppColors.text.withValues(alpha: 0.08)
              : AppColors.primary.withValues(alpha: 0.3),
          width: isCorrect ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFF1F8B4C).withValues(alpha: 0.14)
                        : AppColors.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isCorrect ? Icons.check_rounded : Icons.close_rounded,
                    size: 18,
                    color: isCorrect
                        ? const Color(0xFF1F8B4C)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Задание $index',
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    task.topic,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.prompt,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withValues(alpha: 0.85),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _AnswerChip(
                  label: 'Твой',
                  value: userAnswer.isEmpty ? '—' : userAnswer,
                  highlight: !isCorrect,
                ),
                _AnswerChip(
                  label: 'Верный',
                  value: task.correctAnswer,
                  highlight: false,
                  positive: true,
                ),
              ],
            ),
            if (!isCorrect) ...[
              const SizedBox(height: 10),
              _ExplainPill(onTap: onExplain),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.label,
    required this.value,
    required this.highlight,
    this.positive = false,
  });

  final String label;
  final String value;
  final bool highlight;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = positive
        ? const Color(0xFF1F8B4C)
        : (highlight ? AppColors.primary : AppColors.text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ExplainPill extends StatelessWidget {
  const _ExplainPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Разобрать с AI',
                style: TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultPill extends StatelessWidget {
  const _ResultPill({
    required this.label,
    required this.outline,
    required this.onTap,
  });

  final String label;
  final bool outline;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: outline
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary, width: 1.4),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }
}
