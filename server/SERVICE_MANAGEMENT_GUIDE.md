# 🏗️ 확장 가능한 백엔드 서비스 구조

## 📋 개요

프로젝트가 성장함에 따라 여러 백엔드 서비스를 쉽게 추가하고 관리할 수 있는 구조입니다.

---

## 🎯 현재 구조

```
project_eidos/
├── lib/
│   └── core/
│       └── constants/
│           └── backend_config.dart  ← 모든 백엔드 URL 관리
│
└── server/
    ├── README.md                    ← 서비스 문서
    ├── config.env.example           ← 환경 변수 템플릿
    ├── deploy-all.sh                ← 전체 배포
    ├── check-all-services.sh        ← 상태 확인
    ├── deployed-services.json       ← 배포 기록 (자동 생성)
    │
    ├── visionstory_backend/         ✅ 배포됨
    │   ├── src/index.js
    │   ├── deploy.sh
    │   ├── Dockerfile
    │   └── package.json
    │
    ├── slide_generator/             📝 예정
    │   └── (비어있음)
    │
    └── video_processor/             📝 예정
        └── (비어있음)
```

---

## 🚀 사용 방법

### 1. 개별 서비스 배포

```bash
# VisionStory Backend만 배포
cd server/visionstory_backend
./deploy.sh

# 또는 프로젝트와 리전 명시
./deploy.sh project-eidos-123456 asia-northeast3
```

### 2. 전체 서비스 한 번에 배포

```bash
cd server
./deploy-all.sh

# 자동으로:
# - 모든 서비스 빌드 및 배포
# - URL 수집
# - deployed-services.json 생성
# - Health check 실행
```

### 3. 서비스 상태 확인

```bash
cd server
./check-all-services.sh

# 출력 예시:
# ✅ visionstory-backend: OK
# ⚠️  slide-generator: Not deployed
# ⚠️  video-processor: Not deployed
```

---

## 📦 새 서비스 추가 방법

### Step 1: 서비스 디렉토리 생성

```bash
cd server
mkdir slide_generator
cd slide_generator
```

### Step 2: 기본 구조 생성

```bash
# package.json
npm init -y

# Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-slim
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
ENV PORT=8080
EXPOSE 8080
CMD ["node", "src/index.js"]
EOF

# src/index.js
mkdir src
cat > src/index.js << 'EOF'
import express from 'express';
const app = express();
const port = process.env.PORT || 5002;

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'Slide Generator' });
});

app.listen(port, () => {
  console.log(`Slide Generator listening on port ${port}`);
});
EOF
```

### Step 3: 배포 스크립트 생성

```bash
# deploy.sh 복사
cp ../visionstory_backend/deploy.sh ./
# 서비스 이름 수정
sed -i '' 's/visionstory-backend/slide-generator/g' deploy.sh
chmod +x deploy.sh
```

### Step 4: 배포

```bash
./deploy.sh
```

### Step 5: Flutter 앱에서 사용

```dart
// lib/core/constants/backend_config.dart 수정
static const String slideGeneratorUrl = String.fromEnvironment(
  'SLIDE_GENERATOR_URL',
  defaultValue: 'https://slide-generator-xxx-an.a.run.app',  // 배포된 URL
);
```

---

## 🔑 환경 변수 관리

### 로컬 개발

각 서비스의 `.env` 파일:

```bash
# server/visionstory_backend/.env
VISIONSTORY_API_KEY=sk-vs-xxx
GOOGLE_CLOUD_PROJECT=project-eidos-123456
CLOUD_TASKS_LOCATION=asia-northeast3
CLOUD_TASKS_QUEUE=video-generation-queue

# server/slide_generator/.env
GEMINI_API_KEY=xxx
OPENAI_API_KEY=xxx

# server/video_processor/.env
FFMPEG_PATH=/usr/bin/ffmpeg
```

### 프로덕션 (Cloud Run)

배포 시 자동으로 환경 변수 설정됨 (`deploy.sh` 참조)

---

## 📱 Flutter 앱 설정

### 개발 환경 (로컬 백엔드)

```bash
# 로컬 백엔드 사용
flutter run -d chrome \
  --dart-define=VISIONSTORY_BACKEND_URL=http://localhost:5001 \
  --dart-define=SLIDE_GENERATOR_URL=http://localhost:5002
```

