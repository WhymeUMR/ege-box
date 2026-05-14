import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/pill_button.dart';

class AuthButtons extends StatelessWidget {
  const AuthButtons({
    super.key,
    required this.onSignIn,
    required this.onSignUp,
  });

  final VoidCallback onSignIn;
  final VoidCallback onSignUp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 0, 30, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillPrimaryButton(label: AppStrings.signIn, onPressed: onSignIn),
          const SizedBox(height: 18),
          PillOutlinedButton(label: AppStrings.signUp, onPressed: onSignUp),
        ],
      ),
    );
  }
}
