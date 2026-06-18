import 'dart:async';

import 'package:dish_dash/src/app.dart';
import 'package:dish_dash/src/app_controller.dart';
import 'package:dish_dash/src/menu_generator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMenuGenerator implements MenuGenerator {
  FakeMenuGenerator({
    this.fail = false,
    this.failWinnerComment = false,
    this.initializationFailures = 0,
  });

  final bool fail;
  final bool failWinnerComment;
  int initializationFailures;
  MenuCategory? lastGeneratedCategory;

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
  Stream<String> generate(MenuCategory category) async* {
    lastGeneratedCategory = category;
    if (fail) throw StateError('offline');
    yield '1. 치킨\n2. 피자\n3. 떡볶이\n4. 햄버거\n5. 족발\n';
    yield '6. 보쌈\n7. 짜장면\n8. 초밥\n9. 김치찌개\n10. 돈까스';
  }

  @override
  Stream<String> generateWinnerComment(String menu) async* {
    if (failWinnerComment) throw StateError('comment offline');
    yield '오늘 메뉴는 ';
    yield '$menu, 확정!';
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
    await Future<void>.delayed(Duration.zero);
    expect(controller.winnerComment, '오늘 메뉴는 치킨, 확정!');
    expect(controller.isGeneratingWinnerComment, isFalse);
  });

  test(
    'winner comment failure uses a fallback without blocking result',
    () async {
      final controller = AppController(
        generator: FakeMenuGenerator(failWinnerComment: true),
      );
      await controller.initialize();
      await controller.generateMenus();

      controller.finishRace('피자');
      expect(controller.stage, AppStage.result);
      await Future<void>.delayed(Duration.zero);

      expect(controller.winnerComment, '피자 특유의 맛과 식감, 생각만 해도 맛있겠네요.');
      expect(controller.isGeneratingWinnerComment, isFalse);
    },
  );

  test('generation failure keeps the flow alive with fallback', () async {
    final controller = AppController(generator: FakeMenuGenerator(fail: true));
    await controller.initialize();
    await controller.generateMenus();

    expect(controller.stage, AppStage.racing);
    expect(controller.usingFallback, isTrue);
    expect(
      controller.menus,
      defaultMenuCategory.fallbackMenus.take(raceMenuCount),
    );
    expect(controller.warning, contains('AI 생성 실패'));
  });

  test('passes the selected category into menu generation', () async {
    final generator = FakeMenuGenerator();
    final controller = AppController(generator: generator);
    await controller.initialize();

    final category = menuCategories.firstWhere(
      (category) => category.id == 'japanese',
    );
    controller.selectCategory(category);
    await controller.generateMenus();

    expect(generator.lastGeneratedCategory, category);
  });

  test('generation failure uses selected category fallback menus', () async {
    final controller = AppController(generator: FakeMenuGenerator(fail: true));
    await controller.initialize();
    final category = menuCategories.firstWhere(
      (category) => category.id == 'southeast_asian',
    );
    controller.selectCategory(category);

    await controller.generateMenus();

    expect(controller.stage, AppStage.racing);
    expect(controller.usingFallback, isTrue);
    expect(controller.menus, category.fallbackMenus.take(raceMenuCount));
  });

  test('preview generation keeps the app ready and records menus', () async {
    final generator = FakeMenuGenerator();
    final controller = AppController(generator: generator);
    await controller.initialize();
    final category = menuCategories.firstWhere(
      (category) => category.id == 'japanese',
    );
    controller.selectCategory(category);

    await controller.previewMenusForSelectedCategory();

    expect(controller.stage, AppStage.ready);
    expect(generator.lastGeneratedCategory, category);
    expect(controller.previewMenus, hasLength(raceMenuCount));
    expect(controller.previewText, contains('1. 치킨'));
    expect(controller.previewText, contains('7. 짜장면'));
    expect(controller.isPreviewGenerating, isFalse);
  });

  test('preview generation failure uses selected category fallback', () async {
    final controller = AppController(generator: FakeMenuGenerator(fail: true));
    await controller.initialize();
    final category = menuCategories.firstWhere(
      (category) => category.id == 'dessert_cafe',
    );
    controller.selectCategory(category);

    await controller.previewMenusForSelectedCategory();

    expect(controller.stage, AppStage.ready);
    expect(controller.previewUsingFallback, isTrue);
    expect(controller.previewMenus, category.fallbackMenus.take(raceMenuCount));
    expect(controller.previewWarning, contains('AI 생성 실패'));
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

    expect(find.byType(FilledButton), findsNWidgets(2));
    expect(find.byType(CupertinoButton), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('uses Cupertino actions on iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();

    await tester.pumpWidget(DishDashApp(controller: controller));

    expect(find.byType(CupertinoButton), findsNWidgets(2));
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
    expect(find.text('AI 주방장, 오늘의 메뉴 조합 중!'), findsOneWidget);
    expect(find.text('2 / 14'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('start screen offers ten fixed menu categories', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();

    await tester.pumpWidget(DishDashApp(controller: controller));

    for (final category in menuCategories) {
      expect(find.text(category.label), findsOneWidget);
    }
    expect(find.text('CATEGORY SELECT'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu test button shows generated menus on the start screen', (
    tester,
  ) async {
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();

    await tester.pumpWidget(DishDashApp(controller: controller));
    expect(find.text('MENU TEST'), findsOneWidget);

    controller.previewMenus = fallbackMenus.take(raceMenuCount).toList();
    controller.previewText = '1. 치킨\n2. 피자';
    controller.notifyListeners();
    await tester.pump();

    expect(controller.stage, AppStage.ready);
    expect(find.text('MENU TEST · 국/찌개/탕'), findsOneWidget);
    expect(find.text('COPY'), findsOneWidget);
    expect(find.text('치킨'), findsOneWidget);
    expect(find.text('짜장면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('race screen shows generated standings on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController(generator: FakeMenuGenerator());
    controller.stage = AppStage.racing;
    controller.menus = fallbackMenus.take(raceMenuCount).toList();

    await tester.pumpWidget(DishDashApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 650));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    for (final menu in controller.menus) {
      expect(find.text(menu), findsOneWidget);
    }
    expect(find.text('DISH DASH CUP'), findsNothing);
    expect(find.text('● LIVE'), findsNothing);
    expect(find.text('결승선을 가장 먼저 통과한 메뉴가 오늘의 저녁!'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('result only offers delivery app actions', (tester) async {
    final controller = AppController(generator: FakeMenuGenerator());
    await controller.initialize();
    controller.stage = AppStage.result;
    controller.winner = '치킨';
    controller.winnerComment = '오늘 메뉴는 치킨, 확정!';

    await tester.pumpWidget(DishDashApp(controller: controller));

    expect(find.text('AI 한마디'), findsNothing);
    expect(find.text('오늘 메뉴는 치킨, 확정!'), findsOneWidget);
    expect(find.text('배민'), findsOneWidget);
    expect(find.text('쿠팡이츠'), findsOneWidget);
    expect(find.text('같은 메뉴 재경주'), findsNothing);
    expect(find.text('새 메뉴 생성'), findsNothing);
    expect(find.byIcon(Icons.emoji_events_rounded), findsNothing);
    expect(find.byType(FilledButton), findsNWidgets(2));
    expect(find.byType(OutlinedButton), findsNothing);
  });
}