### 프로덕션 환경

```dart
// lib/core/constants/backend_config.dart
// defaultValue를 배포된 URL로 설정
static const String visionStoryUrl = String.fromEnvironment(
  'VISIONSTORY_BACKEND_URL',
  defaultValue: 'https://visionstory-backend-xxx-an.a.run.app',
);
```

그냥 실행:
```bash
flutter run -d chrome  # defaultValue 사용
```

---

## 🎯 서비스별 책임

### VisionStory Backend (현재)
- AI 아바타 영상 생성
- Cloud Tasks 워커
- 수시간 소요 작업 처리

### Slide Generator (예정)
- GPT/Gemini로 슬라이드 내용 생성
- 대본 생성
- 이미지 생성 (DALL-E, Midjourney 등)

### Video Processor (예정)
- 여러 비디오 합치기
- 자막 추가
- 배경 음악 추가
- 비디오 편집

### 추가 가능한 서비스
- **Auth Service**: 인증/인가
- **Storage Service**: 파일 업로드/다운로드
- **Analytics Service**: 사용자 분석
- **Notification Service**: 푸시 알림

---

## 💰 비용 최적화

### 서비스별 리소스 설정

```bash
# 가벼운 서비스 (Slide Generator)
--memory=512Mi --cpu=1

# 중간 서비스 (VisionStory Backend)
--memory=1Gi --cpu=1

# 무거운 서비스 (Video Processor)
--memory=2Gi --cpu=2
```

### 자동 스케일링 설정

```bash
# 사용량이 적은 서비스
--min-instances=0 --max-instances=5

# 사용량이 많은 서비스
--min-instances=1 --max-instances=100
```

---

## 🔐 보안 모범 사례

### 1. Secret Manager 사용 (권장)

```bash
# Secret 생성
echo -n "sk-vs-xxx" | gcloud secrets create visionstory-api-key --data-file=-

# Cloud Run에서 사용
gcloud run services update visionstory-backend \
  --set-secrets VISIONSTORY_API_KEY=visionstory-api-key:latest
```

### 2. 서비스 계정 분리

각 서비스마다 독립적인 서비스 계정 사용:

```bash
# VisionStory 전용 서비스 계정
gcloud iam service-accounts create visionstory-backend-sa

# 최소 권한 부여
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member=serviceAccount:visionstory-backend-sa@$PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/cloudtasks.enqueuer
```

### 3. 인증 추가 (예정)

```bash
# 인증 필요한 서비스
gcloud run services update slide-generator \
  --no-allow-unauthenticated
```

---

## 📊 모니터링

### Cloud Run 대시보드

```bash
open https://console.cloud.google.com/run?project=$PROJECT_ID
```

### 로그 확인

```bash
# 특정 서비스
gcloud run services logs read visionstory-backend \
  --region asia-northeast3 \
  --limit=100

# 모든 서비스
./check-all-services.sh
```

### 알림 설정

Cloud Monitoring에서 알림 설정:
- CPU > 80%
- 메모리 > 90%
- 오류율 > 5%
- 응답 시간 > 5초

---

## 🔄 CI/CD (GitHub Actions)

```yaml
# .github/workflows/deploy-backend.yml
name: Deploy Backend Services

on:
  push:
    branches: [main]
    paths: ['server/**']

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - uses: google-github-actions/setup-gcloud@v0
        with:
          service_account_key: ${{ secrets.GCP_SA_KEY }}
          project_id: ${{ secrets.GCP_PROJECT_ID }}
      
      - name: Deploy All Services
        run: |
          cd server
          ./deploy-all.sh
```

---

## ✅ 체크리스트

### 새 서비스 추가 시

- [ ] 서비스 디렉토리 생성
- [ ] Dockerfile 작성
- [ ] deploy.sh 생성
- [ ] 로컬 테스트 (localhost:500X)
- [ ] Cloud Run 배포
- [ ] Health check 확인
- [ ] Flutter BackendConfig 업데이트
- [ ] server/README.md 업데이트
- [ ] deploy-all.sh에 추가

---

## 🎊 완료!

**이제 서비스를 체계적으로 관리할 수 있습니다!**

새 서비스 추가가 필요하면 위의 가이드를 따라하세요.

