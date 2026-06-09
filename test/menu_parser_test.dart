import 'package:dish_dash/src/menu_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'generation prompt requests fourteen restaurant delivery candidates',
    () {
      expect(menuPrompt, contains('저녁 메뉴 14가지'));
      expect(menuPrompt, contains('식당에서 조리한'));
      expect(menuPrompt, contains('14. [음식이름]'));
      expect(menuPrompt, isNot(contains('15. [음식이름]')));
    },
  );

  test('follow-up generation prompts request only the missing candidates', () {
    final prompt = buildGenerationPrompt(
      count: 4,
      acceptedMenus: const ['치킨'],
      attemptedMenus: const ['불닭볶음면', '떡볶이 국수'],
    );

    expect(prompt, contains('저녁 메뉴 4가지'));
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

    final prompt = buildValidationPrompt(candidates);

    expect(prompt, contains(candidates));
    expect(prompt, contains('브랜드 상품'));
    expect(prompt, contains('창작 조합'));
    expect(prompt, contains('핵심 음식이 같은 변형 메뉴'));
    expect(prompt, contains('명백히 기준을 어길 때만 제외'));
    expect(prompt, contains('정상적인 메뉴명이면'));
    expect(prompt, contains('음식 이름을 다시 작성하지 마'));
    expect(prompt, contains('통과: 1, 2, 3'));
  });

  test('parses, deduplicates, and fills ten menus', () {
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

  test('validation exception reports an insufficient accepted count', () {
    const error = MenuValidationException('검수를 통과한 메뉴가 부족합니다: 5/7');

    expect(error.toString(), '검수를 통과한 메뉴가 부족합니다: 5/7');
  });
}
