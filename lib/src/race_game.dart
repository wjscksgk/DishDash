import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

const racerColors = <Color>[
  Color(0xFFE94F37),
  Color(0xFFF6AE2D),
  Color(0xFF2EC4B6),
  Color(0xFF5B8DEF),
  Color(0xFFF78FB3),
  Color(0xFF9B5DE5),
  Color(0xFFFF7F11),
  Color(0xFF00A6A6),
  Color(0xFFE84855),
  Color(0xFF7CB518),
];

@immutable
class RaceStanding {
  const RaceStanding({
    required this.number,
    required this.menu,
    required this.color,
    required this.progress,
    required this.rank,
  });

  final int number;
  final String menu;
  final Color color;
  final double progress;
  final int rank;
}

List<RaceStanding> buildRaceStandings(
  Iterable<Racer> racers, {
  List<String> finishOrder = const [],
}) {
  final finishRanks = {
    for (var index = 0; index < finishOrder.length; index++)
      finishOrder[index]: index,
  };
  final ordered =
      racers.toList()..sort((a, b) {
        final aFinishRank = finishRanks[a.menu];
        final bFinishRank = finishRanks[b.menu];
        if (aFinishRank != null || bFinishRank != null) {
          if (aFinishRank == null) return 1;
          if (bFinishRank == null) return -1;
          final finishOrder = aFinishRank.compareTo(bFinishRank);
          if (finishOrder != 0) return finishOrder;
        }
        final progressOrder = b.progress.compareTo(a.progress);
        return progressOrder != 0
            ? progressOrder
            : a.number.compareTo(b.number);
      });
  return List.unmodifiable([
    for (var index = 0; index < ordered.length; index++)
      RaceStanding(
        number: ordered[index].number,
        menu: ordered[index].menu,
        color: ordered[index].color,
        progress: ordered[index].progress,
        rank: index + 1,
      ),
  ]);
}

double calculateLeaderTargetY(Iterable<Racer> racers) {
  final leaders =
      racers.toList()..sort((a, b) => a.position.y.compareTo(b.position.y));
  final leaderCount = min(3, leaders.length);
  if (leaderCount == 0) return 0;
  return leaders
          .take(leaderCount)
          .fold<double>(0, (total, racer) => total + racer.position.y) /
      leaderCount;
}

class DishDashGame extends FlameGame with HasCollisionDetection {
  DishDashGame({
    required this.menus,
    required this.onWinner,
    this.onStandingsChanged,
    this.onCountdownChanged,
    this.onRaceComplete,
    int? seed,
  }) : random = Random(seed);

  final List<String> menus;
  final ValueChanged<String> onWinner;
  final ValueChanged<List<RaceStanding>>? onStandingsChanged;
  final ValueChanged<String?>? onCountdownChanged;
  final VoidCallback? onRaceComplete;
  final Random random;

  final List<Racer> _racers = [];
  final List<String> _finishOrder = [];
  late final PositionComponent _cameraTarget;
  late double _worldHeight;
  late double _startY;
  late double _finishY;
  double _standingsTimer = 0;
  double _countdownRemaining = 1.8;
  double _goTimer = 0;
  int _countdownStep = 3;
  bool _raceStarted = false;

  List<RaceStanding> get standings => _buildStandings();
  double get cameraTargetY => _cameraTarget.position.y;
  double get worldHeight => _worldHeight;

  @override
  Color backgroundColor() => const Color(0xFF171612);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _worldHeight = max(size.y * 2.25, 1360);
    _finishY = 190;
    _startY = _worldHeight - 112;

    final laneWidth = size.x / menus.length;
    final racerWidth = min(34.0, laneWidth * 0.76);
    final racerHeight = racerWidth * 1.55;

    await world.add(
      TrackBackground(
        menuCount: menus.length,
        size: Vector2(size.x, _worldHeight),
      ),
    );
    await world.add(
      FinishLine(
        position: Vector2(0, _finishY - 13),
        size: Vector2(size.x, 26),
      ),
    );
    await world.add(
      StartLine(
        position: Vector2(0, _startY + racerHeight + 8),
        size: Vector2(size.x, 10),
      ),
    );

    for (var index = 0; index < menus.length; index++) {
      final laneLeft = laneWidth * index;
      final racer = Racer(
        number: index + 1,
        menu: menus[index],
        color: racerColors[index % racerColors.length],
        random: random,
        startY: _startY,
        finishY: _finishY,
        isRunning: false,
        position: Vector2(
          laneLeft + (laneWidth - racerWidth) / 2,
          _startY + (index.isEven ? 4 : 0),
        ),
        size: Vector2(racerWidth, racerHeight),
        onFinish: _finish,
      );
      _racers.add(racer);
      await world.add(racer);
    }

