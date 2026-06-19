# Dish Dash

Gemma 4가 배달 메뉴 후보 14개를 생성하고 별도 검수 채팅이 유효한 항목만 통과시킵니다. 부족하면 한 번 더 생성과 검수를 수행한 뒤 무작위로 고른 7개가 Flame 레이스로 오늘의 메뉴를
결정하는 Flutter 앱입니다.

## 개발 환경

- Flutter 3.44.2 / Dart 3.12.2 이상
- Android arm64-v8a 실기기 또는 iOS 16 이상 arm64 실기기
- `flutter_gemma 0.16.4`
- Gemma 4 E2B `.litertlm` 모델

Windows에서는 Flutter 플러그인 심볼릭 링크 생성을 위해 개발자 모드를
활성화해야 합니다.

## 모델 설치

모델은 앱에 번들하지 않습니다. 파일명은 반드시
`gemma-4-e2b-it.litertlm`이어야 합니다.

Android:

```powershell
flutter run
.\scripts\install_model_android.ps1 -ModelPath C:\models\gemma-4-e2b-it.litertlm
```

스크립트 실행 후 앱을 완전히 종료하고 다시 실행합니다.

iOS:

1. Xcode에서 앱을 실기기에 한 번 설치합니다.
2. Finder의 기기 파일 공유에서 Dish Dash의 `models` 폴더에 모델을 넣습니다.
3. 파일 공유 UI가 루트만 제공하면 `models` 폴더를 포함한 디렉터리를 복사합니다.
4. 앱을 완전히 종료하고 다시 실행합니다.

앱이 기대하는 최종 경로는 Documents 아래
`models/gemma-4-e2b-it.litertlm`입니다.

## 실행 및 검증

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d windows              # UI/게임 빠른 반복 확인
flutter run -d <android-device-id>  # 실 Gemma 추론 검증 (arm64-v8a 필수)
```

모델이 없거나 추론이 실패하면 앱은 명시적으로 `DEMO MODE`를 표시하고
fallback 메뉴로 전체 레이스 흐름을 계속합니다.
