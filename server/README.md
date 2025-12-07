# Backend Services

백엔드 서비스들을 관리하는 디렉토리입니다.

## 📁 구조

```
server/
├── visionstory_backend/        # VisionStory AI 아바타 생성
│   ├── src/
│   │   └── index.js
│   ├── Dockerfile
│   └── package.json
│
├── slide_generator/            # 슬라이드 생성 서비스 (예정)
│   ├── src/
│   ├── Dockerfile
│   └── package.json
│
├── video_processor/            # 비디오 처리 서비스 (예정)
│   ├── src/
│   ├── Dockerfile
│   └── package.json
│
├── shared/                     # 공통 코드
│   ├── firebase-config.js
│   ├── cloud-tasks-config.js
│   └── utils.js
│
└── deploy-all.sh              # 전체 서비스 배포 스크립트
```

## 🚀 서비스 목록

### 1. VisionStory Backend (배포됨 ✅)
- **용도**: AI 아바타 영상 생성
- **엔드포인트**:
  - `POST /generate-with-tasks` - 비디오 생성 작업 생성
  - `POST /worker/process-avatar` - 워커 (Cloud Tasks)
  - `GET /jobs/:jobId` - 작업 상태 조회
  - `GET /health` - Health check
- **URL**: https://visionstory-backend-xxx-an.a.run.app
- **배포 리전**: asia-northeast3

### 2. Slide Generator (예정)
- **용도**: GPT/Gemini로 슬라이드 내용 생성
- **엔드포인트**:
  - `POST /generate-slides` - 슬라이드 생성
  - `POST /generate-script` - 대본 생성
- **예상 URL**: https://slide-generator-xxx-an.a.run.app

### 3. Video Processor (예정)
- **용도**: 비디오 편집, 합성, 변환
- **엔드포인트**:
  - `POST /merge-videos` - 여러 비디오 합치기
  - `POST /add-subtitles` - 자막 추가
  - `POST /add-background-music` - 배경 음악 추가
- **예상 URL**: https://video-processor-xxx-an.a.run.app

## 🛠️ 배포

### 개별 서비스 배포

```bash
# VisionStory Backend
cd visionstory_backend
./deploy.sh

# Slide Generator (예정)
cd slide_generator
./deploy.sh
```

### 전체 서비스 한 번에 배포

```bash
cd server
./deploy-all.sh
```

## 🔑 환경 변수 관리

각 서비스는 독립적인 `.env` 파일을 가집니다:

```bash
server/
├── visionstory_backend/.env
├── slide_generator/.env
└── video_processor/.env
```

공통 설정은 `server/config.env`에서 관리.

## 📊 모니터링

### Cloud Run 대시보드
```bash
open https://console.cloud.google.com/run?project=$PROJECT_ID
```

### 모든 서비스 상태 확인
```bash
./check-all-services.sh
```

## 💰 비용 관리

서비스별 비용 추적:
- VisionStory Backend: $80-800/월 (사용량에 따라)
- Slide Generator: $10-50/월
- Video Processor: $50-200/월

**총 예상 비용**: $140-1050/월

## 🔐 보안

- 각 서비스는 독립적인 서비스 계정 사용
- API 키는 Secret Manager로 관리 (권장)
- Firestore 보안 규칙 적용

