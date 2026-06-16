import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

const fallbackMenus = <String>[
  '치킨',
  '피자',
  '떡볶이',
  '햄버거',
  '족발',
  '보쌈',
  '짜장면',
  '초밥',
  '김치찌개',
  '돈까스',
];

const generatedMenuCount = 14;
const raceMenuCount = 10;
const maxGenerationRounds = 2;
const llmModelName = 'Gemma 4 E2B';
const modelDirectoryName = 'models';
const modelFileName = 'gemma-4-e2b-it.litertlm';

String buildModelPath(String documentsPath) =>
    '$documentsPath${Platform.pathSeparator}$modelDirectoryName'
    '${Platform.pathSeparator}$modelFileName';

String buildGenerationPrompt({
  required int count,
  List<String> acceptedMenus = const [],
  List<String> attemptedMenus = const [],
}) => '''
한국의 배달 앱에서 식당에 주문할 저녁 메뉴 $count가지를 추천해.

아래 조건을 모두 지켜:
- 식당에서 조리한 뒤 바로 먹을 수 있는 완성 음식만 선택해.
- 배민이나 쿠팡이츠에서 음식 이름으로 검색했을 때 여러 식당이 판매할 만한 대표 메뉴를 선택해.
- 편의점이나 마트에서 구매하는 라면 제품, 즉석식품, 냉동식품, 밀키트, 식재료, 과자, 음료는 제외해.
- 특정 상품명이나 브랜드명은 제외해. 예: 불닭볶음면, 신라면, 비비고 만두.
- 실제 식당에서 통용되는 기존 메뉴명만 사용하고, 서로 다른 음식 이름을 임의로 합쳐 새 메뉴를 만들지 마.
- 잘못된 예: 떡볶이 국수, 깻잎밥, 닭갈비볶음, 불닭볶음면.
- 완전히 같은 메뉴명은 절대로 두 번 적지 마. 작성한 뒤 동일 메뉴가 없는지 다시 확인해.
- 이름만 조금 다른 사실상 같은 음식은 한 번만 추천해.
- 핵심 음식명이 같고 '볶음', '구이', '찜', '탕', '정식' 같은 조리 표현만 추가된 메뉴는 중복이야.
- 잘못된 조합: 닭갈비와 닭갈비볶음, 불고기와 불고기정식, 족발과 족발구이.
- 위와 같은 중복이 있으면 둘 중 더 일반적이고 짧은 대표 메뉴명 하나만 남기고 전혀 다른 음식으로 교체해.
- 음식 종류나 카테고리 이름이 아니라 주문 가능한 구체적인 음식 이름을 적어.
- '~류', '~요리', 한식, 중식, 일식, 양식, 분식, 디저트 같은 포괄적인 분류 표현은 제외해.
- 잘못된 예: 튀김류, 찌개류, 면 요리, 고기 요리, 한식, 디저트.
- 올바른 예: 새우튀김, 김치찌개, 짬뽕, 제육볶음, 비빔밥, 티라미수.
- 각 항목에는 하나의 대표 메뉴명만 적어. 괄호, 슬래시, 선택지, 재료 설명, 부연 설명을 붙이지 마.
- 잘못된 예: 돈가스 (생선/소고기), 족발/보쌈, 파스타 (크림 또는 토마토).
- 올바른 예: 돈가스, 족발, 파스타.
- 출력 전에 각 항목이 식당 배달 메뉴인지 스스로 확인하고 조건에 맞지 않으면 교체해.
${acceptedMenus.isEmpty ? '' : '- 이미 통과한 다음 메뉴는 제외해: ${acceptedMenus.join(', ')}'}
${attemptedMenus.isEmpty ? '' : '- 이전에 제안한 다음 메뉴도 다시 제안하지 마: ${attemptedMenus.join(', ')}'}

다음 형식으로만 응답해. 번호와 음식 이름 외 어떤 텍스트도 포함하지 마.
${List.generate(count, (index) => '${index + 1}. [음식이름]').join('\n')}
''';

