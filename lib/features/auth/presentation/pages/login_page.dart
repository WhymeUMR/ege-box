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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    FocusScope.of(context).unfocus();
    // TODO: реальный вход.
  }

  void _onTelegram() {
    // TODO: OAuth через Telegram.
  }

  void _onForgot() {
    // TODO: восстановление пароля.
  }

  void _toRegister() {
    Navigator.of(context).pushReplacementNamed(AppRouter.register);
  }

  @override
  Widget build(BuildContext context) {
    // Пока клавиатура открыта — прячем «побочные» блоки, чтобы форма
    // гарантированно помещалась без скролла.
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
                  // Хиро сжимается при появлении клавиатуры.
                  Flexible(
                    flex: 3,
                    child: AuthHero(
                      title: AppStrings.loginTitle,
                      subtitle: AppStrings.loginSubtitle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PillTextField(
                    hint: AppStrings.emailHint,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 12),
                  PillTextField(
                    hint: AppStrings.passwordHint,
                    controller: _passwordCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onSubmit(),
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _onForgot,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text(AppStrings.forgotPassword),
                    ),
                  ),
                  const Spacer(),
                  PillPrimaryButton(
                    label: AppStrings.signIn,
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
                                const OrDivider(),
                                const SizedBox(height: 16),
                                PillTelegramButton(
                                  label: AppStrings.signInWithTelegram,
                                  onPressed: _onTelegram,
                                ),
                                const SizedBox(height: 8),
                                SwitchAuthLink(
                                  leading: AppStrings.noAccountYet,
                                  action: AppStrings.signUp,
                                  onTap: _toRegister,
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
