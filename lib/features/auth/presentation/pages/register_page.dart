import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../../shared/widgets/pill_text_field.dart';
import '../../../../shared/widgets/swipe_back.dart';
import '../widgets/auth_hero.dart';
import '../widgets/or_divider.dart';
import '../widgets/switch_auth_link.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordRepeatCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordRepeatCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    // TODO: реальная регистрация.
  }

  void _onTelegram() {
    // TODO: OAuth через Telegram.
  }

  void _toLogin() {
    Navigator.of(context).pushReplacementNamed(AppRouter.login);
  }

  @override
  Widget build(BuildContext context) {
    // Пока клавиатура открыта — прячем «побочные» блоки (или-разделитель,
    // Telegram, ссылку): они не нужны во время ввода и иначе не помещаются
    // без скролла.
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
                    flex: 2,
                    child: AuthHero(
                      title: AppStrings.registerTitle,
                      subtitle: AppStrings.registerSubtitle,
                    ),
                  ),
                  const SizedBox(height: 16),
                  PillTextField(
                    hint: AppStrings.nameHint,
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.givenName],
                  ),
                  const SizedBox(height: 10),
                  PillTextField(
                    hint: AppStrings.emailHint,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 10),
                  PillTextField(
                    hint: AppStrings.passwordHint,
                    controller: _passwordCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: 10),
                  PillTextField(
                    hint: AppStrings.passwordRepeatHint,
                    controller: _passwordRepeatCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onSubmit(),
                  ),
                  const Spacer(),
                  PillPrimaryButton(
                    label: AppStrings.signUp,
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
                                const SizedBox(height: 14),
                                const OrDivider(),
                                const SizedBox(height: 14),
                                PillTelegramButton(
                                  label: AppStrings.signInWithTelegram,
                                  onPressed: _onTelegram,
                                ),
                                const SizedBox(height: 8),
                                SwitchAuthLink(
                                  leading: AppStrings.alreadyHaveAccount,
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
