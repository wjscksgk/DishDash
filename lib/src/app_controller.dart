import 'dart:async';

import 'package:flutter/foundation.dart';

import 'menu_generator.dart';

enum AppStage { booting, ready, generating, racing, result }

class AppController extends ChangeNotifier {
  AppController({MenuGenerator? generator})
    : generator = generator ?? FlutterGemmaMenuGenerator();

  final MenuGenerator generator;
  AppStage stage = AppStage.booting;
  String streamedText = '';
  String status = 'AI 엔진에 시동을 거는 중';
  String? modelPath;
  String? warning;
  List<String> menus = const [];
  String? winner;
  bool usingFallback = false;
  bool _aiInitialized = false;

  Future<void> initialize() async {
    modelPath = await generator.modelPath;
    try {
      await generator.initialize();
      _aiInitialized = true;
      status = 'AI READY';
    } catch (error, stackTrace) {
      _aiInitialized = false;
      warning = error.toString();
      status = 'DEMO MODE';
      debugPrint('Dish Dash: AI initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
    stage = AppStage.ready;
    notifyListeners();
  }

  Future<void> generateMenus() async {
    stage = AppStage.generating;
    streamedText = '';
    warning = null;
    usingFallback = false;
    status = '메뉴 후보 생성 및 검수 중';
    notifyListeners();

    try {
      if (!_aiInitialized) {
        await generator.initialize();
        _aiInitialized = true;
        status = 'AI READY';
        notifyListeners();
      }
      await for (final token in generator.generate().timeout(
        const Duration(seconds: 120),
      )) {
        streamedText += token;
        notifyListeners();
      }
      menus = parseMenus(streamedText);
    } catch (error, stackTrace) {
      warning = 'AI 생성 실패: $error';
      usingFallback = true;
      debugPrint('Dish Dash: $warning');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('Dish Dash: using demo fallback menus.');
      final demoMenus = fallbackMenus
          .take(raceMenuCount)
          .toList(growable: false);
      streamedText = demoMenus
          .asMap()
          .entries
          .map((entry) => '${entry.key + 1}. ${entry.value}')
          .join('\n');
      menus = demoMenus;
      notifyListeners();
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }

    stage = AppStage.racing;
    notifyListeners();
  }

  void finishRace(String menu) {
    if (stage != AppStage.racing) return;
    winner = menu;
    stage = AppStage.result;
    notifyListeners();
  }

  void replay() {
    winner = null;
    stage = AppStage.racing;
    notifyListeners();
  }

  Future<void> regenerate() => generateMenus();

  @override
  void dispose() {
    unawaited(generator.dispose());
    super.dispose();
  }
}
