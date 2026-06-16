# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Detailed, binding project rules live in `AGENTS.md` — read it before making changes. The summary below is oriented toward getting productive quickly; `AGENTS.md` is the source of truth for constraints.

## Project Overview

Dish Dash is a Flutter app (single Dart codebase, Android/iOS, with Windows and macOS as development targets) that uses an on-device Gemma LLM to generate Korean delivery-food candidates, races ten of them in a Flame top-view game, and opens a deep link into Baemin or Coupang Eats for the winner.

Flow: boot Gemma in the background -> generate/validate 10 menu candidates with progress UI -> run the Flame race -> show winner + AI-generated comment -> let the user pick Baemin or Coupang Eats.

The app must stay fully usable in "DEMO MODE" (fallback menus) when the model or native runtime is unavailable — this is a PBL demo project and that path gets exercised often.

## Commands

```powershell
flutter pub get
flutter analyze
flutter test
flutter test test/menu_parser_test.dart   # single test file
flutter run -d windows                    # fastest UI/game iteration loop
flutter run -d <android-device-id>        # required for real Gemma inference (arm64-v8a only)
flutter build apk --debug
flutter build apk --release
```

Required verification after a change (see `AGENTS.md` "Required Verification" for the full matrix): run `flutter analyze` and `flutter test` after any Dart/Flutter behavior change; also run both `flutter build apk` variants after Android/plugin config changes. Real model inference and deep-link behavior can only be verified on an arm64 physical device/iPhone — always state in your summary which physical-device checks you could not perform.

Model files (`.litertlm`) are never committed and never bundled as assets. Install one for local Android testing with `scripts/install_model_android.ps1 -ModelPath <path>`; expected runtime path is `Documents/models/gemma-4-e2b-it.litertlm` (see `buildModelPath` in `lib/src/menu_generator.dart`).

## Architecture

Five files under `lib/src/`, wired together by `lib/main.dart`:

- **`app_controller.dart`** — `AppController` (a `ChangeNotifier`) is the single state owner. It drives `AppStage`: `booting -> ready -> generating -> racing -> result`. UI is just an `AnimatedBuilder` over this controller (see `app.dart`'s `DishDashApp.build`, which switches on `controller.stage`). `finishRace` is guarded to only act when `stage == AppStage.racing`, making winner selection idempotent against duplicate finish events from the race.
- **`menu_generator.dart`** — Defines the `MenuGenerator` interface (`modelPath`, `initialize`, `generate`, `generateWinnerComment`, `dispose`) and the only implementation, `FlutterGemmaMenuGenerator`. All LLM/native-runtime access is funneled through this interface; `AppController` never talks to `flutter_gemma` directly. The generation pipeline runs up to `maxGenerationRounds` rounds of generate-then-validate (two separate chats/prompts: a generation prompt asking for `generatedMenuCount` candidates, then a validation prompt that returns which numbered candidates passed), accumulating into `accepted` until it has `raceMenuCount` (10) menus, then shuffles and returns exactly that many. Falls back via `fallbackMenus` if validation can't fill the quota. GPU backend is tried first; on failure it retries on CPU (`initialize()`). A fresh `InferenceChat` is created per call and closed in a `finally` so prior output never leaks into the next race.
- **`race_game.dart`** — `DishDashGame` (Flame `FlameGame`) owns the actual race simulation (racer movement, collisions, standings, countdown) and reports back to the UI via `onStandingsChanged`/`onCountdownChanged`/`onWinner` callbacks — it has no knowledge of `AppController`.
- **`app.dart`** — All UI screens (`_BootScreen`, `_StartScreen`, `_LoadingScreen`, `_RaceScreen`, `_ResultScreen`) plus the shared retro-arcade visual primitives (`_PixelFrame`, `_Shell`, `_GridPainter`, the `ink`/`cream`/`tomato`/`mustard`/`mint` palette constants). `_RaceScreen` bridges Flame's per-frame callbacks into Flutter state via a coalescing `addPostFrameCallback` pattern (`_queueStandings`/`_scheduleFrameUpdate`) to avoid setState-during-build issues.
- **`delivery_launcher.dart`** — `openDeliveryApp` tries a deep-link search URL first (only Baemin has one; Coupang Eats has none), then falls back to copying the food name to clipboard + opening the app's home scheme, then falls back further to the platform store listing.

Menu text parsing/normalization (`parseMenus`, `parseMenuCandidates`, `retainValidatedCandidates`, dedup via `_menuComparisonKey`) lives in `menu_generator.dart` as plain functions independent of UI and native runtime — this is what `test/menu_parser_test.dart` exercises directly without needing a real model.

## Key constraints worth knowing before editing

- Don't swap `flutter_gemma`, change the model family away from Gemma 4 E2B, add in-app model downloading, or bundle the model — these are explicit non-goals per `AGENTS.md`.
- Keep `parseMenus` always returning exactly 10 menus (padding from `fallbackMenus` if short) and never blocking the game on model absence/failure/timeout.
- Preserve portrait-only orientation, the five-color palette, and the two-button (Baemin/Coupang Eats) result screen with no replay/regeneration option.
- Android `minSdk` must stay >= 24; `.litertlm` inference only works on `arm64-v8a` (x86_64 emulators can't validate it), so the Android ABI filter stays restricted to `arm64-v8a`. iOS deployment target must stay >= 16 with CocoaPods statically linked; install the model on iOS via app file sharing into the `models` folder under Documents.
- macOS is a Gemma-capable dev target alongside Windows; `FlutterGemmaMenuGenerator.modelPath` there checks `$HOME/Documents/models/gemma-4-e2b-it.litertlm` before the Flutter app documents directory.
