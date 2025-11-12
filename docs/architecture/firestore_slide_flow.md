# Firestore 슬라이드 저장 & 편집 UI 동기화 흐름

## 1. 파이프라인 → Firestore 저장
1. `LangChainSlidePipeline.run`  
   - `SlideGenerationService`가 GPT-5 nano 응답을 `SlideData` 리스트로 변환  
   - `AssetSuggestionService`(옵션)가 이미지/아이콘 추천을 `metadata.assetSuggestions`에 병합
2. `LectureProject.copyWith(slides: ...)`  
   - 프로젝트 엔티티에 새 슬라이드 배열을 주입하고 `updatedAt` 갱신
3. `FirestoreProjectRepository.updateProject`  
   - `project.toJson()` → `_sanitizeForFirestore`  
   - `slides[n].metadata.assetSuggestions` 포함 전체 구조를 Cloud Firestore 문서로 업로드  
   - `updatedAt` 필드는 서버 타임스탬프로 재설정

> 참고: `_sanitizeForFirestore`가 `Map/List` 타입을 재귀적으로 처리하므로 `assetSuggestions.images/icons` 배열도 그대로 유지됩니다.

## 2. Firestore → 편집 UI 로딩
1. `FirestoreProjectRepository.watchProject`  
   - `LectureProject.fromJson` 호출  
   - `SlideData.fromJson`이 `metadata`와 `speakerNotes`, `elements`를 복원
2. `EditableSlideCanvas`  
   - Provider/StateNotifier가 `slides` 배열을 상태로 보관  
   - `metadata.assetSuggestions.images`는 썸네일 그리드, `metadata.assetSuggestions.icons`는 아이콘 피커에 전달

## 3. 편집 시나리오
| 액션 | 로컬 상태 변화 | Firestore 반영 |
|------|----------------|----------------|
| 텍스트 수정 | `SlideElement` 교체 → `SlideData.copyWith(elements: ...)` | `FirestoreProjectRepository.updateProject` (전체 프로젝트 업sert) |
| 자산 교체 | `metadata.assetSuggestions`에서 선택한 URL → `SlideElement` 또는 `metadata` 업데이트 | 동일 |
| 슬라이드 순서 변경 | `List<SlideData>` reorder → 각 슬라이드 `order` 업데이트 | 동일 |
| 슬라이드 삭제 | `slides.removeAt(index)` → 상태 업데이트 | `updateProject`로 저장 |

> 향후 최적화  
> - 슬라이드 단위 서브 컬렉션(`projects/{id}/slides/{slideId}`)으로 분리해 부분 업데이트 지원  
> - `metadata.assetSuggestions` 크기가 커질 경우 TTL 필드(`metadata.assetSuggestionsExpiresAt`) 도입 검토

## 4. 오류 및 복구
- Firestore 쓰기 실패 시 `_executeWithRetry`가 최대 3회 재시도  
- 재시도 실패 시 UI에 에러 노출 + 로컬 `LocalProjectRepository`(캐시)로 롤백 가능  
- `assetSuggestions`가 비어도 파이프라인은 계속 진행하며 편집 UI는 해당 섹션을 비활성화

## 5. 테스트 포인트
- 파이프라인 통합 테스트: `SlideData.metadata.assetSuggestions` 구조 검증  
- Firestore 저장/로드 단위 테스트: `_sanitizeForFirestore`가 Map/List/DateTime을 올바르게 처리하는지 확인  
- 위젯 테스트: `EditableSlideCanvas`가 Firestore에서 내려온 슬라이드로 초기화 → 편집 → 저장 액션 시 상태/Firestore 싱크 확인

