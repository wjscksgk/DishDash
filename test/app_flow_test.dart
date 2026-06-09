import 'dart:async';

import 'package:dish_dash/src/app.dart';
import 'package:dish_dash/src/app_controller.dart';
import 'package:dish_dash/src/menu_generator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMenuGenerator implements MenuGenerator {
  FakeMenuGenerator({this.fail = false, this.initializationFailures = 0});

  final bool fail;
  int initializationFailures;

  @override
  Future<String> get modelPath async => '/fake/model.litertlm';

  @override
  Future<void> initialize() async {
    if (initializationFailures > 0) {
      initializationFailures--;
      throw StateError('initialization failed');
    }
  }

  @override
  Stream<String> generate() async* {
    if (fail) throw StateError('offline');
    yield '1. 치킨\n2. 피자\n3. 떡볶이\n4. 햄버거\n5. 족발\n';
    yield '6. 보쌈\n7. 짜장면\n8. 초밥\n9. 김치찌개\n10. 돈까스';
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('moves from ready through race to result', () async {
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();
    expect(controller.stage, AppStage.ready);

    await controller.generateMenus();
    expect(controller.stage, AppStage.racing);
    expect(controller.menus, hasLength(raceMenuCount));

    controller.finishRace('치킨');
    expect(controller.stage, AppStage.result);
    expect(controller.winner, '치킨');
  });

  test('generation failure keeps the flow alive with fallback', () async {
    final controller = AppController(generator: FakeMenuGenerator(fail: true));
    await controller.initialize();
    await controller.generateMenus();

    expect(controller.stage, AppStage.racing);
    expect(controller.usingFallback, isTrue);
    expect(controller.menus, fallbackMenus.take(raceMenuCount));
    expect(controller.warning, contains('AI 생성 실패'));
  });

  test('retries initialization before generation', () async {
    final controller = AppController(
      generator: FakeMenuGenerator(initializationFailures: 1),
    );
    await controller.initialize();
    expect(controller.status, 'DEMO MODE');

    await controller.generateMenus();

    expect(controller.usingFallback, isFalse);
    expect(controller.menus, hasLength(raceMenuCount));
  });

  testWidgets('uses Material actions on Android', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();

    await tester.pumpWidget(DishDashApp(controller: controller));

    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.byType(CupertinoButton), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('uses Cupertino actions on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();

    await tester.pumpWidget(DishDashApp(controller: controller));

    expect(find.byType(CupertinoButton), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('hides streamed menu text behind a loading screen', (
    tester,
  ) async {
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();
    controller.stage = AppStage.generating;
    controller.streamedText = '1. 치킨\n2. 피자';

    await tester.pumpWidget(DishDashApp(controller: controller));

    expect(find.text('1. 치킨\n2. 피자'), findsNothing);
    expect(find.text('배달 메뉴를 생성하고 검수하는 중'), findsOneWidget);
    expect(find.text('2 / 14'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
