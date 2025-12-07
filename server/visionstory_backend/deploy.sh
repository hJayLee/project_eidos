#!/bin/bash

# VisionStory Backend 개별 배포 스크립트
# 사용법: ./deploy.sh [project-id] [region]

set -e

PROJECT_ID=${1:-$(gcloud config get-value project)}
REGION=${2:-"asia-northeast3"}
SERVICE_NAME="visionstory-backend"

echo "🚀 VisionStory Backend 배포"
echo "프로젝트: $PROJECT_ID"
echo "리전: $REGION"
echo ""

# 환경 변수 로드
if [ -f ".env" ]; then
  export $(cat .env | grep -v '^#' | xargs)
  echo "✅ .env 파일 로드됨"
else
  echo "⚠️  .env 파일이 없습니다. 환경 변수를 수동으로 설정해야 합니다."
fi

# 컨테이너 빌드
echo ""
echo "📦 컨테이너 빌드 중..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# Cloud Run 배포
echo ""
echo "🚢 Cloud Run 배포 중..."
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --timeout=3600s \
  --memory=1Gi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=10 \
  --set-env-vars VISIONSTORY_API_KEY=${VISIONSTORY_API_KEY} \
  --set-env-vars VISIONSTORY_API_BASE=${VISIONSTORY_API_BASE:-https://openapi.visionstory.ai} \
  --set-env-vars GOOGLE_CLOUD_PROJECT=${PROJECT_ID} \
  --set-env-vars CLOUD_TASKS_LOCATION=${REGION} \
  --set-env-vars CLOUD_TASKS_QUEUE=${CLOUD_TASKS_QUEUE:-video-generation-queue}

# 서비스 URL 가져오기
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format="value(status.url)")

echo ""
echo "✅ 배포 완료!"
echo "Service URL: $SERVICE_URL"

# WORKER_URL 업데이트
echo ""
echo "🔄 WORKER_URL 업데이트 중..."
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --set-env-vars WORKER_URL=$SERVICE_URL

echo ""
echo "🏥 Health Check..."
HEALTH_STATUS=$(curl -s "$SERVICE_URL/health" | jq -r '.ok')

if [ "$HEALTH_STATUS" = "true" ]; then
  echo "✅ 서비스 정상 작동 중"
else
  echo "⚠️  서비스 상태 확인 필요"
  echo "로그 확인: gcloud run services logs read $SERVICE_NAME --region $REGION --limit=50"
fi

echo ""
echo "📋 배포 정보:"
echo "  - Service Name: $SERVICE_NAME"
echo "  - URL: $SERVICE_URL"
echo "  - Region: $REGION"
echo "  - Project: $PROJECT_ID"

