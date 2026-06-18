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

class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.label,
    required this.description,
    required this.examples,
    required this.exclusions,
    required this.fallbackMenus,
  });

  final String id;
  final String label;
  final String description;
  final List<String> examples;
  final List<String> exclusions;
  final List<String> fallbackMenus;
}

const defaultMenuCategory = MenuCategory(
  id: 'soup_stew',
  label: '국/찌개/탕',
  description: '국밥류, 찌개류, 탕, 국처럼 국물 중심의 따뜻한 식사 메뉴',
  examples: ['순대국밥', '김치찌개', '감자탕', '삼계탕', '황태국'],
  exclusions: ['제육국밥', '춘장찌개', '설국밥', '진국밥', '맑은 국밥', '닭한마리탕'],
  fallbackMenus: [
    '김치찌개',
    '순두부찌개',
    '부대찌개',
    '된장찌개',
    '감자탕',
    '순대국밥',
    '설렁탕',
    '갈비탕',
    '육개장',
    '해장국',
  ],
);

const menuCategories = <MenuCategory>[
  defaultMenuCategory,
  MenuCategory(
    id: 'korean',
    label: '한식',
    description: '밥, 찜, 볶음, 국물, 정식 등 한국식 식당 메뉴',
    examples: ['제육볶음', '비빔밥', '닭갈비', '갈비찜', '김치찜'],
    exclusions: ['제육국밥', '닭갈비국밥', '불고기찌개', '중식', '일식', '양식'],
    fallbackMenus: [
      '제육볶음',
      '비빔밥',
      '김치찜',
      '닭갈비',
      '갈비찜',
      '오징어볶음',
      '낙지볶음',
      '보쌈',
      '족발',
      '불고기',
    ],
  ),
  MenuCategory(
    id: 'chinese',
    label: '중식',
    description: '한국 배달앱에서 판매되는 중국집과 중화요리 메뉴',
    examples: ['짜장면', '짬뽕', '탕수육', '마라탕', '볶음밥'],
    exclusions: ['짬뽕순대', '불고기', '탕수육 세트', '짜장면 세트', '일식 라멘', '한식 국밥'],
    fallbackMenus: [
      '짜장면',
      '짬뽕',
      '탕수육',
      '마라탕',
      '마파두부',
      '양장피',
      '깐풍기',
      '고추잡채',
      '중화볶음밥',
      '유린기',
    ],
  ),
  MenuCategory(
    id: 'japanese',
    label: '일식',
    description: '초밥, 돈부리, 라멘, 돈가스 등 일본식 식당 메뉴',
    examples: ['초밥', '라멘', '돈가스', '규동', '우동'],
    exclusions: ['중식 면요리', '한식 찌개', '양식 파스타'],
    fallbackMenus: [
      '초밥',
      '라멘',
      '돈가스',
      '우동',
      '규동',
      '가츠동',
      '사케동',
      '소바',
      '오코노미야키',
      '텐동',
    ],
  ),
  MenuCategory(
    id: 'western',
    label: '양식',
    description: '구체적인 파스타, 피자, 스테이크, 브런치 등 서양식 식당 메뉴',
    examples: ['크림파스타', '페퍼로니피자', '안심스테이크', '버섯리조또', '라자냐'],
    exclusions: [
      '파스타',
      '피자',
      '시그니처 파스타',
      '클래식 피자',
      '한식 정식',
      '중식 볶음밥',
      '일식 돈부리',
    ],
    fallbackMenus: [
      '크림파스타',
      '페퍼로니피자',
      '안심스테이크',
      '버섯리조또',
      '라자냐',
      '그라탕',
      '시저샐러드',
      '봉골레파스타',
      '마르게리타피자',
      '치킨필라프',
    ],
  ),
  MenuCategory(
    id: 'southeast_asian',
    label: '동남아',
    description: '태국, 베트남, 인도네시아 등 동남아 식당 메뉴',
    examples: ['쌀국수', '팟타이', '분짜', '나시고렝', '똠얌꿍'],
    exclusions: ['똠얌꿍 볶음', '닭곰탕', '중식 짬뽕', '일식 우동', '한식 국수'],
    fallbackMenus: [
      '쌀국수',
      '팟타이',
      '분짜',
      '나시고렝',
      '미고렝',
      '똠얌꿍',
      '반미',
      '카오팟',
      '그린커리',
      '월남쌈',
    ],
  ),
  MenuCategory(
    id: 'bunsik',
    label: '분식',
    description: '분식집에서 흔히 파는 간편한 식사와 간식 메뉴',
    examples: ['떡볶이', '김밥', '순대', '튀김', '라볶이'],
    exclusions: ['편의점 제품', '봉지라면 상품명', '카페 디저트'],
    fallbackMenus: [
      '떡볶이',
      '김밥',
      '순대',
      '튀김',
      '라볶이',
      '쫄면',
      '어묵',
      '돈가스김밥',
      '치즈떡볶이',
      '김치볶음밥',
    ],
  ),
  MenuCategory(
    id: 'chicken_fastfood',
    label: '치킨/패스트푸드',
    description: '치킨, 버거, 샌드위치처럼 빠르게 먹기 좋은 배달 메뉴',
    examples: ['후라이드치킨', '양념치킨', '햄버거', '샌드위치', '핫도그'],
    exclusions: ['브랜드 세트명', '마트 냉동식품', '음료 단품'],
    fallbackMenus: [
      '후라이드치킨',
      '양념치킨',
      '간장치킨',
      '햄버거',
      '치킨버거',
      '샌드위치',
      '핫도그',
      '치킨텐더',
      '감자튀김',
      '타코',
    ],
  ),
  MenuCategory(
    id: 'grill_meat',
    label: '고기/구이',
    description: '구이, 바비큐, 고기 덮밥과 고기 중심 식사 메뉴',
    examples: ['삼겹살', '갈비구이', '불고기', '스테이크덮밥', '닭꼬치'],
    exclusions: ['해산물 단품', '채식 샐러드', '디저트'],
    fallbackMenus: [
      '삼겹살',
      '갈비구이',
      '불고기',
      '돼지갈비',
      'LA갈비',
      '닭갈비',
      '막창구이',
      '곱창구이',
      '스테이크덮밥',
      '닭꼬치',
    ],
  ),
  MenuCategory(
    id: 'dessert_cafe',
    label: '디저트/카페',
    description: '카페와 디저트 가게에서 배달 가능한 단품 디저트 메뉴',
    examples: ['티라미수', '케이크', '와플', '빙수', '마카롱'],
    exclusions: ['음료만 있는 항목', '식재료', '브랜드 상품명'],
    fallbackMenus: [
      '티라미수',
      '치즈케이크',
      '와플',
      '빙수',
      '마카롱',
      '크로플',
      '도넛',
      '푸딩',
      '브라우니',
      '팬케이크',
    ],
  ),
];

