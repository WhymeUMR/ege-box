import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// Поле ввода в том же «pill»-стиле, что и кнопки на welcome-экране:
/// полностью скруглённое, обводка цветом [AppColors.primary], высота 56.
class PillTextField extends StatelessWidget {
  const PillTextField({
    super.key,
    required this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.maxLength,
  });

  final String hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  /// Жёсткий лимит длины ввода (через [LengthLimitingTextInputFormatter]).
  /// Счётчик не показываем — просто перестаём принимать символы.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(BorderSide side) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(40),
          borderSide: side,
        );

    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofillHints: autofillHints,
        inputFormatters: [
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        cursorColor: AppColors.primary,
        // Тап вне поля — скрыть клавиатуру.
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        style: const TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.text,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.text.withValues(alpha: 0.45),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          filled: false,
          border: border(const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          )),
          enabledBorder: border(const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          )),
          focusedBorder: border(const BorderSide(
            color: AppColors.primary,
            width: 2,
          )),
        ),
      ),
    );
  }
}
