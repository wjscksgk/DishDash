import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
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

class DishDashGame extends FlameGame with HasCollisionDetection {
  DishDashGame({required this.menus, required this.onWinner, int? seed})
    : random = Random(seed);

  final List<String> menus;
  final ValueChanged<String> onWinner;
  final Random random;
  bool _finished = false;

  @override
  Color backgroundColor() => const Color(0xFF171612);

  @override
  Future<void> onLoad() async {
    final laneWidth = size.x / menus.length;
    final finishY = size.y - 34;
    final racerWidth = min(40.0, laneWidth * 0.72);
    final racerHeight = min(88.0, max(70.0, racerWidth * 2.2));
    add(TrackBackground(menuCount: menus.length, size: size));
    add(FinishLine(position: Vector2(0, finishY), size: Vector2(size.x, 16)));

    for (var index = 0; index < menus.length; index++) {
      final laneLeft = laneWidth * index;
      add(
        Racer(
          menu: menus[index],
          color: racerColors[index % racerColors.length],
          random: random,
          position: Vector2(laneLeft + (laneWidth - racerWidth) / 2, 18),
          size: Vector2(racerWidth, racerHeight),
          maxY: finishY,
          onFinish: _finish,
        ),
      );
    }
  }

  void _finish(String menu) {
    if (_finished) return;
    _finished = true;
    onWinner(menu);
  }
}

class TrackBackground extends PositionComponent {
  TrackBackground({required this.menuCount, required super.size});

  final int menuCount;

  @override
  void render(Canvas canvas) {
    final trackPaint = Paint()..color = const Color(0xFF211F1A);
    final tilePaint = Paint()..color = const Color(0xFF2C2922);
    final railPaint = Paint()..color = const Color(0xFFE94F37);
    final lanePaint =
        Paint()
          ..color = const Color(0xFFFFF1D0).withValues(alpha: 0.42)
          ..strokeWidth = 2;
    final mintPaint = Paint()..color = const Color(0xFF2EC4B6);

    canvas.drawRect(size.toRect(), trackPaint);

    const tile = 16.0;
    for (var y = 0.0; y < size.y; y += tile) {
      for (var x = 0.0; x < size.x; x += tile) {
        if (((x / tile).floor() + (y / tile).floor()).isEven) {
          canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), tilePaint);
        }
      }
    }

    const railWidth = 10.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, railWidth, size.y), railPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.x - railWidth, 0, railWidth, size.y),
      railPaint,
    );
    for (var y = 8.0; y < size.y; y += 26) {
      canvas.drawRect(Rect.fromLTWH(2, y, 6, 8), mintPaint);
      canvas.drawRect(Rect.fromLTWH(size.x - 8, y + 13, 6, 8), mintPaint);
    }

    final laneWidth = size.x / menuCount;
    for (var lane = 1; lane < menuCount; lane++) {
      final x = laneWidth * lane;
      for (var y = 8.0; y < size.y; y += 24) {
        canvas.drawLine(Offset(x, y), Offset(x, y + 10), lanePaint);
      }
    }
  }
}

class Racer extends PositionComponent with CollisionCallbacks {
  Racer({
    required this.menu,
    required this.color,
    required this.random,
    required this.maxY,
    required this.onFinish,
    required super.position,
    required super.size,
  });

