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
    final finishY = size.y - 26;
    final racerWidth = min(34.0, laneWidth * 0.62);
    final racerHeight = min(82.0, max(66.0, racerWidth * 2.25));
    add(FinishLine(position: Vector2(0, finishY), size: Vector2(size.x, 8)));

    for (var index = 0; index < menus.length; index++) {
      final laneLeft = laneWidth * index;
      add(
        Racer(
          menu: menus[index],
          color: racerColors[index % racerColors.length],
          random: random,
          position: Vector2(laneLeft + (laneWidth - racerWidth) / 2, 8),
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
    pauseEngine();
    onWinner(menu);
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

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    _changeTimer -= dt;
    if (_changeTimer <= 0) {
      _changeTimer = 0.2 + random.nextDouble() * 0.15;
      speed = 42 + random.nextDouble() * 52;
    }
    position.y += speed * dt;
    if (position.y + size.y >= maxY) onFinish(menu);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      paint,
    );
    final label = TextPainter(
      text: TextSpan(
        text: menu,
        style: const TextStyle(
          color: Color(0xFF171612),
          fontWeight: FontWeight.w900,
          fontSize: 10,
          height: 1.05,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 6,
      ellipsis: '…',
    )..layout(maxWidth: max(0.0, size.x - 6));
    label.paint(
      canvas,
      Offset(
        (size.x - label.width) / 2,
        max(4.0, (size.y - label.height) / 2 - 6),
      ),
    );
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
    const cell = 8.0;
    for (var x = 0.0; x < size.x; x += cell) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, cell, size.y),
        Paint()
          ..color =
              ((x / cell).floor().isEven)
                  ? const Color(0xFFFFF1D0)
                  : const Color(0xFF171612),
      );
    }
  }
}
