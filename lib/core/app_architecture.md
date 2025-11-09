# 강의 영상 제작 플랫폼 아키텍처

## 📁 프로젝트 구조

```
lib/
├── core/                   # 핵심 시스템
│   ├── constants/         # 상수, 설정
│   ├── utils/            # 유틸리티 함수
│   ├── exceptions/       # 커스텀 예외
│   └── extensions/       # 확장 함수
│
├── data/                  # 데이터 레이어
│   ├── models/           # 데이터 모델
│   │   ├── project.dart
│   │   ├── avatar.dart
│   │   ├── script.dart
│   │   ├── slide.dart
│   │   ├── video.dart
│   │   ├── asset.dart
│   │   └── brand_kit.dart
│   │
│   ├── repositories/     # 데이터 저장소
│   └── datasources/      # 로컬/원격 데이터 소스
│
├── domain/               # 비즈니스 로직
│   ├── entities/        # 엔티티
│   ├── usecases/        # 사용 사례
│   └── repositories/    # 추상 저장소
│
├── services/             # 외부/백엔드 연계 서비스
│   ├── ai/
│   │   └── slide_ai_service.dart     # 슬라이드/대본 AI 생성
│   └── avatar/
│       └── avatar_audio_service.dart # 아바타 음성 미리듣기 스텁
│
├── presentation/         # UI 레이어
│   ├── pages/           # 페이지/스크린
│   │   ├── home/
│   │   ├── project/
│   │   ├── editor/
│   │   ├── preview/
│   │   └── export/
│   │
│   ├── widgets/         # 공통 UI 컴포넌트
│   │   └── common/
│   └── providers/       # Riverpod 상태 관리
│
└── main.dart
```

## 🔧 기술 스택 (현 구현 기준)

- **UI 프레임워크**: Flutter Web (Material 2 테마 기반 커스텀)
- **상태관리**: Riverpod + code generation (`riverpod_annotation`)
- **데이터 저장소**
  - Firebase Firestore (인증 사용자 프로젝트)
  - Local Project Repository (비인증/게스트 사용자)
- **AI 연동**: `SlideAIService` (OpenAI API 스텁) / 후속 확장 예정
- **아바타/오디오**: `AvatarAudioService` (HeyGen/TTS 연동 스텁)
- **인증**: Firebase Authentication (Google Sign-In)

## 🎯 기능 플로우 (현재 단계)

1. **프로젝트 생성**
   - HomePage 위저드 → 프로젝트 메타데이터 입력 → Firestore/로컬 저장
2. **에디터 진입**
   - 좌측: SlideGenerationPanel에서 프롬프트 입력 후 AI 슬라이드 생성
   - 중앙: SlidePreviewPanel에서 선택 슬라이드 미리보기/콘텐츠 확인
   - 하단: SlideListPanel로 슬라이드 추가/삭제/재정렬
   - 우측: EditorContextPanel 탭 (콘텐츠/디자인/스크립트/에셋)
     - 스크립트 탭: AI 대본 생성, 아바타 음성 미리듣기 UI 제공
3. **데이터 흐름**
   - `projectByIdProvider(projectId)` → `EditorPage`에서 프로젝트 스트림 구독
   - 슬라이드 CRUD/AI 결과는 `projectListProvider.notifier.updateProject` 통해 저장
   - 로컬 상태(`currentProjectProvider`)는 Firestore 반영 후 UI 즉시 갱신

## 🧭 에디터 레이아웃 개요

```
+--------------------------------------------------------------------------------+
| SlideGenerationPanel |         SlidePreviewPanel         |  EditorContextPanel |
|  (좌측 AI 도우미)   |  (중앙 미리보기 & 콘텐츠)         |   (우측 탭 패널)   |
+--------------------------------------------------------------------------------+
|                               SlideListPanel                                 |
|                         (슬라이드 썸네일 그리드)                             |
+--------------------------------------------------------------------------------+
```

- **SlideGenerationPanel**: 프롬프트/키워드 입력, AI 생성 상태 처리
- **SlidePreviewPanel**: 선택 슬라이드 요소, 보조 요약 정보 표시
- **EditorContextPanel**: 탭별 편집 UI
  - 콘텐츠: 제목/핵심 포인트 CRUD
  - 디자인: 레이아웃/컬러/이미지 추천 placeholder
  - 스크립트: AI 대본 생성, 아바타 음성 미리듣기
  - 에셋: 아바타/이미지 placeholder
- **SlideListPanel**: 드래그 기반 순서 조정, 삭제/추가 버튼

## 📡 상태 관리 개요

```
projectListProvider ─┬─ add/update/removeProject()
                     │
                     └─ projectByIdProvider(projectId) ─→ EditorPage

currentProjectProvider: UI 캐시용 선택 프로젝트
effectiveUserIdProvider: 인증/비인증 사용자 구분
authServiceProvider: Firebase Auth 처리
projectRepositoryProvider: Firestore vs Local 저장소 결정
```

### 상태 관리 의존 관계 (세부)

| Provider | 역할 | 의존성 / 참고 |
| --- | --- | --- |
| `authServiceProvider` | Firebase Auth 인스턴스 | Firebase 초기화 이후 사용 |
| `authStateChangesProvider` | 인증 상태 스트림 | `authServiceProvider` |
| `currentUserProvider` | 로그인 사용자 정보 | `authStateChangesProvider` |
| `currentUserIdProvider` | 로그인 UID | `currentUserProvider` |
| `effectiveUserIdProvider` | 인증/게스트 사용자 ID 라우팅 | `currentUserIdProvider`, 로컬 Fallback ID |
| `projectRepositoryProvider` | Firestore / Local 저장소 선택 | `effectiveUserIdProvider`, `authStateChangesProvider` |
| `projectListProvider` | 프로젝트 리스트 로딩/캐싱 | `projectRepositoryProvider` |
| `projectByIdProvider` | 단일 프로젝트 스트림 | `projectRepositoryProvider`, `effectiveUserIdProvider` |
| `currentProjectProvider` | 에디터 UI에서 선택된 프로젝트 | `projectListProvider` 갱신을 수신 |
| `projectCreationProvider` 등 | 프로젝트 생성/AI 연동 등 상태 | 위의 기본 Provider 들을 조합 |

→ Provider간 순환 의존이 없도록 유지하고, 신규 기능 추가 시 위 표에 업데이트합니다.

## 🧱 공통 UI 컴포넌트 현황

- `presentation/widgets/common/`
  - `custom_app_bar.dart` : 상단 앱바 공통 스타일  
  - `empty_state.dart` : 비어 있는 리스트/검색 결과 안내  
  - `login_required_dialog.dart` : 로그인 안내 모달  
  - `project_card.dart` : 프로젝트 카드 UI
- 향후 추출 예정
  - 반복되는 섹션 헤더, 정보 카드 (`_SectionTitle`, `_PlaceholderCard` 등) → 별도 파일로 승격 검토
  - 다이얼로그/토스트 스타일 통합 (`_showSnackBar` 유틸화)

## 🗺️ 향후 확장 포인트 (계획)

- AI/아바타 실제 API 연동 (`SlideAIService`, `AvatarAudioService` 교체)
- 스크립트 버전 관리, 디자인 템플릿, 에셋 라이브러리, 렌더링 파이프라인 연결
- 협업/권한 관리 및 프로젝트 공유 기능
