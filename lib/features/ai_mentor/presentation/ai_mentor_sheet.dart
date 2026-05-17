import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/haptics.dart';
import '../data/ai_mentor_service.dart';

/// Открывает шит с AI-ментором. Использует тот же паттерн, что и
/// `_showLocationSheet` в cloudz_app: `showModalBottomSheet` со
/// стеклянным контейнером, drag-pill, плавной встроенной анимацией
/// слайда снизу. Так не дёргается контент и корректно работает с
/// клавиатурой (только composer поднимается над `viewInsets.bottom`).
Future<void> showAiMentorSheet({
  required BuildContext context,
  required AiTaskContext task,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.46),
    builder: (context) {
      // Фиксированная высота от полного экрана — не от уменьшенных
      // constraints, иначе лист «съёживается» при клавиатуре и контент
      // дёргается. viewInsets оставляем, чтобы composer мог корректно
      // подняться над клавиатурой через AnimatedPadding.
      final screenHeight = MediaQuery.of(context).size.height;
      return SizedBox(
        height: screenHeight * 0.9,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.96),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border.all(
                  color: AppColors.text.withValues(alpha: 0.08),
                ),
              ),
              child: _AiMentorSheet(task: task),
            ),
          ),
        ),
      );
    },
  );
}

class _AiMentorSheet extends StatefulWidget {
  const _AiMentorSheet({required this.task});

  final AiTaskContext task;

  @override
  State<_AiMentorSheet> createState() => _AiMentorSheetState();
}

class _AiMentorSheetState extends State<_AiMentorSheet> {
  final _service = AiMentorService();
  final _history = <AiMessage>[];
  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Авто-приветствие: попросим модель кратко наметить путь решения.
    Future.microtask(_kickoff);
  }

  @override
  void dispose() {
    _service.dispose();
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  Future<void> _kickoff() async {
    await _ask('Подскажи, с чего начать решение этой задачи. '
        'Дай идею и метод, но пока без готового ответа.');
  }

  Future<void> _ask(String text) async {
    if (text.trim().isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _history.add(AiMessage(role: 'user', content: text.trim()));
    });
    _scrollToBottom();
    try {
      final reply = await _service.ask(task: widget.task, history: _history);
      if (!mounted) return;
      setState(() {
        _history.add(AiMessage(role: 'assistant', content: reply));
      });
      _scrollToBottom();
    } on AiMentorException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Сеть недоступна. Попробуй ещё раз.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtl.hasClients) return;
      _scrollCtl.animateTo(
        _scrollCtl.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _submit() async {
    final text = _inputCtl.text;
    if (text.trim().isEmpty) return;
    AppHaptics.tap();
    _inputCtl.clear();
    await _ask(text);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        _Header(onClose: () => Navigator.of(context).pop()),
        _TaskPreview(task: widget.task),
        const SizedBox(height: 6),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _MessagesList(
              controller: _scrollCtl,
              history: _history,
              loading: _loading,
              error: _error,
            ),
          ),
        ),
        // Только composer поднимается над клавиатурой: остальная
        // часть листа остаётся на месте, ничего не дёргается.
        AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(
            bottom: bottomInset > 0 ? bottomInset : safeBottom,
          ),
          child: _Composer(
            controller: _inputCtl,
            onSubmit: _submit,
            enabled: !_loading,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 8),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.text.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI ментор',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Поможет разобрать задачу',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0x990D0D0D),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  color: AppColors.text.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskPreview extends StatelessWidget {
  const _TaskPreview({required this.task});

  final AiTaskContext task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.taskSource,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              task.taskPrompt,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.text.withValues(alpha: 0.8),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.controller,
    required this.history,
    required this.loading,
    required this.error,
  });

  final ScrollController controller;
  final List<AiMessage> history;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty && loading) {
      return const Center(child: _TypingDots());
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: history.length + (loading ? 1 : 0) + (error != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i < history.length) {
          final m = history[i];
          return _MessageBubble(message: m);
        }
        if (error != null && i == history.length + (loading ? 1 : 0) - 1 + 1) {
          return _ErrorBubble(message: error!);
        }
        return const Align(
          alignment: Alignment.centerLeft,
          child: _TypingDots(),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: Container(
            key: ValueKey(message.content.hashCode),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary
                  : AppColors.text.withValues(alpha: 0.04),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: isUser
                  ? null
                  : Border.all(
                      color: AppColors.text.withValues(alpha: 0.08),
                    ),
            ),
            child: isUser
                ? SelectableText(
                    message.content,
                    style: const TextStyle(
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: AppColors.background,
                    ),
                  )
                : MarkdownBody(
                    data: message.content,
                    selectable: true,
                    softLineBreak: true,
                    styleSheet: _markdownStyles(),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE6E6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Color(0xFFB00020),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFB00020),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Анимация трёх точек — индикатор «AI думает».
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.text.withValues(alpha: 0.04),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(18),
        ),
        border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
      ),
      child: AnimatedBuilder(
        animation: _ctl,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                _Dot(phase: (_ctl.value + i * 0.18) % 1.0),
                if (i != 2) const SizedBox(width: 6),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.phase});

  final double phase;

  @override
  Widget build(BuildContext context) {
    final t = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(0.0, 1.0);
    return Container(
      width: 7 + t * 2,
      height: 7 + t * 2,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.35 + t * 0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSubmit,
    required this.enabled,
  });

  final TextEditingController controller;
  final VoidCallback onSubmit;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.text.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.text.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSubmit(),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(800),
                ],
                style: const TextStyle(
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
                decoration: InputDecoration(
                  hintText: 'Спроси что-нибудь по задаче…',
                  hintStyle: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.text.withValues(alpha: 0.45),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: AnimatedScale(
                scale: enabled ? 1 : 0.94,
                duration: const Duration(milliseconds: 180),
                child: Material(
                  color: enabled
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.45),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? onSubmit : null,
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.background,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Стили markdown под общий шрифт приложения: тот же SpaceGrotesk,
/// тёмный текст, primary-цвет для ссылок, мягкие скруглённые блоки кода.
MarkdownStyleSheet _markdownStyles() {
  const base = TextStyle(
    fontFamily: 'SpaceGrotesk',
    fontSize: 14.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.text,
  );
  return MarkdownStyleSheet(
    p: base,
    h1: base.copyWith(fontSize: 19, fontWeight: FontWeight.w700, height: 1.25),
    h2: base.copyWith(fontSize: 17, fontWeight: FontWeight.w700, height: 1.25),
    h3: base.copyWith(fontSize: 15.5, fontWeight: FontWeight.w700),
    strong: base.copyWith(fontWeight: FontWeight.w700),
    em: base.copyWith(fontStyle: FontStyle.italic),
    a: base.copyWith(
      color: AppColors.primary,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.primary,
    ),
    listBullet: base,
    code: base.copyWith(
      fontFamily: 'SpaceGrotesk',
      fontSize: 13.5,
      backgroundColor: AppColors.text.withValues(alpha: 0.06),
      color: AppColors.primary,
    ),
    codeblockDecoration: BoxDecoration(
      color: AppColors.text.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.text.withValues(alpha: 0.08)),
    ),
    codeblockPadding: const EdgeInsets.all(12),
    blockquoteDecoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      border: Border(
        left: BorderSide(color: AppColors.primary, width: 3),
      ),
    ),
    blockquotePadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
    blockSpacing: 8,
    listIndent: 18,
  );
}
