# Cloud Tasks 통합 가이드

## 🎯 개요

Cloud Tasks를 사용하여 **수시간 소요되는 비디오 생성 작업**을 안정적으로 처리합니다.

### 핵심 개선사항

| 항목 | 이전 (비동기) | 현재 (Cloud Tasks) |
|------|--------------|-------------------|
| **최대 처리 시간** | 60분 (Cloud Run 제한) | 무제한 (수시간~수십시간) |
| **HTTP 연결** | 유지 필요 | 즉시 종료 |
| **동시 처리** | 제한적 | 1000개 동시 가능 |
| **재시도** | 수동 | 자동 (최대 3회) |
| **비용** | 대기 시간 과금 | 실행 시간만 과금 |

## 🏗️ 아키텍처

```
Flutter App
    ↓
POST /generate-with-tasks (이미지 + 오디오)
    ↓
Backend API
    ├─ Firestore에 작업 생성
    ├─ Cloud Task 생성
    └─ 즉시 jobId 응답 (HTTP 종료) ✅
         ↓
Cloud Tasks 큐
    └─ 워커 호출 예약
         ↓
POST /worker/process-avatar
    ├─ 아바타 생성 (10분)
    ├─ 비디오 요청 (5분)
    └─ 폴링 (수시간, 10분마다)
         ├─ Firestore 업데이트
         └─ 완료 시 URL 저장
              ↓
Flutter App (Firestore 실시간 리스닝)
    └─ 자동으로 완료 감지
```

## 📋 사전 준비

### 1. Google Cloud 프로젝트 설정

```bash
# 1. 프로젝트 ID 확인
gcloud config get-value project

# 2. Cloud Tasks API 활성화
gcloud services enable cloudtasks.googleapis.com

# 3. Cloud Run API 활성화 (배포용)
gcloud services enable run.googleapis.com
```

### 2. Cloud Tasks 큐 생성

```bash
# 스크립트 실행 권한 부여
chmod +x setup-cloud-tasks.sh

# 큐 생성 (프로젝트 ID 입력)
./setup-cloud-tasks.sh your-project-id asia-northeast3
```

**수동으로 생성:**
```bash
gcloud tasks queues create video-generation-queue \
  --location=asia-northeast3 \
  --max-concurrent-dispatches=1000 \
  --max-dispatches-per-second=100 \
  --max-attempts=3 \
  --min-backoff=60s \
  --max-backoff=3600s
```

### 3. 환경 변수 설정

`.env` 파일에 다음 추가:

```bash
# VisionStory API
VISIONSTORY_API_KEY=sk-vs-xxxxx
VISIONSTORY_API_BASE=https://openapi.visionstory.ai

# Google Cloud
GOOGLE_CLOUD_PROJECT=your-project-id
CLOUD_TASKS_LOCATION=asia-northeast3
CLOUD_TASKS_QUEUE=video-generation-queue

# Worker URL (로컬 테스트)
WORKER_URL=http://localhost:5001
```

## 🚀 로컬 테스트

### 1. 백엔드 서버 실행

```bash
cd server/visionstory_backend
npm install
node src/index.js
```

### 2. 로컬에서 Cloud Tasks 테스트

**주의**: 로컬에서는 Cloud Tasks가 워커를 직접 호출하지 못합니다.

**해결책 A: ngrok 사용**
```bash
# ngrok 설치
brew install ngrok

# ngrok 실행 (다른 터미널)
ngrok http 5001

# .env 업데이트
WORKER_URL=https://xxxx.ngrok.io
```

**해결책 B: 직접 워커 호출 (개발용)**
```bash
# 1. /generate-with-tasks 호출하여 jobId 받기
curl -X POST http://localhost:5001/generate-with-tasks \
  -F "image=@test.jpg" \
  -F "audio=@test.wav"
# → { "jobId": "abc123" }

# 2. 워커 직접 호출
curl -X POST http://localhost:5001/worker/process-avatar \
  -H "Content-Type: application/json" \
  -d '{"jobId":"abc123","imagePath":"...","audioPath":"..."}'
```

### 3. Flutter 앱 테스트

```bash
flutter run -d chrome
```

진행 상황 확인:
- Firestore 콘솔에서 `avatarJobs/{jobId}` 문서 확인
- Flutter 앱에서 실시간 진행률 표시

## ☁️ Cloud Run 배포

### 1. Dockerfile 확인

이미 생성되어 있습니다: `server/visionstory_backend/Dockerfile`

### 2. 배포

```bash
# Google Cloud 프로젝트 설정
export PROJECT_ID=your-project-id

# 컨테이너 빌드 및 업로드
gcloud builds submit --tag gcr.io/$PROJECT_ID/visionstory-backend

# Cloud Run에 배포
gcloud run deploy visionstory-backend \
  --image gcr.io/$PROJECT_ID/visionstory-backend \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --timeout=3600s \
  --memory=1Gi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --set-env-vars VISIONSTORY_API_KEY=$VISIONSTORY_API_KEY \
  --set-env-vars VISIONSTORY_API_BASE=https://openapi.visionstory.ai \
  --set-env-vars GOOGLE_CLOUD_PROJECT=$PROJECT_ID \
  --set-env-vars CLOUD_TASKS_LOCATION=us-central1 \
  --set-env-vars CLOUD_TASKS_QUEUE=video-generation-queue \
  --set-env-vars WORKER_URL=https://visionstory-backend-xxxx-uc.a.run.app
```

