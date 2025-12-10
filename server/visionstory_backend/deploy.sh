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
  echo "⚠️  .env 파일이 없습니다." 
  echo "   로컬 환경 변수가 설정되어 있지 않다면, Cloud Run의 기존 환경 변수가 유지됩니다."
fi

# 배포 인자 구성
DEPLOY_ARGS=(
  "$SERVICE_NAME"
  "--source" "."
  "--platform" "managed"
  "--region" "$REGION"
  "--allow-unauthenticated"
  "--timeout=3600s"
  "--memory=1Gi"
  "--cpu=1"
  "--min-instances=0"
  "--max-instances=10"
)

# 환경 변수 설정 (값이 있는 경우에만 --set-env-vars 추가)
ENV_VARS_TO_SET=""

if [ -n "$VISIONSTORY_API_KEY" ]; then
  ENV_VARS_TO_SET="${ENV_VARS_TO_SET}VISIONSTORY_API_KEY=$VISIONSTORY_API_KEY,"
fi

if [ -n "$VISIONSTORY_API_BASE" ]; then
  ENV_VARS_TO_SET="${ENV_VARS_TO_SET}VISIONSTORY_API_BASE=$VISIONSTORY_API_BASE,"
fi

if [ -n "$PROJECT_ID" ]; then
  ENV_VARS_TO_SET="${ENV_VARS_TO_SET}GOOGLE_CLOUD_PROJECT=$PROJECT_ID,"
fi

ENV_VARS_TO_SET="${ENV_VARS_TO_SET}CLOUD_TASKS_LOCATION=$REGION,"

if [ -n "$CLOUD_TASKS_QUEUE" ]; then
  ENV_VARS_TO_SET="${ENV_VARS_TO_SET}CLOUD_TASKS_QUEUE=$CLOUD_TASKS_QUEUE,"
else
  ENV_VARS_TO_SET="${ENV_VARS_TO_SET}CLOUD_TASKS_QUEUE=video-generation-queue,"
fi

# 마지막 콤마 제거 및 인자 추가
if [ -n "$ENV_VARS_TO_SET" ]; then
  DEPLOY_ARGS+=("--set-env-vars" "${ENV_VARS_TO_SET%,}")
fi


# Cloud Run 배포
echo ""
echo "🚢 Cloud Run 배포 중..."
gcloud run deploy "${DEPLOY_ARGS[@]}"

# 서비스 URL 가져오기
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
  --region $REGION \
  --format="value(status.url)")

echo ""
echo "✅ 배포 완료!"
echo "Service URL: $SERVICE_URL"

# WORKER_URL 업데이트 (자기 자신을 가리키도록)
echo ""
echo "🔄 WORKER_URL 업데이트 중..."
gcloud run services update $SERVICE_NAME \
  --region $REGION \
  --update-env-vars WORKER_URL=$SERVICE_URL

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
