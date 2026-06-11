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
  String winnerComment = '';
  bool isGeneratingWinnerComment = false;
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
    winnerComment = '';
    isGeneratingWinnerComment = _aiInitialized;
    stage = AppStage.result;
    notifyListeners();
    unawaited(_generateWinnerComment(menu));
  }

  Future<void> _generateWinnerComment(String menu) async {
    if (!_aiInitialized) {
      winnerComment = _fallbackWinnerComment(menu);
      isGeneratingWinnerComment = false;
      notifyListeners();
      return;
    }

    try {
      await for (final token in generator
          .generateWinnerComment(menu)
          .timeout(const Duration(seconds: 20))) {
        winnerComment += token;
        notifyListeners();
      }
      winnerComment = winnerComment.trim();
      if (winnerComment.isEmpty) {
        winnerComment = _fallbackWinnerComment(menu);
      }
    } catch (error, stackTrace) {
      winnerComment = _fallbackWinnerComment(menu);
      debugPrint('Dish Dash: winner comment generation failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      isGeneratingWinnerComment = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    unawaited(generator.dispose());
    super.dispose();
  }
}

String _fallbackWinnerComment(String menu) => '$menu 특유의 맛과 식감, 생각만 해도 맛있겠네요.';
