# Dish Dash Agent Instructions

## Project Overview

Dish Dash is a Flutter PBL project targeting Android and iOS from one Dart
codebase. It generates ten Korean delivery-food candidates with an on-device
LLM, sends them into a Flame top-view race, selects the winner, and opens a
delivery app search through a deep link.

Primary flow:

1. Initialize the local Gemma runtime in the background.
2. Generate and validate ten food candidates while showing generation progress.
3. Run a ten-racer Flame game using the menu names.
4. Show the winning food.
5. Let the user choose Baemin or Coupang Eats.

The implementation must remain usable for demonstrations when the model or a
native runtime is unavailable.

## Technology Decisions

- Language: Dart
- Framework: Flutter
- Local LLM: `flutter_gemma 0.16.4`
- Model: Gemma 4 E2B in `.litertlm` format
- Game engine: Flame
- External app launch: `url_launcher`
- Model location:
  `Documents/models/gemma-4-e2b-it.litertlm`
- UI direction: portrait only
- Visual direction: retro food arcade

Do not replace `flutter_gemma`, change the model family, add an in-app model
download, or bundle the model without an explicit request.

## Architecture

- `AppController` owns the app flow:
  `booting -> ready -> generating -> racing -> result`.
- Keep LLM access behind the `MenuGenerator` interface.
- `FlutterGemmaMenuGenerator` must request GPU first and retry with CPU if GPU
  model initialization fails.
- Create a fresh chat for every menu generation so previous output does not
  affect a new race.
- Close chats and inference models when they are no longer needed.
- Keep menu parsing independent from UI and native runtime code.
- Parse numbered lines, trim wrappers and whitespace, remove duplicates, and
  always return exactly ten menu names by filling from `fallbackMenus`.
- Model absence, initialization failure, generation failure, or timeout must
  not block the game. Clearly indicate demo/fallback mode and continue.
- Winner selection must be idempotent. Only the first finish event may change
  the app state.

## UI And Game Rules

- Preserve the portrait layout on all supported mobile platforms.
- Keep all ten racers readable on a phone-sized screen.
- Maintain the charcoal, cream, tomato, mustard, and mint arcade palette unless
  a redesign is requested.
- Show a clear loading or progress state while the AI generation process runs.
- The race should contain visible overtaking and normally finish in roughly
  8-14 seconds.
- The result screen must offer:
  - Baemin
  - Coupang Eats
- Do not offer replay or candidate regeneration after a winner is selected.
- Deep-link failure must degrade to copying the food name, opening the app
  home, or opening the platform store.

## Platform Constraints

### Android

- `.litertlm` inference is supported only on `arm64-v8a`.
- Keep Android `minSdk` at 24 or higher.
- Preserve the OpenCL native-library declarations in `AndroidManifest.xml`.
- Preserve Baemin and Coupang Eats package/scheme visibility declarations.
- Android x86_64 emulators cannot validate the real Gemma `.litertlm` path.
- Use an arm64 physical device for final inference and deep-link validation.

### iOS

- Keep the deployment target at iOS 16 or higher.
- Keep CocoaPods statically linked.
- Preserve the extended-addressing and increased-memory entitlements.
- Preserve `baemin` and `coupangeats` query schemes.
- Use an arm64 physical iPhone for final model, memory, Metal, and deep-link
  validation. The simulator is suitable primarily for UI and game checks.

### Windows

- Windows desktop is a development target for UI, game, and local Gemma
  integration testing, but it is not a product release target.
- `flutter_gemma` uses its Windows x64 LiteRT-LM runtime. GPU preference maps to
  the available Windows accelerator and falls back to CPU.
- Flutter plugins require Developer Mode or an administrator terminal for
  symbolic-link creation.

## Model Handling

- Never commit `.litertlm` files.
- Never add the model to Flutter assets, APK, IPA, or desktop bundles.
- Use `scripts/install_model_android.ps1` for Android development injection.
- Keep model installation instructions synchronized with the actual path used
  by `FlutterGemmaMenuGenerator`.
- Do not log credentials or introduce a Hugging Face token unless network model
  download is explicitly added.

## Development Practices

- Prefer existing classes and patterns over adding state-management packages.
- Keep changes narrowly scoped; this is a short-duration PBL project.
- Do not add production dependencies unless they remove a concrete blocker.
- Avoid unrelated generated-file or platform-project churn.
- Keep source files formatted with LF line endings.
- Update README instructions whenever setup, model paths, platform constraints,
  or launch commands change.

## Required Verification

After Dart or Flutter behavior changes, run:

```powershell
flutter analyze
flutter test
```

After Android or plugin configuration changes, also run:

```powershell
flutter build apk --debug
flutter build apk --release
```

For UI-only work, verify the Windows application when mobile devices are
unavailable:

```powershell
flutter run -d windows
```

Tests should cover menu parsing, fallback behavior, state transitions, and
single-winner race behavior where practical. Always report which physical
device checks could not be performed.