const generatedMenuCount = 14;
const raceMenuCount = 7;
const maxGenerationRounds = 2;
const llmModelName = 'Gemma 4 E2B';
const modelDirectoryName = 'models';
const modelFileName = 'gemma-4-e2b-it.litertlm';

String buildModelPath(String documentsPath) =>
    '$documentsPath${Platform.pathSeparator}$modelDirectoryName'
    '${Platform.pathSeparator}$modelFileName';

String buildGenerationPrompt({
  required int count,
  MenuCategory category = defaultMenuCategory,
  List<String> acceptedMenus = const [],
  List<String> attemptedMenus = const [],
}) => '''
한국 배달앱 저녁 메뉴 $count개를 추천해.
카테고리: ${category.label} (${category.description})
허용 예: ${category.examples.join(', ')}
금지 예: ${category.exclusions.join(', ')}

규칙:
- 반드시 이 카테고리 안의 실제 대표 메뉴명만 써.
- 배달앱에서 자연스러운 완성 음식만 써.
- 브랜드/상품/라면/즉석/냉동/밀키트/식재료/과자/음료 제외.
- 카테고리명, ~류, ~요리, 한식/중식/일식/양식/분식/디저트 제외.
- 세트/콤보/모둠/정식/코스 제외: 탕수육 세트.
- 창작·합성 메뉴 제외: 떡볶이 국수, 깻잎밥, 닭갈비볶음, 짬뽕순대.
- 선택 카테고리 밖 대표 메뉴 제외: 중식에서 불고기 금지.
- 기존 메뉴명끼리 섞지 마: 제육+국밥=제육국밥, 불고기+찌개=불고기찌개 금지.
- 외국 메뉴명+볶음/탕/국/국밥 금지: 똠얌꿍 볶음.
- 일반/마케팅 수식어로 새 이름 만들지 마: 진한, 맑은, 얼큰한, 시원한, 시그니처, 클래식, 프리미엄, 스페셜.
- 양식: 파스타, 피자 단독명 금지. 파스타/피자/스테이크/리조또류 각 최대 2개.
- 국/찌개/탕에서는 수식어+국밥/국/탕/찌개 금지: 진국밥, 맑은 국밥, 얼큰한 국.
- 국밥은 실제 국밥 메뉴만. 제육국밥처럼 볶음/고기 메뉴에 국밥을 붙이지 마.
- 국/찌개/탕에서는 소스/양념/추상어+찌개/국밥 합성 금지: 춘장찌개, 설국밥.
- 닭 국물 메뉴는 삼계탕, 닭곰탕, 닭개장처럼 통용 메뉴명만. 닭한마리탕 제외.
- 같은 메뉴나 핵심 음식이 같은 변형은 한 번만.
- 괄호, 슬래시, 선택지, 설명 없이 음식명 하나만.
${acceptedMenus.isEmpty ? '' : '- 이미 통과한 다음 메뉴는 제외해: ${acceptedMenus.join(', ')}'}
${attemptedMenus.isEmpty ? '' : '- 이전에 제안한 다음 메뉴도 다시 제안하지 마: ${attemptedMenus.join(', ')}'}

번호와 음식 이름만 출력:
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

String buildValidationPrompt(
  String candidates, {
  MenuCategory category = defaultMenuCategory,
}) => '''
통과 번호만 골라.
카테고리: ${category.label}
허용: ${category.examples.join(', ')}
금지: ${category.exclusions.join(', ')}

