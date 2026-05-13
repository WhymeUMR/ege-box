import 'package:flutter/material.dart';

import '../../../../core/routing/app_router.dart';
import '../widgets/auth_buttons.dart';
import '../widgets/circle_header.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late final AnimationController _circleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    reverseDuration: const Duration(milliseconds: 600),
  );

  late final AnimationController _buttonsController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    reverseDuration: const Duration(milliseconds: 400),
  );

  late final Animation<Offset> _circleSlide = Tween<Offset>(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _circleController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  late final Animation<Offset> _buttonsSlide = Tween<Offset>(
    begin: const Offset(0, 0.6),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _buttonsController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  @override
  void initState() {
    super.initState();
    _playEnter();
  }

  void _playEnter() {
    _circleController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _buttonsController.forward(from: 0);
    });
  }

  Future<void> _exitAndPush(String route) async {
    // Сначала убираем кнопки, потом круг уезжает наверх.
    final buttonsExit = _buttonsController.reverse();
    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    final circleExit = _circleController.reverse();
    await Future.wait([buttonsExit, circleExit]);
    if (!mounted) return;

    await Navigator.of(context).pushNamed(route);
    // Когда возвращаемся — проигрываем приветствие заново.
    if (mounted) _playEnter();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _buttonsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Круг сверху, выезжает / заезжает обратно.
          SlideTransition(
            position: _circleSlide,
            child: const Align(
              alignment: Alignment.topCenter,
              child: CircleHeader(),
            ),
          ),
          // Кнопки прибиты к нижнему краю.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _buttonsController,
                child: SlideTransition(
                  position: _buttonsSlide,
                  child: AuthButtons(
                    onSignIn: () => _exitAndPush(AppRouter.login),
                    onSignUp: () => _exitAndPush(AppRouter.register),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
