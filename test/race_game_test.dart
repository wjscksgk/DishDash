import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dish_dash/src/race_game.dart';

void main() {
  test('racer moves downward without changing lanes', () {
    var finishCount = 0;
    final racer = Racer(
      menu: '치킨',
      color: Colors.red,
      random: Random(1),
      maxY: 1000,
      onFinish: (_) => finishCount++,
      position: Vector2(20, 8),
      size: Vector2(40, 80),
    );

    racer.update(0.5);

    expect(racer.position.x, 20);
    expect(racer.position.y, greaterThan(8));
    expect(finishCount, 0);
  });

  test('racer finishes at the bottom boundary', () {
    String? winner;
    final racer = Racer(
      menu: '떡볶이',
      color: Colors.red,
      random: Random(1),
      maxY: 100,
      onFinish: (menu) => winner = menu,
      position: Vector2(20, 30),
      size: Vector2(40, 60),
    );

    racer.update(0.5);

    expect(winner, '떡볶이');
  });
}
