#!/bin/bash

# Cloud Tasks 큐 생성 스크립트
# 사용법: ./setup-cloud-tasks.sh [PROJECT_ID] [LOCATION]

PROJECT_ID=${1:-"your-project-id"}
LOCATION=${2:-"asia-northeast3"}
QUEUE_NAME="video-generation-queue"

echo "🚀 Cloud Tasks 큐 생성 중..."
echo "프로젝트: $PROJECT_ID"
echo "리전: $LOCATION"
echo "큐 이름: $QUEUE_NAME"
echo ""

# Cloud Tasks API 활성화
echo "1️⃣ Cloud Tasks API 활성화..."
gcloud services enable cloudtasks.googleapis.com --project=$PROJECT_ID

# 큐 생성
echo "2️⃣ Cloud Tasks 큐 생성..."
gcloud tasks queues create $QUEUE_NAME \
  --project=$PROJECT_ID \
  --location=$LOCATION \
  --max-concurrent-dispatches=1000 \
  --max-dispatches-per-second=100 \
  --max-attempts=3 \
  --min-backoff=60s \
  --max-backoff=3600s

if [ $? -eq 0 ]; then
  echo "✅ Cloud Tasks 큐 생성 완료!"
  echo ""
  echo "큐 정보:"
  gcloud tasks queues describe $QUEUE_NAME \
    --project=$PROJECT_ID \
    --location=$LOCATION
else
  echo "❌ 큐 생성 실패. 이미 존재하는지 확인하세요."
  echo ""
  echo "기존 큐 확인:"
  gcloud tasks queues list \
    --project=$PROJECT_ID \
    --location=$LOCATION
fi

echo ""
echo "📝 환경 변수 설정:"
echo "export GOOGLE_CLOUD_PROJECT=$PROJECT_ID"
echo "export CLOUD_TASKS_LOCATION=$LOCATION"
echo "export CLOUD_TASKS_QUEUE=$QUEUE_NAME"