  final String menu;
  final Color color;
  final Random random;
  final double maxY;
  final ValueChanged<String> onFinish;
  double speed = 50;
  double _changeTimer = 0;
  double _driveTime = 0;
  double _celebrationTimer = 0;
  bool _finished = false;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _driveTime += dt;
    if (_celebrationTimer > 0) {
      _celebrationTimer = max(0, _celebrationTimer - dt);
    }
    if (_finished) return;
    _changeTimer -= dt;
    if (_changeTimer <= 0) {
      _changeTimer = 0.2 + random.nextDouble() * 0.15;
      speed = 42 + random.nextDouble() * 52;
    }
    position.y += speed * dt;
    if (position.y + size.y >= maxY) {
      position.y = maxY - size.y;
      _finished = true;
      _celebrationTimer = 0.8;
      onFinish(menu);
    }
  }

  @override
  void render(Canvas canvas) {
    final wobble = sin(_driveTime * 14) * 2;
    canvas.save();
    canvas.translate(0, wobble);
    _drawSpeedLines(canvas);
    _drawFoodTruck(canvas);
    canvas.restore();
    if (_celebrationTimer > 0) _drawWinnerBurst(canvas);
  }

  void _drawSpeedLines(Canvas canvas) {
    final linePaint =
        Paint()
          ..color = const Color(0xFFFFF1D0).withValues(alpha: 0.5)
          ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final y = -8.0 - i * 12 + sin(_driveTime * 18 + i) * 3;
      canvas.drawLine(Offset(size.x * 0.25, y), Offset(size.x * 0.75, y - 8), linePaint);
    }
  }

  void _drawFoodTruck(Canvas canvas) {
    final outline = Paint()..color = const Color(0xFF171612);
    final body = Paint()..color = color;
    final creamPaint = Paint()..color = const Color(0xFFFFF1D0);
    final mintPaint = Paint()..color = const Color(0xFF2EC4B6);
    final tomatoPaint = Paint()..color = const Color(0xFFE94F37);

    final truck = Rect.fromLTWH(0, size.y * 0.18, size.x, size.y * 0.54);
    canvas.drawRect(truck.inflate(2), outline);
    canvas.drawRect(truck, body);

    final cab = Rect.fromLTWH(size.x * 0.08, truck.top + 6, size.x * 0.34, 20);
    canvas.drawRect(cab, mintPaint);
    canvas.drawRect(cab.deflate(3), creamPaint);
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.5, truck.top + 8, size.x * 0.34, 8),
      creamPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.x * 0.5, truck.top + 20, size.x * 0.26, 8),
      tomatoPaint,
    );

    final awningTop = truck.top - 8;
    for (var x = 3.0; x < size.x - 3; x += 8) {
      canvas.drawRect(
        Rect.fromLTWH(x, awningTop, 6, 8),
        ((x / 8).floor().isEven) ? creamPaint : tomatoPaint,
      );
    }

    final wheelY = truck.bottom + 2;
    for (final wheelX in [size.x * 0.24, size.x * 0.74]) {
      canvas.drawRect(Rect.fromCircle(center: Offset(wheelX, wheelY), radius: 6), outline);
      canvas.drawRect(
        Rect.fromCircle(center: Offset(wheelX, wheelY), radius: 3),
        creamPaint,
      );
    }

    final labelRect = Rect.fromLTWH(2, size.y * 0.72, size.x - 4, size.y * 0.25);
    canvas.drawRect(labelRect.inflate(2), outline);
    canvas.drawRect(labelRect, creamPaint);
    final label = TextPainter(
      text: TextSpan(
        text: menu,
        style: const TextStyle(
          color: Color(0xFF171612),
          fontWeight: FontWeight.w900,
          fontSize: 9,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: max(0.0, labelRect.width - 4));
    label.paint(
      canvas,
      Offset(
        (size.x - label.width) / 2,
        labelRect.top + max(0, (labelRect.height - label.height) / 2),
      ),
    );
  }

  void _drawWinnerBurst(Canvas canvas) {
    final progress = 1 - (_celebrationTimer / 0.8);
    final burstPaint = Paint()..color = const Color(0xFFF6AE2D);
    final center = Offset(size.x / 2, size.y * 0.25);
    for (var i = 0; i < 8; i++) {
      final angle = (pi * 2 / 8) * i;
      final distance = 8 + progress * 18;
      final star = Offset(
        center.dx + cos(angle) * distance,
        center.dy + sin(angle) * distance,
      );
      canvas.drawRect(Rect.fromCenter(center: star, width: 5, height: 5), burstPaint);
    }
  }
}

class FinishLine extends PositionComponent with CollisionCallbacks {
  FinishLine({required super.position, required super.size});

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void render(Canvas canvas) {
    const cell = 10.0;
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