final menuPrompt = buildGenerationPrompt(count: generatedMenuCount);

String buildWinnerCommentPrompt(String menu) => '''
오늘의 메뉴는 "$menu"야.
이 음식의 매력이 생생하게 느껴지는 짧은 한국어 한마디를 작성해.

작성 기준:
- 맛, 향, 식감, 온도 중 이 음식의 대표적인 특징 한 가지에 집중해.
- 먹는 순간을 떠올릴 수 있도록 구체적이고 감각적인 표현을 사용해.
- 앞부분에서 음식의 매력을 묘사하고, 뒷부분에서 맛있겠다는 공감이나 감탄을 표현해.
- 사용자에게 행동을 권하지 말고 함께 기대하는 듯한 말투로 작성해.
- 메뉴 이름을 억지로 반복하지 않아도 돼.
- 실제 음식에 일반적으로 어울리는 특징만 묘사하고 재료나 조리법을 지어내지 마.
- 35자 이내로 작성해.
- 따옴표, 목록 기호, 이모지는 사용하지 마.
- 배달, 주문, 고민, 선택, 확정, 우승, 레이스라는 단어는 사용하지 마.
- 느껴보세요, 즐겨보세요, 드셔보세요처럼 행동을 권하는 표현은 사용하지 마.
- 맛있겠네요라는 말만 단독으로 쓰지 말고 반드시 음식의 구체적인 특징을 함께 적어.
- 다른 음식을 언급하거나 추천하지 마.

좋은 예:
- 순두부찌개: 얼큰한 국물에 포근한 두부라니 맛있겠네요
- 순두부찌개: 보들보들한 두부가 정말 든든하겠어요
- 치킨: 바삭한 껍질과 촉촉한 살이 정말 맛있겠네요
- 초밥: 부드러운 회와 고슬한 밥의 조화가 좋겠네요

설명이나 접두어 없이 한마디만 출력해.
''';

String buildValidationPrompt(String candidates) => '''
아래 목록은 다른 AI가 만든 배달 음식 후보야. 각 항목을 검수하고 통과할 항목의 번호만 선택해.

검수 기준:
- 한국 배달 앱에서 식당이 조리해 판매하는 음식으로 자연스럽게 이해되면 통과시켜.
- 명백한 라면 제품, 브랜드 상품, 편의점·마트 상품, 밀키트, 식재료만 제외해.
- 실제 음식으로 보기 어려운 명백한 창작 조합이나 억지로 합친 이름만 제외해.
- '~류', '~요리'처럼 구체적인 음식이 아닌 카테고리명만 제외해.
- 괄호 안 설명이나 부연 문구가 있어도 앞부분이 정상적인 메뉴명이면 그 원래 항목을 통과시켜.
- 같은 음식, 표기만 다른 음식, 핵심 음식이 같은 변형 메뉴는 하나만 남겨.
- 일반적인 식당 메뉴일 가능성이 높으면 통과시키고, 명백히 기준을 어길 때만 제외해.
- 일반적인 배달 음식은 적극적으로 통과시켜.
- 후보에 없는 메뉴를 새로 만들지 마.
- 음식 이름을 다시 작성하지 마.

후보 목록:
<candidates>
$candidates
</candidates>

반드시 다음 형식 한 줄로만 응답해:
통과: 1, 2, 3

통과 항목이 하나도 없으면 다음과 같이 응답해:
통과: 없음
''';

List<String> parseMenus(String raw) {
  final parsed = parseMenuCandidates(raw, limit: raceMenuCount);

  for (final fallback in fallbackMenus) {
    if (parsed.length == raceMenuCount) break;
    if (!_containsEquivalentMenu(parsed, fallback)) parsed.add(fallback);
  }
  return parsed;
}

