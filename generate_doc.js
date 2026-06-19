const { Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, Table, TableRow, TableCell, WidthType, BorderStyle, TableOfContents, ShadingType, convertInchesToTwip, LevelFormat, Footer, PageNumber, NumberFormat } = require("docx");
const fs = require("fs");

// Helper functions
function heading1(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_1, spacing: { before: 400, after: 200 }, children: [new TextRun({ text, bold: true, size: 32, font: "맑은 고딕" })] });
}
function heading2(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 300, after: 150 }, children: [new TextRun({ text, bold: true, size: 26, font: "맑은 고딕" })] });
}
function heading3(text) {
  return new Paragraph({ heading: HeadingLevel.HEADING_3, spacing: { before: 200, after: 100 }, children: [new TextRun({ text, bold: true, size: 22, font: "맑은 고딕" })] });
}
function para(text, opts = {}) {
  return new Paragraph({ spacing: { after: 120, line: 360 }, ...opts, children: [new TextRun({ text, size: 20, font: "맑은 고딕", ...opts })] });
}
function bullet(text, level = 0) {
  return new Paragraph({ bullet: { level }, spacing: { after: 80, line: 340 }, children: [new TextRun({ text, size: 20, font: "맑은 고딕" })] });
}
function boldPara(label, value) {
  return new Paragraph({ spacing: { after: 120, line: 360 }, children: [
    new TextRun({ text: label, bold: true, size: 20, font: "맑은 고딕" }),
    new TextRun({ text: value, size: 20, font: "맑은 고딕" }),
  ]});
}
function makeArchRow(cells, bgColor) {
  const tableCells = cells.map(c => new TableCell({
    shading: { type: ShadingType.SOLID, color: bgColor },
    borders: {
      top:    { style: BorderStyle.SINGLE, size: 6, color: "1A5276" },
      bottom: { style: BorderStyle.SINGLE, size: 6, color: "1A5276" },
      left:   { style: BorderStyle.SINGLE, size: 6, color: "1A5276" },
      right:  { style: BorderStyle.SINGLE, size: 6, color: "1A5276" },
    },
    children: [
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 80, after: c.subtitle ? 40 : 80 }, children: [
        new TextRun({ text: c.title, bold: true, size: 18, font: "맑은 고딕" }),
      ]}),
      ...(c.subtitle ? [new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 0, after: 80 }, children: [
        new TextRun({ text: c.subtitle, size: 15, font: "맑은 고딕", color: "555555" }),
      ]})] : []),
    ],
  }));
  return new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, rows: [new TableRow({ children: tableCells })] });
}
function archArrow(label) {
  return new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 50, after: 50 }, children: [
    new TextRun({ text: label ? `▼  ${label}` : "▼", size: 18, font: "맑은 고딕", color: "2E4057" }),
  ]});
}
function monoLine(text) {
  return new Paragraph({ spacing: { after: 0, line: 240 }, children: [
    new TextRun({ text, size: 16, font: "Courier New" }),
  ]});
}

function makeCell(text, opts = {}) {
  return new TableCell({
    width: opts.width ? { size: opts.width, type: WidthType.PERCENTAGE } : undefined,
    shading: opts.header ? { type: ShadingType.SOLID, color: "2E4057" } : undefined,
    children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ text, size: 18, font: "맑은 고딕", bold: !!opts.header, color: opts.header ? "FFFFFF" : "000000" })] })],
  });
}

function simpleTable(headers, rows) {
  const headerRow = new TableRow({ children: headers.map(h => makeCell(h, { header: true })) });
  const dataRows = rows.map(r => new TableRow({ children: r.map(c => makeCell(c)) }));
  return new Table({ width: { size: 100, type: WidthType.PERCENTAGE }, rows: [headerRow, ...dataRows] });
}

