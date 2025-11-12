# LangChain 슬라이드 파이프라인 테스트 계획

## 목표
- GPT-5 nano 기반 LangChain 파이프라인이 입력 컨텍스트에 따라 올바른 슬라이드를 생성하는지 검증
- Unsplash/Iconify 자산 추천 유틸이 프롬프트 기반 메타데이터를 정상 주입하는지 확인
- Firestore 연동 전 단계에서 슬라이드 편집 UI가 기대하는 데이터 구조를 유지하는지 보장

## 범위
1. `SlideGenerationService` + `Gpt5NanoClient`
2. `AssetSuggestionService`를 통한 이미지/아이콘 추천
3. `LangChainSlidePipeline` 통합 흐름 (자산 추천 포함/미포함)

## 테스트 유형
### 1. 단위 테스트
- `asset_suggestion_service_test.dart`
  - Unsplash 호출 실패 시 빈 배열 반환
  - Iconify 응답 파싱 확인 (Mock HTTP 클라이언트 사용)
  - `fetchSuggestions`가 image/icon 키를 모두 포함하는지 검증
- `langchain_slide_pipeline_test.dart`
  - `AssetSuggestionService` 미주입 시 슬라이드 메타데이터 변경 없음
  - 추천 서비스 주입 후 `metadata.assetSuggestions` 구조 확인
  - 추천 서비스 실패 시 graceful fallback

### 2. 통합 테스트 (Mock 기반)
- `slide_pipeline_integration_test.dart`
  - Mock `LlmClient`가 `_SlideDraft` JSON을 반환하도록 구성
  - Mock `AssetSuggestionService`가 예상 값을 반환
  - 파이프라인 실행 → `SlideData` 리스트 비교

### 3. 수동 QA 체크리스트
- Firestore에 생성된 슬라이드 문서에 `metadata.assetSuggestions.images/icons` 필드 존재 확인
- 에디터 UI에서 썸네일/아이콘 추천 목록이 표시되는지 확인
- 추천 API 키 미설정 시 경고 로그만 출력되고 파이프라인이 계속 동작하는지 확인

## 도구 & 환경
- Flutter test 프레임워크
- Mocktail 또는 Mockito를 이용한 HTTP/LLM Stub
- `.env` 또는 `--dart-define`을 통한 API 키 주입

## 향후 과제
- 실제 Unsplash/Iconify API와의 E2E 연동 테스트 (staging 프로젝트에서만 실행)
- 자산 추천 결과를 기반으로 사용자 선택 → Firestore 업데이트 흐름 검증