List<String> parseMenuCandidates(String raw, {int? limit}) {
  final pattern = RegExp(r'^\s*\d+\.\s*(.+?)\s*$', multiLine: true);
  final parsed = <String>[];
  for (final match in pattern.allMatches(raw)) {
    final value = _normalizeMenuName(match.group(1));
    if (value != null &&
        value.isNotEmpty &&
        !_containsEquivalentMenu(parsed, value)) {
      parsed.add(value);
    }
    if (limit != null && parsed.length == limit) break;
  }
  return parsed;
}

List<String> retainValidatedCandidates(
  List<String> candidates,
  String validatedRaw,
) {
  final retained = <String>[];
  final response = RegExp(
    r'통과\s*:\s*([^\r\n]+)',
  ).firstMatch(validatedRaw)?.group(1);
  if (response == null || response.contains('없음')) return retained;

  final seenIndices = <int>{};
  for (final match in RegExp(r'\d+').allMatches(response)) {
    final number = int.tryParse(match.group(0)!);
    if (number == null || number < 1 || number > candidates.length) continue;
    final index = number - 1;
    if (seenIndices.add(index)) {
      retained.add(candidates[index]);
    }
  }
  return retained;
}

String? _normalizeMenuName(String? raw) {
  if (raw == null) return null;

  return raw
      .replaceAll(RegExp(r'[\[\]]'), '')
      .replaceAll(RegExp(r'\s*[\(（][^\)）]*[\)）]'), '')
      .split(RegExp(r'\s*(?:/|\|| 또는 )\s*'))
      .first
      .trim();
}

bool _containsEquivalentMenu(List<String> menus, String candidate) {
  final candidateKey = _menuComparisonKey(candidate);
  return menus.any((menu) => _menuComparisonKey(menu) == candidateKey);
}

String _menuComparisonKey(String menu) {
  return menu
      .toLowerCase()
      .replaceAll(RegExp(r'[\s\u00A0\u200B-\u200D\u2060\uFEFF]+'), '')
      .replaceAll(RegExp(r'[·ㆍ・.,:;!?\-_]'), '');
}

abstract interface class MenuGenerator {
  Future<String> get modelPath;
  Future<void> initialize();
  Stream<String> generate();
  Stream<String> generateWinnerComment(String menu);
  Future<void> dispose();
}

class FlutterGemmaMenuGenerator implements MenuGenerator {
  InferenceModel? _model;
  InferenceChat? _chat;

  @override
  Future<String> get modelPath async {
    if (Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null) {
        final developmentPath = buildModelPath(
          '$home${Platform.pathSeparator}Documents',
        );
        if (await File(developmentPath).exists()) return developmentPath;
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    return buildModelPath(documents.path);
  }

  @override
  Future<void> initialize() async {
    await FlutterGemma.initialize();
    final path = await modelPath;
    final file = File(path);
    if (!await file.exists()) {
      throw ModelMissingException(path);
    }

    await FlutterGemma.installModel(
      modelType: ModelType.gemma4,
      fileType: ModelFileType.litertlm,
    ).fromFile(path).install();

    try {
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.gpu,
        maxConcurrentSessions: 1,
      );
    } catch (error) {
      debugPrint('GPU model initialization failed, retrying on CPU: $error');
      _model = await FlutterGemma.getActiveModel(
        maxTokens: 1024,
        preferredBackend: PreferredBackend.cpu,
        maxConcurrentSessions: 1,
      );
    }
    debugPrint('Dish Dash active backend: ${_model?.activeBackend}');
  }