// ── Build Document ──
const doc = new Document({
  styles: {
    default: {
      document: { run: { font: "맑은 고딕", size: 20 } },
    },
  },
  numbering: {
    config: [{
      reference: "heading-numbering",
      levels: [
        { level: 0, format: LevelFormat.DECIMAL, text: "%1.", alignment: AlignmentType.START },
        { level: 1, format: LevelFormat.DECIMAL, text: "%1.%2.", alignment: AlignmentType.START },
        { level: 2, format: LevelFormat.DECIMAL, text: "%1.%2.%3.", alignment: AlignmentType.START },
      ],
    }],
  },
  sections: [{
    properties: {
      page: {
        margin: { top: convertInchesToTwip(1), bottom: convertInchesToTwip(1), left: convertInchesToTwip(1.2), right: convertInchesToTwip(1.2) },
      },
    },
    footers: {
      default: new Footer({
        children: [new Paragraph({ alignment: AlignmentType.CENTER, children: [new TextRun({ children: [PageNumber.CURRENT], size: 18, font: "맑은 고딕" })] })],
      }),
    },
    children: [
      // ══════════════ 표지 ══════════════
      new Paragraph({ spacing: { before: 3000 }, alignment: AlignmentType.CENTER, children: [] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: "캡스톤디자인 프로젝트 보고서", size: 28, font: "맑은 고딕", color: "555555" })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 600 }, children: [new TextRun({ text: "Dish Dash", bold: true, size: 56, font: "맑은 고딕" })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 100 }, children: [new TextRun({ text: "On-Device LLM 기반 배달 메뉴 추천 레이싱 앱", size: 24, font: "맑은 고딕" })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 1200, after: 100 }, children: [new TextRun({ text: "2025", size: 22, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { before: 400 }, children: [] }),

      // ══════════════ 목차 ══════════════
      new Paragraph({ spacing: { before: 600 }, children: [new TextRun({ text: "목 차", bold: true, size: 32, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "1. 개요 ·················································· 2", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   1.1 프로젝트 소개 (제안 주제 및 목적)", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   1.2 주안점 (Key Point)", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   1.3 주요 기술", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "2. 요구사항 ·············································· 4", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   2.1 목적", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   2.2 범위", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   2.3 사용자 요구사항", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   2.4 시스템 요구사항", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "   2.5 기타 요구사항", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "3. 설계 ·················································· 7", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "4. 구현 ·················································· 10", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 80 }, children: [new TextRun({ text: "5. 검증 (성능 평가) ····································· 14", size: 20, font: "맑은 고딕" })] }),
      new Paragraph({ spacing: { after: 200 }, children: [new TextRun({ text: "6. 참고문헌 ·············································· 16", size: 20, font: "맑은 고딕" })] }),

      // ══════════════ 1. 개요 ══════════════
      heading1("1. 개요"),

      heading2("1.1 프로젝트 소개 (제안 주제 및 목적)"),
      boldPara("주제: ", "On-Device LLM 기반 배달 메뉴 추천 레이싱 앱 'Dish Dash'"),
      para("배달 앱 선택 장애를 해결하기 위해, 사용자의 기분이나 상황에 맞는 메뉴 카테고리를 선택하면 Google의 경량 LLM인 Gemma 4 E2B 모델이 기기 내에서(on-device) 직접 배달 가능한 메뉴 후보 7개를 생성하고, 이를 레트로 아케이드 스타일의 탑뷰 레이싱 게임으로 경주시켜 최종 1개 메뉴를 결정한 뒤, 배민 또는 쿠팡이츠 앱으로 바로 연결하는 Flutter 크로스플랫폼 모바일 앱입니다."),
      para("기존 배달 앱은 수백 가지 메뉴를 나열하여 오히려 선택을 어렵게 만드는 '선택 과부하(Choice Overload)' 문제가 있습니다. Dish Dash는 AI가 카테고리별 적절한 메뉴를 자동으로 추천하고, 게이미피케이션(레이싱)을 통해 결정 과정 자체를 즐거운 경험으로 전환함으로써 이 문제를 해소합니다."),

      boldPara("목적:", ""),
      bullet("배달 메뉴 선택에 소요되는 시간과 스트레스를 줄여주는 실용적인 모바일 앱 개발"),
      bullet("On-Device LLM(Gemma 4 E2B)의 모바일 환경 적용 가능성을 검증"),
      bullet("생성형 AI 출력의 유효성 검증(Validation) 파이프라인 설계 및 구현 경험"),
      bullet("게이미피케이션을 통한 사용자 경험(UX) 차별화 전략 실습"),
      bullet("Flutter 크로스플랫폼 개발 및 Flame 게임 엔진 통합 역량 확보"),

      heading2("1.2 주안점 (Key Point)"),
      bullet("On-Device 추론: 서버 없이 기기 내에서 LLM 추론을 완료하여 개인정보 보호 및 오프라인 사용 가능성 확보"),
      bullet("2단계 생성-검증 파이프라인: LLM이 생성한 메뉴 후보를 별도의 검증 채팅에서 다시 검수하여 환각(hallucination) 및 부적절한 메뉴를 필터링"),
      bullet("카테고리 기반 메뉴 생성: 한식, 중식, 일식, 양식, 동남아, 분식, 치킨/패스트푸드, 고기/구이, 국/찌개/탕 등 9개 카테고리별 맞춤 프롬프트 엔지니어링"),
      bullet("Graceful Degradation (DEMO MODE): 모델 파일이 없거나 추론 실패 시에도 폴백 메뉴로 전체 흐름이 정상 작동"),
      bullet("게이미피케이션 UX: 레트로 아케이드 스타일의 탑뷰 레이싱을 통해 메뉴 결정 과정을 재미있는 경험으로 전환"),
      bullet("딥링크 연동: 레이스 우승 메뉴를 배민/쿠팡이츠 앱의 검색 화면으로 즉시 전달"),

      heading2("1.3 주요 기술"),
      simpleTable(
        ["기술 영역", "기술/도구", "설명"],
        [
          ["프레임워크", "Flutter 3.44+", "Android/iOS 단일 코드베이스 크로스플랫폼 UI 프레임워크"],
          ["언어", "Dart 3.12+", "Flutter 공식 프로그래밍 언어, Null Safety 지원"],
          ["게임 엔진", "Flame 1.35", "Flutter 위에서 동작하는 경량 2D 게임 엔진"],
          ["On-Device LLM", "Gemma 4 E2B", "Google의 경량 언어 모델 (LiteRT 포맷, arm64 전용)"],
          ["LLM 런타임", "flutter_gemma 0.16.4", "Flutter에서 Gemma 모델 로드/추론을 위한 네이티브 플러그인"],
          ["프롬프트 엔지니어링", "커스텀 프롬프트", "카테고리별 생성·검증·코멘트 3종 프롬프트 설계"],
          ["상태 관리", "ChangeNotifier", "Flutter 내장 상태 관리 패턴 (외부 패키지 미사용)"],
          ["딥링크", "url_launcher 6.3", "배민/쿠팡이츠 앱 스킴 기반 딥링크 라우팅"],
          ["빌드/배포", "Gradle (Android), Xcode (iOS)", "arm64-v8a ABI 필터, CocoaPods 정적 링킹"],
        ]
      ),

      // ══════════════ 2. 요구사항 ══════════════
      heading1("2. 요구사항"),

      heading2("2.1 목적"),
      para("본 프로젝트의 목적은 사용자가 배달 음식 메뉴를 선택하는 데 겪는 어려움을 AI와 게이미피케이션을 결합하여 해결하는 모바일 앱을 개발하는 것입니다. 구체적으로 다음과 같은 목표를 달성합니다:"),
      bullet("On-Device LLM을 활용하여 네트워크 의존 없이 메뉴를 생성·추천할 수 있는 시스템 구축"),
      bullet("생성-검증 2단계 파이프라인을 통해 LLM 출력의 품질(실제 배달 가능한 메뉴)을 보장"),
      bullet("레트로 아케이드 레이싱이라는 게이미피케이션 요소로 선택 과정의 재미와 몰입감 제공"),
      bullet("레이스 결과를 배달 앱(배민, 쿠팡이츠)과 즉시 연동하여 사용자 행동 전환(conversion) 최소화"),

      heading2("2.2 범위"),
      heading3("2.2.1 포함 범위"),
      bullet("Android(arm64-v8a) 및 iOS(arm64) 모바일 플랫폼 지원"),
      bullet("Windows, macOS 데스크톱 개발 및 테스트 환경 지원"),
      bullet("9개 카테고리 기반 메뉴 생성 및 검증"),
      bullet("Flame 기반 7인 레이싱 게임 시뮬레이션"),
      bullet("배민/쿠팡이츠 딥링크 연동"),
      bullet("모델 부재 시 DEMO MODE 폴백"),

      heading3("2.2.2 제외 범위"),
      bullet("앱 내 모델 다운로드 기능 (모델은 수동 설치)"),
      bullet("사용자 계정/인증 시스템"),
      bullet("메뉴 주문 기능 (배달 앱으로 전환만 수행)"),
      bullet("서버 기반 AI 추론 (모든 추론은 기기 내에서 수행)"),
      bullet("레이스 결과 저장 및 히스토리 기능"),

      heading2("2.3 사용자 요구사항"),
      heading3("2.3.1 기능적 요구사항"),
      simpleTable(
        ["ID", "요구사항", "설명", "우선순위"],
        [
          ["FR-01", "카테고리 선택", "사용자는 9개 메뉴 카테고리(한식, 중식, 일식 등) 중 하나를 선택할 수 있다", "필수"],
          ["FR-02", "AI 메뉴 생성", "선택한 카테고리에 맞는 배달 가능한 메뉴 후보를 LLM이 자동 생성한다", "필수"],
          ["FR-03", "메뉴 검증", "생성된 메뉴를 별도 LLM 채팅으로 검증하여 실존하는 배달 메뉴만 통과시킨다", "필수"],
          ["FR-04", "레이싱 게임", "검증된 7개 메뉴가 탑뷰 레이싱으로 경주하여 우승 메뉴를 결정한다", "필수"],
          ["FR-05", "우승 코멘트", "LLM이 우승 메뉴에 대한 한 줄 감성 코멘트를 한국어로 생성한다", "선택"],
          ["FR-06", "배달 앱 연동", "우승 메뉴를 배민 또는 쿠팡이츠 앱에서 검색/주문할 수 있도록 딥링크 전환한다", "필수"],
          ["FR-07", "DEMO MODE", "모델 파일 부재 시 폴백 메뉴로 전체 앱 흐름이 정상 작동한다", "필수"],
          ["FR-08", "실시간 순위판", "레이스 진행 중 7개 메뉴의 실시간 순위와 진행률을 표시한다", "필수"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("2.3.2 비기능적 요구사항"),
      simpleTable(
        ["ID", "요구사항", "설명", "기준"],
        [
          ["NFR-01", "응답 시간", "메뉴 생성부터 레이스 시작까지 소요 시간", "120초 이내 (타임아웃)"],
          ["NFR-02", "프라이버시", "사용자 데이터가 외부 서버로 전송되지 않음", "모든 추론 on-device"],
          ["NFR-03", "오프라인 사용", "네트워크 없이도 핵심 기능 사용 가능", "모델 설치 후 오프라인 작동"],
          ["NFR-04", "UI 반응성", "레이스 중 프레임 드랍 없이 부드러운 애니메이션", "60 FPS 유지"],
          ["NFR-05", "사용성", "직관적인 UI/UX로 별도 학습 없이 사용 가능", "3단계 이내 메뉴 결정"],
          ["NFR-06", "안정성", "LLM 오류, 타임아웃 등 예외 상황에서도 앱 크래시 없음", "Graceful fallback"],
          ["NFR-07", "접근성", "세로 화면 고정, 큰 텍스트, 고대비 색상 팔레트", "5색 팔레트 준수"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading2("2.4 시스템 요구사항"),
      heading3("2.4.1 개발 환경"),
      simpleTable(
        ["항목", "사양"],
        [
          ["Flutter SDK", "3.44.1 이상"],
          ["Dart SDK", "3.12.1 이상"],
          ["Android Studio / VS Code", "Flutter 플러그인 설치"],
          ["Xcode (iOS 빌드 시)", "15.0 이상"],
          ["Windows / macOS", "데스크톱 개발 타겟"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("2.4.2 실행 환경 (Android)"),
      simpleTable(
        ["항목", "사양"],
        [
          ["최소 API 레벨", "24 (Android 7.0)"],
          ["CPU 아키텍처", "arm64-v8a (필수)"],
          ["GPU", "OpenCL 지원 (GPU 가속 추론용)"],
          ["저장 공간", "모델 파일 포함 약 2GB 이상 여유"],
          ["RAM", "4GB 이상 권장"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("2.4.3 실행 환경 (iOS)"),
      simpleTable(
        ["항목", "사양"],
        [
          ["최소 iOS 버전", "16.0"],
          ["CPU 아키텍처", "arm64 (A11 Bionic 이상 권장)"],
          ["저장 공간", "모델 파일 포함 약 2GB 이상 여유"],
          ["모델 설치", "Finder 파일 공유를 통한 수동 설치"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading2("2.5 기타 요구사항"),
      heading3("2.5.1 비용"),
      bullet("서버 비용: 없음 (모든 추론은 on-device에서 수행)"),
      bullet("API 비용: 없음 (외부 AI API 미사용)"),
      bullet("LLM 모델: Google Gemma 4 E2B (오픈 소스, 무료)"),
      bullet("개발 도구: Flutter/Dart (오픈 소스, 무료), Flame (MIT 라이선스)"),
      bullet("배포: Google Play / App Store 개발자 등록비만 필요"),

      heading3("2.5.2 품질"),
      bullet("메뉴 품질: 2단계 생성-검증 파이프라인으로 환각 메뉴 필터링, 카테고리별 제외 규칙 적용"),
      bullet("코드 품질: flutter analyze 정적 분석 통과, flutter_lints 5.0.0 준수"),
      bullet("테스트 품질: 30개 단위 테스트로 메뉴 파싱·검증·프롬프트 로직 커버리지 확보"),
      bullet("UI 품질: 레트로 아케이드 5색 팔레트 일관성, 세로 화면 고정, 플랫폼 적응형 위젯"),

      heading3("2.5.3 제약사항"),
      bullet("모델 파일(.litertlm)은 앱에 번들되지 않으며 사용자가 수동으로 설치해야 함"),
      bullet("x86_64 에뮬레이터에서는 LLM 추론이 불가능 (arm64 물리 기기 필요)"),
      bullet("flutter_gemma 0.16.4 버전 고정 (상위 호환성 미보장)"),
      bullet("Gemma 4 E2B 모델 패밀리 외 다른 모델 사용 불가"),

      // ══════════════ 3. 설계 ══════════════
      heading1("3. 설계"),

      heading2("3.1 시스템 아키텍처"),
      para("Dish Dash는 단일 Flutter 코드베이스로 구성되며, 5개의 핵심 소스 파일과 1개의 진입점 파일로 이루어진 간결한 아키텍처를 채택합니다."),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 180, after: 100 }, children: [
        new TextRun({ text: "[그림 3-1]  시스템 아키텍처 구조도", size: 17, font: "맑은 고딕", italics: true, color: "444444" }),
      ]}),
      makeArchRow([{ title: "main.dart", subtitle: "앱 진입점 · 세로 화면 고정" }], "D4E6F1"),
      archArrow(),
      makeArchRow([{ title: "app.dart  (UI 계층)", subtitle: "_BootScreen  ·  _StartScreen  ·  _LoadingScreen  ·  _RaceScreen  ·  _ResultScreen" }], "D6EAF8"),
      archArrow("AnimatedBuilder  (상태 구독)"),
      makeArchRow([{ title: "app_controller.dart  (상태 머신)", subtitle: "AppStage · ChangeNotifier" }], "D1F2EB"),
      archArrow("generate() / onWinner callback"),
      makeArchRow([
        { title: "menu_generator.dart", subtitle: "AI 엔진 · Gemma 4 E2B" },
        { title: "race_game.dart",      subtitle: "Flame 탑뷰 레이싱" },
        { title: "delivery_launcher.dart", subtitle: "딥링크 · 배달 앱 연동" },
      ], "FEF9E7"),
      new Paragraph({ spacing: { after: 240 }, children: [] }),

      heading3("3.1.1 모듈 구조"),
      simpleTable(
        ["모듈", "파일", "책임"],
        [
          ["진입점", "main.dart (11줄)", "앱 초기화, 세로 화면 고정, DishDashApp 실행"],
          ["상태 관리", "app_controller.dart (162줄)", "AppStage 상태 머신, 메뉴 생성 파이프라인 조율, ChangeNotifier 기반"],
          ["UI", "app.dart (902줄)", "5개 화면(Boot, Start, Loading, Race, Result), 레트로 아케이드 시각 컴포넌트"],
          ["AI 엔진", "menu_generator.dart (677줄)", "MenuGenerator 인터페이스, LLM 초기화/생성/검증, 메뉴 파싱"],
          ["게임 엔진", "race_game.dart (489줄)", "Flame 기반 7인 탑뷰 레이싱 시뮬레이션"],
          ["딥링크", "delivery_launcher.dart (45줄)", "배민/쿠팡이츠 앱 딥링크 라우팅"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("3.1.2 앱 상태 흐름 (State Machine)"),
      para("AppController는 5단계 상태 머신(AppStage)으로 앱 전체 흐름을 제어합니다:"),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 120, after: 80 }, children: [
        new TextRun({ text: "[그림 3-2]  AppStage 상태 전이 다이어그램", size: 17, font: "맑은 고딕", italics: true, color: "444444" }),
      ]}),
      monoLine("  ┌─────────┐    ┌───────┐    ┌────────────┐    ┌────────┐    ┌────────┐"),
      monoLine("  │ booting │──▶ │ ready │──▶ │ generating │──▶ │ racing │──▶ │ result │"),
      monoLine("  └─────────┘    └───────┘    └────────────┘    └────────┘    └────────┘"),
      monoLine("  Gemma 초기화   카테고리      메뉴 생성·검증    레이싱 게임   우승+딥링크"),
      monoLine("                 선택"),
      new Paragraph({ spacing: { after: 160 }, children: [] }),
      bullet("booting: Gemma 모델 백그라운드 초기화 (GPU 시도 → 실패 시 CPU 폴백)"),
      bullet("ready: 카테고리 선택 화면 (AI READY 또는 DEMO MODE 표시)"),
      bullet("generating: LLM이 메뉴 후보를 생성·검증하는 로딩 화면 (최대 120초 타임아웃)"),
      bullet("racing: Flame 레이싱 게임 실행, 실시간 순위판 표시"),
      bullet("result: 우승 메뉴 + AI 코멘트 + 배민/쿠팡이츠 버튼"),

      heading2("3.2 메뉴 생성-검증 파이프라인"),
      para("LLM 출력의 품질을 보장하기 위해 2단계 파이프라인을 설계합니다:"),

      heading3("3.2.1 1단계: 메뉴 생성 (Generation)"),
      bullet("카테고리별 맞춤 프롬프트로 14개 메뉴 후보 요청 (temperature=0.65)"),
      bullet("프롬프트에 카테고리 설명, 예시, 제외 항목, 명명 규칙 포함"),
      bullet("정규식으로 번호 매기기 형식(1. 메뉴명) 파싱"),
      bullet("유니코드 정규화 및 중복 제거"),

      heading3("3.2.2 2단계: 메뉴 검증 (Validation)"),
      bullet("생성된 후보를 별도 LLM 채팅에서 검증 (temperature=0.2, 보수적)"),
      bullet("각 후보의 실존 여부, 카테고리 적합성, 배달 가능성 판단"),
      bullet("'통과' 판정된 후보만 최종 수락"),
      bullet("부족 시 2라운드까지 재시도, 그래도 부족하면 카테고리 폴백 메뉴로 패딩"),

      heading3("3.2.3 프롬프트 설계 원칙"),
      bullet("각 프롬프트 1,000자 이내 (경량 모델 토큰 효율성)"),
      bullet("생성·검증·코멘트 3종 프롬프트 분리 (역할 명확화)"),
      bullet("매 호출마다 새로운 InferenceChat 생성 (컨텍스트 오염 방지)"),

      heading2("3.3 레이싱 게임 설계"),
      bullet("Flame FlameGame + HasCollisionDetection 기반 탑뷰 레이싱"),
      bullet("7개 레이서가 개별 레인에서 출발, 무작위 속도 변동(118-188 px/frame)"),
      bullet("카메라가 상위 3명의 평균 위치를 추적 (최대 540 px/s 부드러운 팔로우)"),
      bullet("결승선 통과 시 첫 번째 레이서만 우승자로 판정 (멱등성 보장)"),
      bullet("0.2초마다 순위 업데이트를 UI에 전달 (PostFrameCallback 코얼레싱 패턴)"),

      heading2("3.4 딥링크 설계"),
      para("3단계 폴백 체인으로 배달 앱 연동의 안정성을 확보합니다:"),
      bullet("1차: 검색 딥링크 (배민: baemin://search?search_query=메뉴명)"),
      bullet("2차: 홈 스킴 + 클립보드 복사 (배민: baemin://, 쿠팡이츠: coupangeats://)"),
      bullet("3차: 앱스토어/플레이스토어 링크"),

      heading2("3.5 UI/UX 설계"),
      bullet("레트로 아케이드 컨셉의 5색 팔레트: ink(#171612), cream(#FFF1D0), tomato(#E94F37), mustard(#F6AE2D), mint(#2EC4B6)"),
      bullet("세로 화면 고정 (portrait only)"),
      bullet("플랫폼 적응형 위젯 (iOS: Cupertino, Android: Material)"),
      bullet("AnimatedBuilder 기반 반응형 UI (AppController 상태 변화에 자동 갱신)"),

      // ══════════════ 4. 구현 ══════════════
      heading1("4. 구현"),

      heading2("4.1 프로젝트 구성"),
      simpleTable(
        ["파일", "코드 줄 수", "역할"],
        [
          ["lib/main.dart", "11", "앱 진입점"],
          ["lib/src/app_controller.dart", "162", "상태 관리 컨트롤러"],
          ["lib/src/app.dart", "902", "전체 UI 화면 및 컴포넌트"],
          ["lib/src/menu_generator.dart", "677", "LLM 인터페이스 및 메뉴 파싱"],
          ["lib/src/race_game.dart", "489", "Flame 레이싱 게임"],
          ["lib/src/delivery_launcher.dart", "45", "딥링크 라우팅"],
          ["test/menu_parser_test.dart", "445", "단위 테스트"],
          ["합계", "2,731", ""],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading2("4.2 핵심 구현 상세"),

      heading3("4.2.1 AppController (상태 관리)"),
      para("AppController는 ChangeNotifier를 확장하여 앱의 단일 상태 소유자(single source of truth) 역할을 합니다. AppStage 열거형으로 5단계 상태 전환을 관리하며, UI는 AnimatedBuilder를 통해 상태 변화를 구독합니다."),
      bullet("initialize(): Gemma 모델 초기화 시도, 실패 시 warning 설정 및 DEMO MODE 전환"),
      bullet("generateMenus(): 120초 타임아웃 내에서 메뉴 생성 파이프라인 실행, 스트림 토큰 수신"),
      bullet("finishRace(): stage == racing일 때만 동작하는 멱등성 가드로 중복 완주 이벤트 방지"),
      bullet("_generateWinnerComment(): 우승 메뉴에 대한 AI 코멘트를 토큰 단위로 스트리밍하여 실시간 표시"),

      heading3("4.2.2 MenuGenerator (AI 엔진)"),
      para("MenuGenerator 인터페이스를 정의하고 FlutterGemmaMenuGenerator가 유일한 구현체로서 모든 LLM 접근을 캡슐화합니다."),
      bullet("modelPath: 플랫폼별 모델 경로 자동 해석 (macOS: ~/Documents/models/, 기타: 앱 문서 디렉토리)"),
      bullet("initialize(): GPU 백엔드 우선 시도, 실패 시 CPU 폴백, 최대 1024 토큰/1 동시 세션"),
      bullet("generate(): 비동기 제너레이터로 최대 2라운드 생성-검증 수행, 중복 제거 및 패밀리 제한 적용"),
      bullet("_runChat(): 호출마다 새 InferenceChat 생성, finally에서 반드시 닫기 (컨텍스트 오염 방지)"),

      heading3("4.2.3 메뉴 파싱 및 정규화"),
      para("메뉴 텍스트 파싱은 UI와 LLM 런타임에 독립적인 순수 함수로 구현되어 단위 테스트가 용이합니다."),
      bullet("parseMenuCandidates(): 정규식 ^\\s*\\d+\\.\\s*(.+?)\\s*$ 로 번호 매기기 형식 추출"),
      bullet("_normalizeMenuName(): 괄호, 슬래시, 설명 텍스트 제거"),
      bullet("_menuComparisonKey(): 소문자화, 공백/유니코드 공백/구두점 제거 후 비교 키 생성"),
      bullet("fillMenusWithFallback(): 양식 카테고리 패밀리 제한(파스타/피자/스테이크/리조또 각 최대 2개) 적용"),

      heading3("4.2.4 DishDashGame (레이싱 게임)"),
      para("Flame FlameGame을 확장한 DishDashGame이 7인 탑뷰 레이싱을 시뮬레이션합니다."),
      bullet("Racer 컴포넌트: 음식 카트 디자인(트레이, 바디, 스트라이프, 번호판, 바퀴, 속도선) 커스텀 Canvas 렌더링"),
      bullet("속도 시스템: 0.35~0.6초마다 118~188 px/frame 범위에서 무작위 속도 변경"),
      bullet("카메라: 상위 3명 레이서의 평균 Y좌표를 추적, 최대 540 px/s 부드러운 팔로우"),
      bullet("시각 효과: 사인파 바운스(13Hz), 좌우 흔들림(8Hz), 우승 시 별 버스트 애니메이션"),
      bullet("충돌: 물리적 충돌 없이 통과, 결승선은 비주얼 체커드 패턴"),

      heading3("4.2.5 UI 화면 구성"),
      simpleTable(
        ["화면", "위젯", "주요 기능"],
        [
          ["부팅", "_BootScreen", "Gemma 모델 로딩 상태 표시"],
          ["시작", "_StartScreen", "카테고리 선택 그리드, AI 상태 카드, RACE START 버튼"],
          ["로딩", "_LoadingScreen", "AI 메뉴 생성 중 스피너 및 진행 상태"],
          ["레이스", "_RaceScreen", "Flame 게임 뷰포트 + 2열 실시간 순위판"],
          ["결과", "_ResultScreen", "우승 메뉴, AI 코멘트, 배민/쿠팡이츠 버튼"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("4.2.6 딥링크 라우팅"),
      para("openDeliveryApp 함수는 DeliveryApp 열거형(baemin, coupangEats)과 음식 이름을 받아 3단계 폴백 체인으로 배달 앱을 실행합니다."),
      bullet("배민: baemin://search?search_query=<음식명> → baemin:// (클립보드 복사) → Play Store/App Store"),
      bullet("쿠팡이츠: coupangeats:// (클립보드 복사) → Play Store/App Store (검색 스킴 미지원)"),

      heading2("4.3 의존성 관리"),
      simpleTable(
        ["패키지", "버전", "용도"],
        [
          ["flame", "1.35.0", "2D 게임 엔진"],
          ["flutter_gemma", "0.16.4", "On-device Gemma LLM 런타임"],
          ["path_provider", "2.1.5", "앱 문서 디렉토리 접근"],
          ["url_launcher", "6.3.2", "딥링크 URL 실행"],
          ["flutter_lints", "5.0.0", "Dart 코드 분석 규칙 (dev)"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading2("4.4 에러 처리 및 폴백 전략"),
      simpleTable(
        ["상황", "처리"],
        [
          ["모델 파일 부재", "ModelMissingException → DEMO MODE 전환"],
          ["GPU 초기화 실패", "CPU 백엔드로 자동 재시도"],
          ["메뉴 생성 타임아웃 (120초)", "카테고리 폴백 메뉴 사용"],
          ["검증 응답 파싱 실패", "해당 라운드 0건 통과 처리, 다음 라운드 진행"],
          ["2라운드 후에도 메뉴 부족", "카테고리 폴백 메뉴로 패딩"],
          ["우승 코멘트 생성 실패/타임아웃", "한국어 기본 코멘트 사용"],
          ["딥링크 실패", "클립보드 복사 + 앱 홈 → 스토어 링크"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      // ══════════════ 5. 검증 (성능 평가) ══════════════
      heading1("5. 검증 (성능 평가)"),

      heading2("5.1 단위 테스트"),
      para("test/menu_parser_test.dart에 30개의 단위 테스트가 구현되어 있으며, LLM 런타임 없이 순수 파싱 로직만을 검증합니다."),

      simpleTable(
        ["테스트 영역", "테스트 수", "검증 내용"],
        [
          ["모델 경로 빌드", "1", "플랫폼별 모델 파일 경로 생성 정확성"],
          ["프롬프트 생성", "8", "카테고리별 프롬프트 내용, 크기 제한(1000자), 후속 라운드 프롬프트"],
          ["메뉴 파싱", "6", "번호 형식 추출, 정규화, 중복 제거, 유니코드 처리"],
          ["폴백 처리", "5", "카테고리별 폴백, 패밀리 제한, 빈 입력 처리"],
          ["검증 파싱", "6", "통과/실패 판정 추출, 엣지 케이스"],
          ["예외 처리", "2", "MenuValidationException 메시지 포맷"],
          ["상태 전환", "2", "AppStage 흐름, 코멘트 생성"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading2("5.2 정적 분석"),
      para("flutter analyze 명령으로 Dart 코드 정적 분석을 수행하며, flutter_lints 5.0.0 규칙 세트를 준수합니다. 모든 경고(warning) 및 오류(error) 0건을 유지합니다."),

      heading2("5.3 빌드 검증"),
      simpleTable(
        ["빌드 타겟", "명령어", "검증 항목"],
        [
          ["Android Debug APK", "flutter build apk --debug", "arm64-v8a ABI 필터, minSdk 24, OpenCL 설정"],
          ["Android Release APK", "flutter build apk --release", "ProGuard/R8 적용, 서명, 최적화"],
          ["iOS (Xcode)", "flutter build ios", "CocoaPods 정적 링킹, iOS 16+ 타겟"],
          ["Windows Desktop", "flutter run -d windows", "UI/게임 로직 빠른 이터레이션"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading2("5.4 성능 지표"),
      heading3("5.4.1 메뉴 생성 성능"),
      simpleTable(
        ["지표", "기준", "비고"],
        [
          ["생성 타임아웃", "120초", "AppController에서 스트림 레벨 타임아웃 적용"],
          ["라운드당 후보 수", "14개", "충분한 후보 풀 확보"],
          ["최대 라운드 수", "2", "부족 시 폴백 메뉴 사용"],
          ["생성 temperature", "0.65", "창의적 메뉴 생성"],
          ["검증 temperature", "0.2", "보수적 검증 판단"],
          ["코멘트 temperature", "0.75", "감성적 표현 생성"],
          ["최대 토큰 수", "1,024", "경량 모델 최적화"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("5.4.2 레이싱 게임 성능"),
      simpleTable(
        ["지표", "값", "비고"],
        [
          ["레이서 속도 범위", "118-188 px/frame", "무작위 변동으로 흥미 유발"],
          ["속도 변경 주기", "0.35-0.6초", "자연스러운 가감속"],
          ["순위 업데이트 주기", "0.2초 (5 FPS)", "UI 부담 최소화"],
          ["카메라 최대 속도", "540 px/s", "부드러운 추적"],
          ["월드 높이", "최소 1,360 px", "충분한 레이스 거리"],
          ["레이스 소요 시간", "8-14초", "적절한 몰입 시간"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      heading3("5.4.3 메뉴 품질 검증"),
      para("2단계 생성-검증 파이프라인의 효과를 다음과 같이 평가합니다:"),
      bullet("카테고리 적합성: 카테고리별 제외 규칙(예: 한식 카테고리에서 파스타 제외)이 프롬프트와 검증 모두에 적용"),
      bullet("중복 방지: _menuComparisonKey 기반 정규화로 공백/구두점/유니코드 차이에 따른 중복 방지"),
      bullet("패밀리 제한: 양식 카테고리에서 파스타/피자/스테이크/리조또 각 최대 2개로 다양성 보장"),
      bullet("폴백 안정성: 생성 실패 시 카테고리별 사전 정의된 폴백 메뉴 7개 보장"),

      heading2("5.5 기기별 검증 매트릭스"),
      simpleTable(
        ["플랫폼", "UI/게임", "LLM 추론", "딥링크", "비고"],
        [
          ["Android arm64 물리 기기", "검증 가능", "검증 가능", "검증 가능", "전체 기능 검증"],
          ["Android x86_64 에뮬레이터", "검증 가능", "불가 (DEMO MODE)", "제한적", "UI/게임 테스트만"],
          ["iOS arm64 물리 기기", "검증 가능", "검증 가능", "검증 가능", "전체 기능 검증"],
          ["iOS 시뮬레이터", "검증 가능", "불가 (DEMO MODE)", "불가", "UI/게임 테스트만"],
          ["Windows Desktop", "검증 가능", "검증 가능", "불가", "개발 이터레이션"],
          ["macOS Desktop", "검증 가능", "검증 가능", "불가", "개발 이터레이션"],
        ]
      ),
      new Paragraph({ spacing: { after: 200 }, children: [] }),

      // ══════════════ 6. 참고문헌 ══════════════
      heading1("6. 참고문헌"),
      para("[1] Google, \"Gemma: Open Models Based on Gemini Research and Technology,\" 2024."),
      para("[2] Flutter Team, \"Flutter Documentation,\" https://docs.flutter.dev/"),
      para("[3] Flame Engine, \"Flame - A Flutter Game Engine,\" https://flame-engine.org/"),
      para("[4] Google, \"LiteRT (formerly TensorFlow Lite) Documentation,\" https://ai.google.dev/edge/litert"),
      para("[5] Google, \"flutter_gemma - Flutter Plugin for Gemma,\" https://pub.dev/packages/flutter_gemma"),
      para("[6] Dart Team, \"Dart Programming Language,\" https://dart.dev/"),
      para("[7] Flutter Team, \"url_launcher Plugin,\" https://pub.dev/packages/url_launcher"),
      para("[8] Flutter Team, \"path_provider Plugin,\" https://pub.dev/packages/path_provider"),
      para("[9] Schwartz, B., \"The Paradox of Choice: Why More Is Less,\" Harper Perennial, 2004."),
      para("[10] Google, \"Gemma 4 Technical Report,\" 2025."),
    ],
  }],
});

(async () => {
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync("DishDash_프로젝트_보고서.docx", buffer);
  console.log("Document created: DishDash_프로젝트_보고서.docx");
})();