    _cameraTarget = PositionComponent(
      position: Vector2(size.x / 2, _startY),
      size: Vector2.zero(),
    );
    await world.add(_cameraTarget);

    camera.viewfinder
      ..anchor = Anchor.center
      ..position = _cameraTarget.position;
    camera.setBounds(
      Rectangle.fromLTWH(0, 0, size.x, _worldHeight),
      considerViewport: true,
    );
    camera.follow(_cameraTarget, maxSpeed: 540, verticalOnly: true, snap: true);
    onCountdownChanged?.call('3');
    _notifyStandings();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_racers.isEmpty) return;

    if (!_raceStarted) {
      _updateCountdown(dt);
      return;
    }
    if (_goTimer > 0) {
      _goTimer -= dt;
      if (_goTimer <= 0) onCountdownChanged?.call(null);
    }

    _cameraTarget.position.y = calculateLeaderTargetY(_racers);

    _standingsTimer -= dt;
    if (_standingsTimer <= 0) {
      _standingsTimer = 0.2;
      _notifyStandings();
    }
  }

  List<RaceStanding> _buildStandings() =>
      buildRaceStandings(_racers, finishOrder: _finishOrder);

  void _updateCountdown(double dt) {
    _countdownRemaining -= dt;
    final nextStep = max(1, (_countdownRemaining / 0.6).ceil());
    if (_countdownRemaining > 0 && nextStep != _countdownStep) {
      _countdownStep = nextStep;
      onCountdownChanged?.call('$nextStep');
    }
    if (_countdownRemaining > 0) return;

    _raceStarted = true;
    _goTimer = 0.55;
    for (final racer in _racers) {
      racer.isRunning = true;
    }
    onCountdownChanged?.call('GO!');
  }

  void _notifyStandings() {
    onStandingsChanged?.call(_buildStandings());
  }

  void _finish(String menu) {
    if (_finishOrder.contains(menu)) return;
    _finishOrder.add(menu);
    _notifyStandings();
    if (_finishOrder.length == 1) onWinner(menu);
    if (_finishOrder.length == _racers.length) onRaceComplete?.call();
  }
}

class TrackBackground extends PositionComponent {
  TrackBackground({required this.menuCount, required super.size});

  final int menuCount;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final asphaltPaint = Paint()..color = const Color(0xFF24221D);
    final texturePaint =
        Paint()..color = const Color(0xFFFFF1D0).withValues(alpha: 0.025);
    final lanePaint =
        Paint()
          ..color = const Color(0xFFFFF1D0).withValues(alpha: 0.2)
          ..strokeWidth = 1.5;
    final curbCream = Paint()..color = const Color(0xFFFFF1D0);
    final curbTomato = Paint()..color = const Color(0xFFE94F37);

    canvas.drawRect(size.toRect(), asphaltPaint);

    for (var x = 18.0; x < size.x; x += 32) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.y), texturePaint);
    }

    const curbWidth = 7.0;
    const curbLength = 24.0;
    for (var y = 0.0; y < size.y; y += curbLength) {
      final paint = (y / curbLength).floor().isEven ? curbCream : curbTomato;
      canvas.drawRect(Rect.fromLTWH(0, y, curbWidth, curbLength), paint);
      canvas.drawRect(
        Rect.fromLTWH(size.x - curbWidth, y, curbWidth, curbLength),
        paint,
      );
    }

    final laneWidth = size.x / menuCount;
    for (var lane = 1; lane < menuCount; lane++) {
      final x = laneWidth * lane;
      for (var y = 18.0; y < size.y; y += 42) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 15), lanePaint);
      }
    }
  }
}

class Racer extends PositionComponent with CollisionCallbacks {
  Racer({
    required this.number,
    required this.menu,
    required this.color,
    required this.random,
    required this.startY,
    required this.finishY,
    this.isRunning = true,
    required this.onFinish,
    required super.position,
    required super.size,
  });

  final int number;
  final String menu;
  final Color color;
  final Random random;
  final double startY;
  final double finishY;
  final ValueChanged<String> onFinish;
  bool isRunning;
  double speed = 132;
  double _changeTimer = 0;
  double _driveTime = 0;
  double _celebrationTimer = 0;
  bool _finished = false;

  double get progress =>
      ((startY - position.y) / (startY - finishY)).clamp(0.0, 1.0);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _driveTime += dt;
    if (_celebrationTimer > 0) {
      _celebrationTimer = max(0, _celebrationTimer - dt);
    }
    if (_finished || !isRunning) return;

    _changeTimer -= dt;
    if (_changeTimer <= 0) {
      _changeTimer = 0.35 + random.nextDouble() * 0.25;
      speed = 118 + random.nextDouble() * 70;
    }