  @override
  Stream<String> generate() async* {
    final model = _model;
    if (model == null) throw StateError('Model is not initialized.');

    final accepted = <String>[];
    final attempted = <String>[];
    final random = Random();
    debugPrint('Dish Dash: starting menu generation pipeline.');

    for (
      var round = 0;
      round < maxGenerationRounds && accepted.length < raceMenuCount;
      round++
    ) {
      debugPrint('Dish Dash: generation round ${round + 1} started.');
      final generationPrompt = buildGenerationPrompt(
        count: generatedMenuCount,
        acceptedMenus: accepted,
        attemptedMenus: attempted,
      );
      final generatedRaw = await _runChat(
        model,
        generationPrompt,
        temperature: 0.65,
      );
      final candidates = <String>[];
      for (final candidate in parseMenuCandidates(
        generatedRaw,
        limit: generatedMenuCount,
      )) {
        if (!_containsEquivalentMenu(attempted, candidate) &&
            !_containsEquivalentMenu(accepted, candidate)) {
          candidates.add(candidate);
        }
      }
      debugPrint(
        'Dish Dash: generation round ${round + 1} produced '
        '${candidates.length} unique candidates.',
      );
      for (final candidate in candidates) {
        if (!_containsEquivalentMenu(attempted, candidate)) {
          attempted.add(candidate);
        }
      }
      if (candidates.isEmpty) continue;

      debugPrint('Dish Dash: validation round ${round + 1} started.');
      final candidateText = candidates
          .asMap()
          .entries
          .map((entry) => '${entry.key + 1}. ${entry.value}')
          .join('\n');
      final validatedRaw = await _runChat(
        model,
        buildValidationPrompt(candidateText),
        temperature: 0.2,
      );
      final retained = retainValidatedCandidates(candidates, validatedRaw);
      for (final candidate in retained) {
        if (!_containsEquivalentMenu(accepted, candidate)) {
          accepted.add(candidate);
        }
      }
      debugPrint(
        'Dish Dash: validation round ${round + 1} accepted '
        '${retained.length}; ${accepted.length}/$raceMenuCount collected.',
      );
    }

    if (accepted.length < raceMenuCount) {
      throw MenuValidationException(
        '검수를 통과한 메뉴가 부족합니다: ${accepted.length}/$raceMenuCount',
      );
    }

    accepted.shuffle(random);
    final finalMenus = accepted.take(raceMenuCount).toList(growable: false);
    final finalOutput = finalMenus
        .asMap()
        .entries
        .map((entry) => '${entry.key + 1}. ${entry.value}')
        .join('\n');
    debugPrint('Dish Dash final race menus:\n$finalOutput');
    yield finalOutput;
  }

  @override
  Stream<String> generateWinnerComment(String menu) async* {
    final model = _model;
    if (model == null) throw StateError('Model is not initialized.');

    await _chat?.close();
    _chat = await _createChat(model, temperature: 0.75);
    try {
      await _chat!.addQuery(
        Message.text(text: buildWinnerCommentPrompt(menu), isUser: true),
      );
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) yield response.token;
      }
    } finally {
      await _chat?.close();
      _chat = null;
    }
  }

  Future<String> _runChat(
    InferenceModel model,
    String prompt, {
    required double temperature,
  }) async {
    await _chat?.close();
    _chat = await _createChat(model, temperature: temperature);
    try {
      await _chat!.addQuery(Message.text(text: prompt, isUser: true));

      final output = StringBuffer();
      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) output.write(response.token);
      }
      return output.toString();
    } finally {
      await _chat?.close();
      _chat = null;
    }
  }

  Future<InferenceChat> _createChat(
    InferenceModel model, {
    required double temperature,
  }) {
    return model.createChat(
      temperature: temperature,
      randomSeed: DateTime.now().microsecondsSinceEpoch,
      topK: 40,
      topP: 0.9,
      tokenBuffer: 64,
      modelType: ModelType.gemma4,
    );
  }

  @override
  Future<void> dispose() async {
    await _chat?.close();
    _chat = null;
    await _model?.close();
    _model = null;
  }
}

class ModelMissingException implements Exception {
  const ModelMissingException(this.path);

  final String path;

  @override
  String toString() => '모델 파일을 찾을 수 없습니다: $path';
}

class MenuValidationException implements Exception {
  const MenuValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