**중요**: `WORKER_URL`은 배포 후 생성된 URL로 업데이트해야 합니다.

### 3. 환경 변수 업데이트

```bash
# 배포된 URL 확인
gcloud run services describe visionstory-backend \
  --region us-central1 \
  --format="value(status.url)"

# WORKER_URL 업데이트
export SERVICE_URL=$(gcloud run services describe visionstory-backend --region us-central1 --format="value(status.url)")

gcloud run services update visionstory-backend \
  --region us-central1 \
  --set-env-vars WORKER_URL=$SERVICE_URL
```

### 4. Flutter 앱 URL 변경

```dart
// lib/presentation/pages/instructor/instructor_profile_page.dart
static const _backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://visionstory-backend-xxxx-uc.a.run.app',
);
```

또는 실행 시:
```bash
flutter run -d chrome --dart-define=BACKEND_URL=https://your-service.run.app
```

## 📊 작동 확인

### 1. API 테스트

```bash
# Health check
curl https://your-service.run.app/health

# 작업 생성
curl -X POST https://your-service.run.app/generate-with-tasks \
  -F "image=@test.jpg" \
  -F "audio=@test.wav" \
  -F "userId=test_user" \
  -F "instructorName=홍길동" \
  -F "instructorBio=테스트"

# 응답 예시:
# {
#   "success": true,
#   "jobId": "abc123",
#   "message": "아바타 생성 작업이 큐에 추가되었습니다..."
# }

# 작업 상태 확인
curl https://your-service.run.app/jobs/abc123
```

### 2. Cloud Tasks 큐 확인

```bash
# 큐 상태
gcloud tasks queues describe video-generation-queue \
  --location=us-central1

# 대기 중인 작업
gcloud tasks list \
  --queue=video-generation-queue \
  --location=us-central1
```

### 3. Firestore 확인

Firebase Console → Firestore → `avatarJobs` 컬렉션

```javascript
{
  jobId: "abc123",
  status: "processing",
  progress: {
    currentStep: "video_generation",
    stepNumber: 3,
    message: "비디오 생성 중... (120분 경과)"
  }
}
```

## 🔧 트러블슈팅

### 문제 1: "Cloud Tasks API has not been used"

```bash
gcloud services enable cloudtasks.googleapis.com --project=your-project-id
```

### 문제 2: "Permission denied"

Cloud Run 서비스 계정에 Cloud Tasks 권한 추가:

```bash
# 서비스 계정 확인
gcloud run services describe visionstory-backend \
  --region us-central1 \
  --format="value(spec.template.spec.serviceAccountName)"

# Cloud Tasks Enqueuer 역할 부여
gcloud projects add-iam-policy-binding your-project-id \
  --member=serviceAccount:YOUR-SERVICE-ACCOUNT@your-project-id.iam.gserviceaccount.com \
  --role=roles/cloudtasks.enqueuer
```

### 문제 3: "Worker not responding"

로그 확인:
```bash
gcloud run logs read visionstory-backend \
  --region us-central1 \
  --limit=50
```

### 문제 4: "Timeout after 60 minutes"

워커 엔드포인트가 60분 이상 걸리면 Cloud Run이 종료됩니다.

**해결책**: 폴링을 더 자주 하되 Firestore 업데이트만 하고 HTTP 응답은 빨리 반환:

```javascript
// 잘못된 방식
while (attempts < 360) {
  await sleep(10 * 60 * 1000);  // 10분 대기
  // ... 총 60시간 (Cloud Run 종료됨!)
}

// 올바른 방식
while (attempts < 6) {  // 최대 60분
  await sleep(10 * 60 * 1000);  // 10분 대기
  // ...
}
// 60분 후 아직 완료 안 됨
// → 새로운 Task 생성하여 계속 폴링
```

## 💰 비용 예상

### 시나리오: 하루 10개 작업, 각 3시간

```
월 작업: 300개
실행 시간: 300 × 3시간 = 900시간

Cloud Run 비용:
- vCPU: 900 × 60 × 60 = 3,240,000 vCPU-초
- 비용: 3,240,000 × $0.00002400 = $77.76

Cloud Tasks 비용:
- 작업 수: 300개
- 비용: 거의 무료 (월 100만 작업까지 무료)

총 비용: 약 $80/월
```

### 대규모 사용 (하루 100명 × 100개)

```
월 작업: 300,000개
실행 시간: 900,000시간

비용: 약 $77,760/월

최적화:
- Spot 인스턴스: 80% 할인 → $15,552/월
- 약정 할인 (1년): 37% 할인 → $49,000/월
```

## 📝 다음 단계

### 1. 슬라이드별 영상 생성으로 확장

현재: 1개 작업 → 1개 비디오
목표: 1개 프로젝트 → 100개 비디오 (병렬)

### 2. 푸시 알림 추가

완료 시 사용자에게 알림

### 3. 작업 목록 페이지

사용자가 자신의 모든 작업 확인

### 4. 재시도 로직 개선

실패 시 자동 재시도 정책

## ✅ 완료!

**Cloud Tasks 통합이 완료되었습니다!**

이제 수시간 걸리는 작업도 안정적으로 처리할 수 있습니다.

