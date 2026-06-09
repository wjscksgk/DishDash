import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'delivery_launcher.dart';
import 'menu_generator.dart';
import 'race_game.dart';

const ink = Color(0xFF171612);
const cream = Color(0xFFFFF1D0);
const tomato = Color(0xFFE94F37);
const mustard = Color(0xFFF6AE2D);
const mint = Color(0xFF2EC4B6);

class DishDashApp extends StatefulWidget {
  const DishDashApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<DishDashApp> createState() => _DishDashAppState();
}

class _DishDashAppState extends State<DishDashApp> {
  late final AppController controller = widget.controller ?? AppController();
  late final bool ownsController = widget.controller == null;

  @override
  void initState() {
    super.initState();
    if (ownsController) unawaited(controller.initialize());
  }

  @override
  void dispose() {
    if (ownsController) controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dish Dash',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: tomato,
          secondary: mustard,
          surface: Color(0xFF26231D),
        ),
        fontFamily: 'monospace',
        useMaterial3: true,
      ),
      home: AnimatedBuilder(
        animation: controller,
        builder:
            (context, _) => switch (controller.stage) {
              AppStage.booting => const _BootScreen(),
              AppStage.ready => _StartScreen(controller: controller),
              AppStage.generating => _LoadingScreen(controller: controller),
              AppStage.racing => _RaceScreen(controller: controller),
              AppStage.result => _ResultScreen(controller: controller),
            },
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) => const _Shell(
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Logo(),
          SizedBox(height: 32),
          _PlatformActivityIndicator(),
          SizedBox(height: 14),
          Text('AI ENGINE WARMING UP'),
        ],
      ),
    ),
  );
}

class _StartScreen extends StatelessWidget {
  const _StartScreen({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const _Logo(),
              const SizedBox(height: 16),
              const Text(
                '오늘 뭐 먹지?\nAI에게 맡기고, 레이스로 결정!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: cream,
                  fontSize: 19,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _StatusCard(controller: controller),
              const SizedBox(height: 18),
              _PlatformButton(
                label: 'RACE START',
                icon: Icons.flag_rounded,
                cupertinoIcon: CupertinoIcons.flag_fill,
                onPressed: controller.generateMenus,
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'AI PIT STOP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mustard,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                decoration: BoxDecoration(
                  color: cream.withValues(alpha: 0.07),
                  border: Border.all(color: mint),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const _PlatformActivityIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      '배달 메뉴를 생성하고 검수하는 중',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cream,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      minHeight: 8,
                      color: mint,
                      backgroundColor: cream.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (controller.warning != null)
                Text(
                  controller.warning!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: mustard),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RaceScreen extends StatefulWidget {
  const _RaceScreen({required this.controller});

  final AppController controller;

  @override
  State<_RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<_RaceScreen> {
  late final DishDashGame game = DishDashGame(
    menus: widget.controller.menus,
    onWinner: (winner) {
      Future<void>.delayed(
        const Duration(milliseconds: 800),
        () => widget.controller.finishRace(winner),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DISH DASH',
                    style: TextStyle(
                      color: tomato,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  _LiveBadge(),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GameWidget(game: game),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '결승선을 가장 먼저 통과한 메뉴가 오늘의 저녁!',
                style: TextStyle(color: cream),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final winner = controller.winner ?? fallbackMenus.first;
    return _Shell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.emoji_events_rounded, size: 82, color: mustard),
              const Text(
                'WINNER',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tomato,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: cream,
                  border: Border.all(color: ink, width: 3),
                  boxShadow: const [
                    BoxShadow(color: tomato, offset: Offset(8, 8)),
                  ],
                ),
                child: Text(
                  winner,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: ink,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                '주문할 앱을 선택하세요',
                textAlign: TextAlign.center,
                style: TextStyle(color: cream, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PlatformButton(
                      label: '배민',
                      color: mint,
                      onPressed:
                          () => openDeliveryApp(DeliveryApp.baemin, winner),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PlatformButton(
                      label: '요기요',
                      color: tomato,
                      onPressed:
                          () => openDeliveryApp(DeliveryApp.yogiyo, winner),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _PlatformButton(
                      emphasis: _ButtonEmphasis.secondary,
                      onPressed: controller.replay,
                      label: '같은 메뉴 재경주',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PlatformButton(
                      emphasis: _ButtonEmphasis.secondary,
                      onPressed: controller.regenerate,
                      label: '새 메뉴 생성',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [CustomPaint(painter: _GridPainter()), child],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.04,
          child: const Text(
            'DISH',
            style: TextStyle(
              color: cream,
              fontSize: 58,
              height: 0.9,
              fontWeight: FontWeight.w900,
              letterSpacing: -4,
            ),
          ),
        ),
        Transform.rotate(
          angle: 0.025,
          child: const Text(
            'DASH',
            style: TextStyle(
              color: tomato,
              fontSize: 68,
              height: 0.9,
              fontWeight: FontWeight.w900,
              letterSpacing: -5,
              shadows: [Shadow(color: mustard, offset: Offset(4, 4))],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final ready = controller.warning == null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cream.withValues(alpha: 0.07),
        border: Border.all(color: ready ? mint : mustard),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 11, color: ready ? mint : mustard),
              const SizedBox(width: 8),
              Text(
                controller.status,
                style: TextStyle(
                  color: ready ? mint : mustard,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (!ready) ...[
            const SizedBox(height: 8),
            const Text('모델이 없어도 데모 메뉴로 레이스를 시작할 수 있습니다.'),
            const SizedBox(height: 5),
            SelectableText(
              controller.modelPath ?? '',
              style: const TextStyle(color: cream, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ButtonEmphasis { primary, secondary }

bool get _usesCupertino => defaultTargetPlatform == TargetPlatform.iOS;

class _PlatformButton extends StatelessWidget {
  const _PlatformButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.cupertinoIcon,
    this.color = mustard,
    this.emphasis = _ButtonEmphasis.primary,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? cupertinoIcon;
  final Color color;
  final _ButtonEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    if (_usesCupertino) {
      final buttonIcon = cupertinoIcon ?? icon;
      return SizedBox(
        height: 52,
        child: CupertinoButton(
          color: emphasis == _ButtonEmphasis.primary ? color : null,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          onPressed: onPressed,
          child: _ButtonContent(
            label: label,
            icon: buttonIcon,
            color: emphasis == _ButtonEmphasis.primary ? ink : cream,
          ),
        ),
      );
    }

    final child = _ButtonContent(
      label: label,
      icon: icon,
      color: emphasis == _ButtonEmphasis.primary ? ink : null,
    );
    return SizedBox(
      height: 52,
      child:
          emphasis == _ButtonEmphasis.primary
              ? FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: ink,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onPressed: onPressed,
                child: child,
              )
              : OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _PlatformActivityIndicator extends StatelessWidget {
  const _PlatformActivityIndicator();

  @override
  Widget build(BuildContext context) {
    if (_usesCupertino) {
      return const CupertinoActivityIndicator(color: mustard, radius: 14);
    }
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(color: mustard, strokeWidth: 3),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: tomato,
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text('● LIVE', style: TextStyle(fontWeight: FontWeight.w900)),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = cream.withValues(alpha: 0.035)
          ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
