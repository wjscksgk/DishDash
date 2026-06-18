# Dish Dash 메뉴 생성 테스트 현황

작성일: 2026-06-18

## 현재 상태

- 카테고리 선택 기능 추가 완료
- 선택 카테고리 기준 LLM 메뉴 생성 프롬프트 적용 완료
- 메뉴 생성 개수는 최종 7개로 조정 완료
- 레이스와 별개로 메뉴 생성 결과를 확인하는 `MENU TEST` 버튼 추가 완료
- 생성 메뉴 리스트 복사 버튼 추가 완료
- LLM 검증 실패 시 앱이 중단되지 않고 카테고리 fallback으로 채우도록 조정 완료

## 수동 LLM 테스트 완료 카테고리

아래 카테고리는 Windows 개발 환경에서 실제 생성 결과를 보며 프롬프트를 보정했다.

- `국/찌개/탕`
  - `진국밥`, `맑은 국밥`, `제육국밥`, `춘장찌개`, `설국밥`, `닭한마리탕` 같은 창작/부적절 메뉴 방지 규칙 추가
- `한식`
  - `제육국밥`처럼 실제 한식 메뉴명끼리 섞은 창작 메뉴 방지 규칙 추가
- `중식`
  - `탕수육 세트` 같은 세트명 방지
  - `짬뽕순대`, `불고기`처럼 중식 밖 메뉴나 합성 메뉴 방지
- `일식`
  - 현재 추가 이슈 없이 테스트 완료
- `양식`
  - `시그니처 파스타`, `클래식 피자` 같은 마케팅 수식어 방지
  - `파스타`, `피자` 단독명 대신 구체 메뉴명 생성 유도
  - 파스타류/피자류/스테이크류/리조또류가 각각 최대 2개만 최종 리스트에 남도록 후처리 추가
- `동남아`
  - `똠얌꿍 볶음`처럼 기존 외국 메뉴명 뒤에 `볶음/탕/국/국밥`을 붙이는 합성 메뉴 방지
  - `닭곰탕` 같은 카테고리 밖 메뉴 방지 신호 강화

## 아직 수동 LLM 테스트가 필요한 카테고리

- `분식`
- `치킨/패스트푸드`
- `고기/구이`
- `디저트/카페`

## 자동 검증 현황

마지막 확인 명령:

```powershell
C:\flutter\bin\flutter.bat test test\menu_parser_test.dart
C:\flutter\bin\flutter.bat analyze
C:\flutter\bin\flutter.bat test
```

결과:

- `menu_parser_test.dart` 통과
- `flutter analyze` 통과
- 전체 `flutter test` 통과

추가된 주요 회귀 테스트:

- 카테고리별 프롬프트 금지 문구 검증
- 로컬 모델 컨텍스트 초과 방지를 위한 프롬프트 길이 제한 검증
- 검증 통과 메뉴가 부족할 때 카테고리 fallback으로 채우는 동작 검증
- 양식 카테고리에서 같은 음식군이 2개를 초과하지 않는 최종 리스트 보정 검증

## MacBook에서 이어서 할 작업

1. 저장소 최신화

```bash
git pull
flutter pub get
```

2. macOS 모델 경로 확인

```text
$HOME/Documents/models/gemma-4-e2b-it.litertlm
```

3. 기본 검증

```bash
flutter analyze
flutter test
flutter run -d macos
```

4. 남은 카테고리 수동 생성 테스트

- `분식`
- `치킨/패스트푸드`
- `고기/구이`
- `디저트/카페`

## 배포 전 제거 또는 결정 필요 항목

아래 항목은 카테고리별 LLM 검수 편의를 위해 추가된 성격이 강하므로, 배포 전 제품 기능으로 남길지 결정해야 한다.

- `lib/src/app.dart`
  - 시작 화면의 `MENU TEST` 버튼
  - 메뉴 미리보기 패널
  - 메뉴 리스트 `COPY` 버튼
- `lib/src/app_controller.dart`
  - `previewMenusForSelectedCategory`
  - `previewMenus`, `previewText`, `previewWarning`, `previewUsingFallback`
  - `Dish Dash preview menus...` debug 로그
- `test/app_flow_test.dart`
  - `MENU TEST` UI와 preview 상태를 검증하는 테스트
  - 위 UI를 제거하면 함께 삭제 또는 수정 필요
- `lib/src/menu_generator.dart`
  - `Dish Dash final race menus` debug 로그는 출시 빌드에서 노출 필요성이 낮으므로 제거 또는 debug 모드 한정 처리 검토
  - generation/validation round debug 로그도 출시 전에 로그 레벨 또는 debug 모드 한정 처리 검토

유지해야 하는 항목:

- `test/menu_parser_test.dart`의 프롬프트/파싱 회귀 테스트
- 카테고리별 fallback 메뉴
- LLM 실패 시 fallback으로 앱 흐름을 유지하는 동작
- 양식 카테고리의 음식군 최대 2개 후처리

## 알려진 제약

- Windows에서 실제 모바일 딥링크와 arm64 `.litertlm` 모바일 추론은 최종 검증하지 못했다.
- Android/iOS 실기기 검증은 배포 전 별도로 필요하다.
- 프롬프트는 로컬 모델 입력 제한 때문에 길이를 강하게 제한하고 있다. 새 규칙을 추가할 때는 `menu prompts stay compact for the local model context` 테스트를 반드시 확인해야 한다.