통과: 카테고리 안의 완성 음식.
제외: 카테고리 밖, 브랜드/상품/라면/즉석/밀키트/식재료, 카테고리명, ~류/~요리, 창작·합성, 중복 변형.
제외: 세트/콤보/모둠/정식/코스. 예: 탕수육 세트.
제외: 카테고리 밖 대표 메뉴. 예: 중식에서 불고기.
제외: 금지 예나 명백히 만든 이름.
제외: 메뉴명끼리 섞은 이름. 예: 제육국밥, 닭갈비국밥, 불고기찌개, 짬뽕순대.
제외: 외국 메뉴명+볶음/탕/국/국밥. 예: 똠얌꿍 볶음.
제외: 진한/맑은/얼큰한/시원한/시그니처/클래식/프리미엄/스페셜 같은 수식어로 만든 이름.
양식: 파스타/피자 단독명 제외, 파스타/피자/스테이크/리조또류 각 2개.
국/찌개/탕이면 진국밥, 맑은 국밥, 얼큰한 국, 시원한 탕처럼 수식어+국밥/국/탕/찌개 제외.
국밥은 실제 국밥만. 제육국밥처럼 볶음/고기 메뉴+국밥 합성은 제외.
국/찌개/탕에서 춘장찌개, 설국밥처럼 소스/양념/추상어+찌개/국밥 합성은 제외.
닭한마리탕은 제외. 닭 국물 메뉴는 삼계탕, 닭곰탕, 닭개장처럼 통용 이름만 통과.
후보에 없는 메뉴를 만들거나 이름을 고치지 마.

후보:
$candidates

형식:
통과: 1, 2, 3

없으면:
통과: 없음
''';

List<String> parseMenus(
  String raw, {
  List<String> fallbackMenuPool = fallbackMenus,
  MenuCategory? category,
}) {
  final parsed = parseMenuCandidates(raw, limit: raceMenuCount);
  return fillMenusWithFallback(parsed, fallbackMenuPool, category: category);
}

List<String> fillMenusWithFallback(
  List<String> menus,
  List<String> fallbackMenuPool, {
  int count = raceMenuCount,
  MenuCategory? category,
}) {
  final filled = <String>[];
  final familyCounts = <String, int>{};

  bool canAdd(String menu) {
    if (_containsEquivalentMenu(filled, menu)) return false;
    final family = _limitedMenuFamily(menu, category);
    if (family == null) return true;
    final currentCount = familyCounts[family] ?? 0;
    if (currentCount >= 2) return false;
    familyCounts[family] = currentCount + 1;
    return true;
  }

  for (final menu in menus) {
    if (filled.length == count) break;
    if (canAdd(menu)) filled.add(menu);
  }
  for (final fallback in fallbackMenuPool) {
    if (filled.length == count) break;
    if (canAdd(fallback)) filled.add(fallback);
  }
  return filled;
}

String? _limitedMenuFamily(String menu, MenuCategory? category) {
  if (category?.id != 'western') return null;
  final key = _menuComparisonKey(menu);
  if (key.contains('파스타') || key.contains('스파게티') || key == '알리오올리오') {
    return 'pasta';
  }
  if (key.contains('피자')) return 'pizza';
  if (key.contains('스테이크')) return 'steak';
  if (key.contains('리조또')) return 'risotto';
  return null;
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
  Stream<String> generate(MenuCategory category);
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
  Stream<String> generate(MenuCategory category) async* {
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
        category: category,
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
        buildValidationPrompt(candidateText, category: category),
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

    accepted.shuffle(random);
    if (accepted.length < raceMenuCount) {
      debugPrint(
        'Dish Dash: validation accepted ${accepted.length}/$raceMenuCount; '
        'filling remaining menus from ${category.label} fallback.',
      );
    }
    final finalMenus = fillMenusWithFallback(
      accepted,
      category.fallbackMenus,
      category: category,
    ).toList(growable: false);
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
