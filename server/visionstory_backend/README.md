# VisionStory Backend

Node.js Express 백엔드 서버로 VisionStory AI Talking Head API를 프록시합니다.

## 설치

```bash
cd server/visionstory_backend
npm install
```

## 환경 변수 설정

`.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
VISIONSTORY_API_KEY=your_visionstory_api_key
VISIONSTORY_API_BASE=https://openapi.visionstory.ai
PORT=5001
```

## 실행

```bash
npm start
```

개발 모드 (자동 재시작):

```bash
npm run dev
```

## API 엔드포인트

- `GET /health` - 서버 상태 확인
- `POST /generate` - 아바타 비디오 생성 (이미지 + 오디오)
- `GET /status/:videoId` - 비디오 생성 상태 확인

## 사용 예시

```bash
curl -X POST http://localhost:5001/generate \
  -F "image=@/path/to/image.jpg" \
  -F "audio=@/path/to/audio.wav"
```

