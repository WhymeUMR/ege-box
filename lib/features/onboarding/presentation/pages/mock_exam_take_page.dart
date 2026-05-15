import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../../../auth/data/auth_service.dart';
import '../../data/mock_exam_bank.dart';

class MockExamTakeArgs {
  const MockExamTakeArgs({
    required this.subjectId,
    required this.subjectTitle,
    required this.initialScore,
  });

  final String subjectId;
  final String subjectTitle;
  final int initialScore;
}

class MockExamTakePage extends StatefulWidget {
  const MockExamTakePage({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    required this.initialScore,
  });

  final String subjectId;
  final String subjectTitle;
  final int initialScore;

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
  late final Timer _timer;
  int _remainingSeconds = 4 * 60 * 60;
  bool _mistakesMode = false;

  MockExamTask get _task =>
      _tasks.firstWhere((t) => t.id == _visibleTaskIds[_index]);

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthService>();
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
    setState(() {
      _answers[_task.id] = typed;
    });
    if (_index < _visibleTaskIds.length - 1) {
      _selectTask(_index + 1);
    } else {
      _persistDraft();
      _finishExam();
    }
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
    if (!mounted) return;
    final action = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Пробник завершён',
            style: TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          content: Text(
            wrong.isEmpty
                ? 'Результат: $score/100\n\nВсе задания выполнены верно.'
                : 'Результат: $score/100\n\nОшибки в номерах: ${wrong.join(', ')}',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
              color: AppColors.text,
              height: 1.35,
            ),
          ),
          actions: [
            if (wrong.isNotEmpty && !_mistakesMode)
              TextButton(
                onPressed: () {
                  AppHaptics.select();
                  Navigator.of(context).pop('mistakes');
                },
                child: const Text('Работа над ошибками'),
              ),
            TextButton(
              onPressed: () {
                AppHaptics.success();
                Navigator.of(context).pop('finish');
              },
              child: const Text('Завершить'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (action == 'mistakes') {
      setState(() {
        _mistakesMode = true;
        _visibleTaskIds = wrong.map((n) => _tasks[n - 1].id).toList();
        _index = 0;
        _answerCtl.text = _answers[_task.id] ?? '';
      });
      _persistDraft();
      return;
    }
    if (!mounted) return;
    _finished = true;
    await _auth.clearMockExamDraft();
    await _auth.setLastRoute(AppRouter.onboardingMock);
    if (!mounted) return;
    Navigator.of(context).pop(score);
  }

  @override
  Widget build(BuildContext context) {
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
