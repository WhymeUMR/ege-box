import 'dart:async';

import 'package:flutter/material.dart';

/// Текст с эффектом «печатной машинки»: посимвольно печатает фразу,
/// держит её, посимвольно стирает и переходит к следующей. Зацикливается.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.phrases,
    this.style,
    this.textAlign = TextAlign.center,
    this.typeSpeed = const Duration(milliseconds: 55),
    this.eraseSpeed = const Duration(milliseconds: 30),
    this.holdAfterType = const Duration(milliseconds: 1500),
    this.holdAfterErase = const Duration(milliseconds: 350),
    this.cursor = '|',
  });

  final List<String> phrases;
  final TextStyle? style;
  final TextAlign textAlign;
  final Duration typeSpeed;
  final Duration eraseSpeed;
  final Duration holdAfterType;
  final Duration holdAfterErase;
  final String cursor;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText>
    with SingleTickerProviderStateMixin {
  int _phraseIndex = 0;
  int _charCount = 0;
  bool _typing = true;
  Timer? _stepTimer;
  late final AnimationController _cursorController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scheduleNext(Duration.zero);
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  void _scheduleNext(Duration delay) {
    _stepTimer?.cancel();
    _stepTimer = Timer(delay, _step);
  }

  void _step() {
    if (!mounted) return;
    final phrase = widget.phrases[_phraseIndex];

    if (_typing) {
      if (_charCount < phrase.length) {
        setState(() => _charCount++);
        _scheduleNext(widget.typeSpeed);
      } else {
        // Дописали — держим, потом начинаем стирать.
        _typing = false;
        _scheduleNext(widget.holdAfterType);
      }
    } else {
      if (_charCount > 0) {
        setState(() => _charCount--);
        _scheduleNext(widget.eraseSpeed);
      } else {
        // Стёрли — следующая фраза.
        _typing = true;
        _phraseIndex = (_phraseIndex + 1) % widget.phrases.length;
        _scheduleNext(widget.holdAfterErase);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrases[_phraseIndex];
    final visible = phrase.substring(0, _charCount);
    return AnimatedBuilder(
      animation: _cursorController,
      builder: (_, __) {
        final cursorVisible = _cursorController.value > 0.5;
        return Text(
          '$visible${cursorVisible ? widget.cursor : ' '}',
          textAlign: widget.textAlign,
          style: widget.style,
        );
      },
    );
  }
}