    position.y -= speed * dt;
    angle = sin(_driveTime * 8 + number) * 0.025;
    if (position.y <= finishY) {
      position.y = finishY;
      _finished = true;
      _celebrationTimer = 0.8;
      scale = Vector2.all(1.08);
      onFinish(menu);
    }
  }

  @override
  void render(Canvas canvas) {
    final bounce = sin(_driveTime * 13 + number) * 1.2;
    canvas.save();
    canvas.translate(0, bounce);
    _drawSpeedLines(canvas);
    _drawFoodKart(canvas);
    canvas.restore();
    if (_celebrationTimer > 0) _drawWinnerBurst(canvas);
  }

  void _drawSpeedLines(Canvas canvas) {
    final linePaint =
        Paint()
          ..color = color.withValues(alpha: 0.38)
          ..strokeWidth = 2;
    for (var i = 0; i < 2; i++) {
      final y = size.y + 5 + i * 9 + sin(_driveTime * 16 + i) * 2;
      canvas.drawLine(
        Offset(size.x * 0.28, y),
        Offset(size.x * 0.28, y + 7),
        linePaint,
      );
      canvas.drawLine(
        Offset(size.x * 0.72, y),
        Offset(size.x * 0.72, y + 7),
        linePaint,
      );
    }
  }

  void _drawFoodKart(Canvas canvas) {
    final outline = Paint()..color = const Color(0xFF171612);
    final bodyPaint = Paint()..color = color;
    final creamPaint = Paint()..color = const Color(0xFFFFF1D0);
    final mustardPaint = Paint()..color = const Color(0xFFF6AE2D);

    final tray = Rect.fromLTWH(size.x * 0.16, 0, size.x * 0.68, size.y * 0.2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(tray.inflate(2), const Radius.circular(3)),
      outline,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tray, const Radius.circular(2)),
      number.isEven ? mustardPaint : creamPaint,
    );
    canvas.drawCircle(
      Offset(size.x / 2, tray.center.dy),
      size.x * 0.12,
      bodyPaint,
    );

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, size.y * 0.16, size.x - 2, size.y * 0.62),
      const Radius.circular(5),
    );
    canvas.drawRRect(body.inflate(2), outline);
    canvas.drawRRect(body, bodyPaint);

    final stripe = Rect.fromLTWH(
      size.x * 0.12,
      size.y * 0.24,
      size.x * 0.76,
      size.y * 0.1,
    );
    canvas.drawRect(stripe, creamPaint);

    final numberDisc = Offset(size.x / 2, size.y * 0.54);
    canvas.drawCircle(numberDisc, size.x * 0.29, outline);
    canvas.drawCircle(numberDisc, size.x * 0.23, creamPaint);
    _paintNumber(canvas, numberDisc);

    final wheelPaint = Paint()..color = const Color(0xFF0D0C0A);
    for (final x in [size.x * 0.12, size.x * 0.88]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, size.y * 0.78),
            width: size.x * 0.22,
            height: size.y * 0.2,
          ),
          const Radius.circular(2),
        ),
        wheelPaint,
      );
    }
  }

  void _paintNumber(Canvas canvas, Offset center) {
    final painter = TextPainter(
      text: TextSpan(
        text: '$number',
        style: TextStyle(
          color: const Color(0xFF171612),
          fontSize: number == 10 ? size.x * 0.31 : size.x * 0.42,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(center.dx - painter.width / 2, center.dy - painter.height / 2),
    );
  }

  void _drawWinnerBurst(Canvas canvas) {
    final progress = 1 - (_celebrationTimer / 0.8);
    final burstPaint = Paint()..color = const Color(0xFFF6AE2D);
    final center = Offset(size.x / 2, size.y * 0.35);
    for (var i = 0; i < 10; i++) {
      final burstAngle = (pi * 2 / 10) * i;
      final distance = 10 + progress * 24;
      final star = Offset(
        center.dx + cos(burstAngle) * distance,
        center.dy + sin(burstAngle) * distance,
      );
      canvas.drawRect(
        Rect.fromCenter(center: star, width: 5, height: 5),
        burstPaint,
      );
    }
  }
}

class StartLine extends PositionComponent {
  StartLine({required super.position, required super.size});

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      size.toRect(),
      Paint()..color = const Color(0xFF2EC4B6).withValues(alpha: 0.75),
    );
  }
}

class FinishLine extends PositionComponent with CollisionCallbacks {
  FinishLine({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void render(Canvas canvas) {
    const cell = 13.0;
    canvas.drawRect(
      Rect.fromLTWH(0, -4, size.x, size.y + 8),
      Paint()..color = const Color(0xFFE94F37),
    );
    for (var x = 0.0; x < size.x; x += cell) {
      for (var y = 0.0; y < size.y; y += cell) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, cell, cell),
          Paint()
            ..color =
                ((x / cell).floor() + (y / cell).floor()).isEven
                    ? const Color(0xFFFFF1D0)
                    : const Color(0xFF171612),
        );
      }
    }
  }
}
