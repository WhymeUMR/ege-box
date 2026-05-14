import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/swipe_back.dart';

class MockExamTakePage extends StatefulWidget {
  const MockExamTakePage({
    super.key,
    required this.subjectTitle,
    required this.initialScore,
  });

  final String subjectTitle;
  final int initialScore;

  @override
  State<MockExamTakePage> createState() => _MockExamTakePageState();
}

class _MockExamTakePageState extends State<MockExamTakePage> {
  late int _score = widget.initialScore;

  @override
  Widget build(BuildContext context) {
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
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Технический демо-экран пробника. После завершения вернём тебя обратно и сохраним балл.',
                  style: TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_score/100',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    color: AppColors.text,
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.text.withValues(alpha: 0.12),
                    thumbColor: AppColors.primary,
                    overlayColor: AppColors.primary.withValues(alpha: 0.14),
                    trackHeight: 6,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 11,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: 100,
                    divisions: 100,
                    value: _score.toDouble(),
                    onChanged: (value) =>
                        setState(() => _score = value.round()),
                  ),
                ),
                const Spacer(),
                PillPrimaryButton(
                  label: 'Завершить пробник',
                  onPressed: () => Navigator.of(context).pop(_score),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
