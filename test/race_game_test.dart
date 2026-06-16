import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dish_dash/src/race_game.dart';

void main() {
  Racer buildRacer({
    required int number,
    required String menu,
    required double x,
    required double y,
    double startY = 1000,
    double finishY = 100,
    ValueChanged<String>? onFinish,
  }) {
    return Racer(
      number: number,
      menu: menu,
      color: racerColors[(number - 1) % racerColors.length],
      random: Random(number),
      startY: startY,
      finishY: finishY,
      onFinish: onFinish ?? (_) {},
      position: Vector2(x, y),
      size: Vector2(32, 50),
    );
  }

  test('racer moves upward without changing lanes', () {
    var finishCount = 0;
    final racer = buildRacer(
      number: 1,
      menu: '치킨',
      x: 20,
      y: 800,
      onFinish: (_) => finishCount++,
    );

    racer.update(0.5);

    expect(racer.position.x, 20);
    expect(racer.position.y, lessThan(800));
    expect(finishCount, 0);
  });

  test('racer finishes at the top boundary only once', () {
    String? winner;
    var finishCount = 0;
    final racer = buildRacer(
      number: 2,
      menu: '떡볶이',
      x: 20,
      y: 110,
      onFinish: (menu) {
        winner = menu;
        finishCount++;
      },
    );

    racer.update(0.5);
    racer.update(0.5);

    expect(winner, '떡볶이');
    expect(racer.position.y, 100);
    expect(finishCount, 1);
  });

  test('standings reorder after an overtake and keep stable ties', () {
    final racers = [
      buildRacer(number: 1, menu: '치킨', x: 10, y: 700),
      buildRacer(number: 2, menu: '피자', x: 50, y: 500),
      buildRacer(number: 3, menu: '족발', x: 90, y: 700),
    ];

    final standings = buildRaceStandings(racers);

    expect(standings.map((standing) => standing.number), [2, 1, 3]);
    expect(standings.map((standing) => standing.rank), [1, 2, 3]);
  });

  test('standings keep finished racers in finish order', () {
    final racers = [
      buildRacer(number: 5, menu: '초밥', x: 10, y: 100),
      buildRacer(number: 2, menu: '피자', x: 50, y: 100),
      buildRacer(number: 7, menu: '돈까스', x: 90, y: 300),
      buildRacer(number: 4, menu: '파스타', x: 130, y: 180),
    ];

    final standings = buildRaceStandings(racers, finishOrder: ['초밥', '피자']);

    expect(standings.map((standing) => standing.number), [5, 2, 4, 7]);
    expect(standings.map((standing) => standing.rank), [1, 2, 3, 4]);
  });

  test(
    'camera target follows the average position of the top three racers',
    () {
      final racers = [
        buildRacer(number: 1, menu: '치킨', x: 10, y: 520),
        buildRacer(number: 2, menu: '피자', x: 50, y: 300),
        buildRacer(number: 3, menu: '족발', x: 90, y: 380),
        buildRacer(number: 4, menu: '파스타', x: 130, y: 700),
      ];

      expect(calculateLeaderTargetY(racers), 400);
    },
  );
}
