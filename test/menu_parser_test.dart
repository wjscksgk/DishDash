import 'dart:io';

import 'package:dish_dash/src/menu_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds the model path from shared path constants', () {
    final path = buildModelPath('Documents');

    expect(
      path,
      'Documents${Platform.pathSeparator}models'
      '${Platform.pathSeparator}gemma-4-e2b-it.litertlm',
    );
    expect(path, contains(modelDirectoryName));
    expect(path, endsWith(modelFileName));
  });

  test(
    'generation prompt requests fourteen restaurant delivery candidates',
    () {
      expect(menuPrompt, contains('저녁 메뉴 14개'));
      expect(menuPrompt, contains('국/찌개/탕'));
      expect(menuPrompt, contains('국밥류, 찌개류, 탕, 국'));
      expect(menuPrompt, contains('진국밥'));
      expect(menuPrompt, contains('맑은 국밥'));
      expect(menuPrompt, contains('제육국밥'));
      expect(menuPrompt, contains('춘장찌개'));
      expect(menuPrompt, contains('설국밥'));
      expect(menuPrompt, contains('닭한마리탕'));
      expect(menuPrompt, contains('삼계탕'));
      expect(menuPrompt, contains('실제 대표 메뉴명'));
      expect(menuPrompt, contains('완성 음식'));
      expect(menuPrompt, contains('카테고리 안의 실제 대표 메뉴명'));
      expect(menuPrompt, contains('14. [음식이름]'));
      expect(menuPrompt, isNot(contains('15. [음식이름]')));
    },
  );

  test('menu prompts stay compact for the local model context', () {
    final generationPrompt = buildGenerationPrompt(
      count: generatedMenuCount,
      category: defaultMenuCategory,
    );
    final validationPrompt = buildValidationPrompt('1. 순대국밥\n2. 진국밥');

    expect(generationPrompt.length, lessThan(1000));
    expect(validationPrompt.length, lessThan(700));
  });

  test('winner comment prompt focuses on the food experience', () {
    final prompt = buildWinnerCommentPrompt('순두부찌개');

    expect(prompt, contains('"순두부찌개"'));
    expect(prompt, contains('맛, 향, 식감, 온도'));
    expect(prompt, contains('구체적이고 감각적인 표현'));
    expect(prompt, contains('맛있겠다는 공감이나 감탄'));
    expect(prompt, contains('함께 기대하는 듯한 말투'));
    expect(prompt, contains('재료나 조리법을 지어내지 마'));
    expect(prompt, contains('35자 이내'));
    expect(prompt, contains('배달, 주문, 고민, 선택, 확정, 우승, 레이스'));
    expect(prompt, contains('행동을 권하는 표현은 사용하지 마'));
    expect(prompt, contains('얼큰한 국물에 포근한 두부라니 맛있겠네요'));
    expect(prompt, contains('설명이나 접두어 없이 한마디만 출력해'));
  });

  test('soup generation prompt rejects invented soup-like names', () {
    final prompt = buildGenerationPrompt(
      count: 7,
      category: defaultMenuCategory,
    );

    expect(prompt, contains('진한, 맑은, 얼큰한, 시원한'));
    expect(prompt, contains('수식어+국밥/국/탕/찌개 금지'));
    expect(prompt, contains('진국밥, 맑은 국밥, 얼큰한 국'));
    expect(prompt, contains('제육국밥처럼 볶음/고기 메뉴에 국밥'));
    expect(prompt, contains('소스/양념/추상어+찌개/국밥 합성 금지'));
    expect(prompt, contains('춘장찌개, 설국밥'));
    expect(prompt, contains('삼계탕, 닭곰탕, 닭개장'));
    expect(prompt, contains('닭한마리탕 제외'));
  });

  test('korean generation prompt rejects mixed invented menu names', () {
    final korean = menuCategories.firstWhere(
      (category) => category.id == 'korean',
    );
    final prompt = buildGenerationPrompt(count: 7, category: korean);

    expect(prompt, contains('제육국밥'));
    expect(prompt, contains('닭갈비국밥'));
    expect(prompt, contains('불고기찌개'));
    expect(prompt, contains('기존 메뉴명끼리 섞지 마'));
  });

  test('chinese generation prompt rejects set menu labels', () {
    final chinese = menuCategories.firstWhere(
      (category) => category.id == 'chinese',
    );
    final prompt = buildGenerationPrompt(count: 7, category: chinese);

    expect(prompt, contains('탕수육 세트'));
    expect(prompt, contains('짜장면 세트'));
    expect(prompt, contains('짬뽕순대'));
    expect(prompt, contains('불고기'));
    expect(prompt, contains('세트/콤보/모둠/정식/코스'));
    expect(prompt, contains('중식에서 불고기 금지'));
  });

  test('western generation prompt asks for concrete pasta and pizza names', () {
    final western = menuCategories.firstWhere(
      (category) => category.id == 'western',
    );
    final prompt = buildGenerationPrompt(count: 7, category: western);

    expect(prompt, contains('크림파스타'));
    expect(prompt, contains('페퍼로니피자'));
    expect(prompt, contains('라자냐'));
    expect(prompt, contains('시그니처'));
    expect(prompt, contains('클래식'));
    expect(prompt, contains('파스타, 피자 단독명 금지'));
    expect(prompt, contains('각 최대 2개'));
  });

  test('southeast asian generation prompt rejects invented combinations', () {
    final southeastAsian = menuCategories.firstWhere(
      (category) => category.id == 'southeast_asian',
    );
    final prompt = buildGenerationPrompt(count: 7, category: southeastAsian);

    expect(prompt, contains('동남아'));
    expect(prompt, contains('똠얌꿍 볶음'));
    expect(prompt, contains('닭곰탕'));
    expect(prompt, contains('외국 메뉴명+볶음/탕/국/국밥'));
  });

  test('follow-up generation prompts request only the missing candidates', () {
    final prompt = buildGenerationPrompt(
      count: 4,
      category: menuCategories.firstWhere(
        (category) => category.id == 'japanese',
      ),
      acceptedMenus: const ['치킨'],
      attemptedMenus: const ['불닭볶음면', '떡볶이 국수'],
    );

    expect(prompt, contains('저녁 메뉴 4개'));
    expect(prompt, contains('일식'));
    expect(prompt, contains('초밥, 라멘, 돈가스'));
    expect(prompt, contains('이미 통과한 다음 메뉴는 제외해: 치킨'));
    expect(prompt, contains('불닭볶음면, 떡볶이 국수'));
    expect(prompt, contains('4. [음식이름]'));
    expect(prompt, isNot(contains('5. [음식이름]')));
  });

  test('validation prompt asks the model to reject invalid candidates', () {
    const candidates = '''
1. 김치찌개
2. 불닭볶음면 (완성 음식으로 가정)
3. 떡볶이 국수
4. 떡볶이
''';

    final prompt = buildValidationPrompt(
      candidates,
      category: menuCategories.firstWhere(
        (category) => category.id == 'chinese',
      ),
    );

    expect(prompt, contains(candidates));
    expect(prompt, contains('중식'));
    expect(prompt, contains('카테고리 안의 완성 음식'));
    expect(prompt, contains('명백히 만든 이름'));
    expect(prompt, contains('브랜드/상품'));
    expect(prompt, contains('창작·합성'));
    expect(prompt, contains('중복 변형'));
    expect(prompt, contains('이름을 고치지 마'));
    expect(prompt, contains('통과: 1, 2, 3'));
  });

  test('soup validation prompt rejects generic adjective soup names', () {
    const candidates = '''
1. 순대국밥
2. 진국밥
3. 맑은 국밥
4. 김치찌개
5. 제육국밥
6. 닭한마리탕
7. 춘장찌개
8. 설국밥
''';

    final prompt = buildValidationPrompt(candidates);

    expect(prompt, contains(candidates));
    expect(prompt, contains('진국밥, 맑은 국밥'));
    expect(prompt, contains('수식어+국밥/국/탕/찌개 제외'));
    expect(prompt, contains('볶음/고기 메뉴+국밥 합성은 제외'));
    expect(prompt, contains('소스/양념/추상어+찌개/국밥 합성은 제외'));
    expect(prompt, contains('춘장찌개, 설국밥'));
    expect(prompt, contains('닭한마리탕은 제외'));
    expect(prompt, contains('삼계탕, 닭곰탕, 닭개장'));
  });

  test('validation prompt rejects invented names mixed from real menus', () {
    const candidates = '''
1. 제육볶음
2. 제육국밥
3. 불고기찌개
4. 비빔밥
''';

    final prompt = buildValidationPrompt(
      candidates,
      category: menuCategories.firstWhere(
        (category) => category.id == 'korean',
      ),
    );

    expect(prompt, contains(candidates));
    expect(prompt, contains('메뉴명끼리 섞은 이름'));
    expect(prompt, contains('제육국밥, 닭갈비국밥, 불고기찌개, 짬뽕순대'));
  });

  test('validation prompt rejects set menu labels', () {
    const candidates = '''
1. 탕수육 세트
2. 탕수육
3. 짬뽕
''';

    final prompt = buildValidationPrompt(
      candidates,
      category: menuCategories.firstWhere(
        (category) => category.id == 'chinese',
      ),
    );

    expect(prompt, contains(candidates));
    expect(prompt, contains('세트/콤보/모둠/정식/코스'));
    expect(prompt, contains('탕수육 세트'));
  });

  test('western validation prompt rejects broad or marketing pasta names', () {
    const candidates = '''
1. 파스타
2. 시그니처 파스타
3. 크림파스타
4. 클래식 피자
5. 페퍼로니피자
''';

    final western = menuCategories.firstWhere(
      (category) => category.id == 'western',
    );
    final prompt = buildValidationPrompt(candidates, category: western);

    expect(prompt, contains(candidates));
    expect(prompt, contains('파스타/피자 단독명 제외'));
    expect(prompt, contains('시그니처/클래식'));
    expect(prompt, contains('각 2개'));
    expect(western.fallbackMenus, isNot(contains('파스타')));
    expect(western.fallbackMenus, isNot(contains('피자')));
    expect(western.fallbackMenus, contains('크림파스타'));
    expect(western.fallbackMenus, contains('페퍼로니피자'));
  });

  test('southeast asian validation prompt rejects invented combinations', () {
    const candidates = '''
1. 팟타이
2. 똠얌꿍 볶음
3. 닭곰탕
4. 분짜
''';

    final southeastAsian = menuCategories.firstWhere(
      (category) => category.id == 'southeast_asian',
    );
    final prompt = buildValidationPrompt(candidates, category: southeastAsian);

    expect(prompt, contains(candidates));
    expect(prompt, contains('똠얌꿍 볶음'));
    expect(prompt, contains('닭곰탕'));
    expect(prompt, contains('외국 메뉴명+볶음/탕/국/국밥'));
  });

  test(
    'validation prompt rejects outside-category and mixed chinese names',
    () {
      const candidates = '''
1. 짬뽕순대
2. 불고기
3. 탕수육
4. 짬뽕
''';

      final prompt = buildValidationPrompt(
        candidates,
        category: menuCategories.firstWhere(
          (category) => category.id == 'chinese',
        ),
      );

      expect(prompt, contains(candidates));
      expect(prompt, contains('카테고리 밖 대표 메뉴'));
      expect(prompt, contains('중식에서 불고기'));
      expect(prompt, contains('짬뽕순대'));
    },
  );

  test('parses, deduplicates, and fills race menus', () {
    const raw = '''
1. 치킨
2. 피자
3. 치킨
4. [쌀국수]
''';

    final result = parseMenus(raw);

    expect(result, hasLength(raceMenuCount));
    expect(result.take(3), ['치킨', '피자', '쌀국수']);
    expect(result.toSet(), hasLength(raceMenuCount));
  });

  test('normalizes descriptions and menu options', () {
    const raw = '''
1. 돈가스 (등심)
2. 족발/보쌈
3. 파스타 (크림)
4. 치킨 또는 피자
''';

    final result = parseMenus(raw);

    expect(result.take(4), ['돈가스', '족발', '파스타', '치킨']);
  });

  test('deduplicates invisible spaces and punctuation', () {
    const raw = '''
1. 떡볶이
2. 떡​볶이
3. 떡 볶 이
4. 떡볶이.
5. 치킨
''';

    final result = parseMenus(raw);

    expect(result.where((menu) => menu.replaceAll(' ', '').startsWith('떡')), [
      '떡볶이',
    ]);
    expect(result, hasLength(raceMenuCount));
  });

  test('uses fallback list for invalid output', () {
    expect(parseMenus('오늘은 아무거나 드세요'), fallbackMenus.take(raceMenuCount));
  });

  test('uses category fallback list for invalid output', () {
    final category = menuCategories.firstWhere(
      (category) => category.id == 'grill_meat',
    );

    expect(
      parseMenus('오늘은 아무거나 드세요', fallbackMenuPool: category.fallbackMenus),
      category.fallbackMenus.take(raceMenuCount),
    );
  });

  test('fills insufficient validated menus from category fallback', () {
    final category = menuCategories.firstWhere(
      (category) => category.id == 'chinese',
    );

    final result = fillMenusWithFallback(const [
      '탕수육',
      '짬뽕',
    ], category.fallbackMenus);

    expect(result, hasLength(raceMenuCount));
    expect(result.take(2), ['탕수육', '짬뽕']);
    expect(result.toSet(), hasLength(raceMenuCount));
    expect(result, contains('짜장면'));
  });

  test('limits western pasta and pizza variants to two final menus', () {
    final western = menuCategories.firstWhere(
      (category) => category.id == 'western',
    );

    final result = fillMenusWithFallback(
      const [
        '페퍼로니피자',
        '버섯 크림 파스타',
        '크림파스타',
        '봉골레파스타',
        '토마토파스타',
        '알리오올리오',
        '마르게리타피자',
      ],
      western.fallbackMenus,
      category: western,
    );

    final pastaCount = result.where(
      (menu) =>
          menu.replaceAll(' ', '').contains('파스타') ||
          menu.replaceAll(' ', '') == '알리오올리오',
    );
    final pizzaCount = result.where((menu) => menu.contains('피자'));

    expect(result, hasLength(raceMenuCount));
    expect(pastaCount, hasLength(2));
    expect(pizzaCount, hasLength(2));
    expect(result, contains('안심스테이크'));
    expect(result, contains('버섯리조또'));
  });

  test('candidate parsing does not add fallback menus', () {
    expect(parseMenuCandidates('1. 치킨\n2. 피자'), ['치킨', '피자']);
    expect(parseMenuCandidates('검수 통과 없음'), isEmpty);
  });

  test('validation can only retain candidates from the current round', () {
    const candidates = ['치킨', '피자', '김치찌개'];
    const validatedRaw = '통과: 1, 3, 8';

    expect(retainValidatedCandidates(candidates, validatedRaw), ['치킨', '김치찌개']);
  });

  test('validation handles duplicate numbers and an empty result', () {
    const candidates = ['치킨', '피자', '김치찌개'];

    expect(retainValidatedCandidates(candidates, '통과: 2, 2, 1'), ['피자', '치킨']);
    expect(retainValidatedCandidates(candidates, '통과: 없음'), isEmpty);
  });

  test('validation exception can still describe hard validation failures', () {
    const error = MenuValidationException('검수 응답을 처리할 수 없습니다.');

    expect(error.toString(), '검수 응답을 처리할 수 없습니다.');
  });
}
