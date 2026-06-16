import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'app_controller.dart';
import 'delivery_launcher.dart';
import 'menu_generator.dart';
import 'race_game.dart';

const ink = Color(0xFF171612);
const cream = Color(0xFFFFF1D0);
const tomato = Color(0xFFE94F37);
const mustard = Color(0xFFF6AE2D);
const mint = Color(0xFF2EC4B6);
const panel = Color(0xFF26231D);

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
          Text('AI 엔진 로딩 중'),
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
                  color: panel,
                  border: Border.all(color: mint, width: 3),
                  boxShadow: const [
                    BoxShadow(color: ink, offset: Offset(6, 6)),
                  ],
                ),
                child: Column(
                  children: [
                    const _PlatformActivityIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      'AI 주방장, 오늘의 메뉴 조합 중!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: cream,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LinearProgressIndicator(
                      minHeight: 10,
                      color: mint,
                      backgroundColor: cream.withValues(alpha: 0.12),
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
  String? countdown = '3';
  List<RaceStanding>? _pendingStandings;
  String? _pendingCountdown;
  bool _hasPendingCountdown = false;
  bool _frameUpdateScheduled = false;

  late List<RaceStanding> standings = [
    for (var index = 0; index < widget.controller.menus.length; index++)
      RaceStanding(
        number: index + 1,
        menu: widget.controller.menus[index],
        color: racerColors[index % racerColors.length],
        progress: 0,
        rank: index + 1,
      ),
  ];

  late final DishDashGame game = DishDashGame(
    menus: widget.controller.menus,
    onStandingsChanged: _queueStandings,
    onCountdownChanged: _queueCountdown,
    onWinner: (winner) {
      Future<void>.delayed(
        const Duration(milliseconds: 800),
        () => widget.controller.finishRace(winner),
      );
    },
  );

  void _queueStandings(List<RaceStanding> nextStandings) {
    _pendingStandings = nextStandings;
    _scheduleFrameUpdate();
  }

  void _queueCountdown(String? value) {
    _pendingCountdown = value;
    _hasPendingCountdown = true;
    _scheduleFrameUpdate();
  }

  void _scheduleFrameUpdate() {
    if (_frameUpdateScheduled) return;
    _frameUpdateScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _frameUpdateScheduled = false;
      if (!mounted) return;

      final nextStandings = _pendingStandings;
      final hasCountdown = _hasPendingCountdown;
      final nextCountdown = _pendingCountdown;
      _pendingStandings = null;
      _hasPendingCountdown = false;

      setState(() {
        if (nextStandings != null) standings = nextStandings;
        if (hasCountdown) countdown = nextCountdown;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _Shell(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: Container(
            decoration: BoxDecoration(
              color: panel,
              border: Border.all(color: cream, width: 2),
            ),
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.hardEdge,
              children: [
                GameWidget(game: game),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: _RaceStandingsBoard(standings: standings),
                ),
                if (countdown != null)
                  Center(child: _RaceCountdownLabel(text: countdown!)),
              ],
            ),
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
              _PixelFrame(
                color: cream,
                borderColor: ink,
                shadowColor: ink,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 12,
                  ),
                  child: Text(
                    winner,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: ink,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _PixelFrame(
                color: panel,
                borderColor: mint,
                shadowColor: ink,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 76),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.winnerComment.isEmpty
                            ? '우승 메뉴를 위한 한마디를 만드는 중...'
                            : controller.winnerComment,
                        style: TextStyle(
                          color:
                              controller.winnerComment.isEmpty
                                  ? cream.withValues(alpha: 0.55)
                                  : cream,
                          fontSize: 16,
                          height: 1.35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                      label: '쿠팡이츠',
                      color: tomato,
                      onPressed:
                          () =>
                              openDeliveryApp(DeliveryApp.coupangEats, winner),
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

class _PixelFrame extends StatelessWidget {
  const _PixelFrame({
    required this.child,
    this.color = panel,
    this.borderColor = cream,
    this.shadowColor = tomato,
  });

  final Widget child;
  final Color color;
  final Color borderColor;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor, width: 3),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(6, 6))],
      ),
      child: child,
    );
  }
}

class _RaceStandingsBoard extends StatelessWidget {
  const _RaceStandingsBoard({required this.standings});

  final List<RaceStanding> standings;

  @override
  Widget build(BuildContext context) {
    final splitIndex = (standings.length / 2).ceil();
    final columns = [
      standings.take(splitIndex).toList(growable: false),
      standings.skip(splitIndex).toList(growable: false),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.9),
        border: Border.all(color: cream.withValues(alpha: 0.7), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (
              var columnIndex = 0;
              columnIndex < columns.length;
              columnIndex++
            ) ...[
              if (columnIndex > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: [
                    for (final standing in columns[columnIndex])
                      _StandingRow(standing: standing),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RaceCountdownLabel extends StatelessWidget {
  const _RaceCountdownLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.9),
        border: Border.all(color: mustard, width: 3),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: cream,
          fontSize: 34,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.standing});

  final RaceStanding standing;

  @override
  Widget build(BuildContext context) {
    final isWinner = standing.rank == 1;
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Container(
            width: 21,
            height: 18,
            alignment: Alignment.center,
            color: isWinner ? mustard : cream.withValues(alpha: 0.12),
            child: Text(
              '${standing.rank}',
              style: TextStyle(
                color: isWinner ? ink : cream,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: standing.color,
              border: Border.all(color: ink),
            ),
            child: Text(
              '${standing.number}',
              style: const TextStyle(
                color: ink,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              standing.menu,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isWinner ? cream : cream.withValues(alpha: 0.82),
                fontSize: 11,
                fontWeight: isWinner ? FontWeight.w900 : FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
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
    return _PixelFrame(
      color: panel,
      borderColor: ready ? mint : mustard,
      shadowColor: ink,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.square, size: 11, color: ready ? mint : mustard),
                const SizedBox(width: 8),
                Text(
                  controller.status,
                  style: TextStyle(
                    color: ready ? mint : mustard,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
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
      ),
    );
  }
}

bool get _usesCupertino => defaultTargetPlatform == TargetPlatform.iOS;

class _PlatformButton extends StatelessWidget {
  const _PlatformButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.cupertinoIcon,
    this.color = mustard,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final IconData? cupertinoIcon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final buttonIcon = _usesCupertino ? cupertinoIcon ?? icon : icon;
    if (_usesCupertino) {
      return Container(
        height: 52,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: cream, width: 3),
          boxShadow: const [BoxShadow(color: ink, offset: Offset(5, 5))],
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.zero,
          onPressed: onPressed,
          child: _ButtonContent(label: label, icon: buttonIcon, color: ink),
        ),
      );
    }

    final child = _ButtonContent(label: label, icon: icon, color: ink);
    return SizedBox(
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: ink,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
          shape: const BeveledRectangleBorder(),
          side: const BorderSide(color: cream, width: 3),
          elevation: 8,
          shadowColor: ink,
        ),
        onPressed: onPressed,
        child: child,
      ),
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
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
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

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(ink, BlendMode.src);
    final dotPaint = Paint()..color = cream.withValues(alpha: 0.06);
    const step = 16.0;
    const dot = 3.0;
    for (var x = 0.0; x < size.width; x += step) {
      for (var y = 0.0; y < size.height; y += step) {
        canvas.drawRect(Rect.fromLTWH(x, y, dot, dot), dotPaint);
      }
    }
    final glowPaint = Paint()..color = tomato.withValues(alpha: 0.035);
    for (var y = 8.0; y < size.height; y += 64) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 4), glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
