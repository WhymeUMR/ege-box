import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/pill_text_field.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../widgets/auth_hero.dart';
import '../widgets/switch_auth_link.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    // TODO: реальный запрос на сброс пароля.
  }

  void _toLogin() {
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return SwipeBack(
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _BackRow(onBack: () => Navigator.of(context).maybePop()),
                const SizedBox(height: 8),
                Flexible(
                  flex: 3,
                  child: AuthHero(
                    title: AppStrings.forgotTitle,
                    subtitle: AppStrings.forgotSubtitle,
                  ),
                ),
                const SizedBox(height: 20),
                PillTextField(
                  hint: AppStrings.emailHint,
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSubmit(),
                  autofillHints: const [AutofillHints.email],
                ),
                const Spacer(),
                PillPrimaryButton(
                  label: AppStrings.sendResetLink,
                  onPressed: _onSubmit,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 140),
                    curve: Curves.easeOut,
                    opacity: isKeyboardOpen ? 0 : 1,
                    child: isKeyboardOpen
                        ? const SizedBox(width: double.infinity)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              SwitchAuthLink(
                                leading: AppStrings.rememberedPassword,
                                action: AppStrings.signIn,
                                onTap: _toLogin,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkResponse(
        onTap: onBack,
        radius: 24,
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.text,
            size: 28,
          ),
        ),
      ),
    );
  }
}
