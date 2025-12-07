#!/bin/bash

# 모든 배포된 서비스의 상태를 확인하는 스크립트
# 사용법: ./check-all-services.sh

set -e

PROJECT_ID=$(gcloud config get-value project)
REGION=${1:-"asia-northeast3"}

echo "🔍 서비스 상태 확인"
echo "프로젝트: $PROJECT_ID"
echo "리전: $REGION"
echo ""

# 배포된 서비스 목록 가져오기
SERVICES=$(gcloud run services list --region=$REGION --format="value(metadata.name)")

if [ -z "$SERVICES" ]; then
  echo "❌ 배포된 서비스가 없습니다."
  exit 0
fi

echo "📋 서비스 목록:"
echo "$SERVICES" | while read SERVICE; do
  echo "  - $SERVICE"
done
echo ""

# 각 서비스 상태 확인
echo "================================"
echo "🏥 Health Check"
echo "================================"
echo ""

echo "$SERVICES" | while read SERVICE; do
  # 서비스 URL 가져오기
  SERVICE_URL=$(gcloud run services describe $SERVICE \
    --region $REGION \
    --format="value(status.url)")
  
  echo "[$SERVICE]"
  echo "  URL: $SERVICE_URL"
  
  # Health check
  echo -n "  Status: "
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$SERVICE_URL/health" 2>/dev/null || echo "000")
  
  if [ "$RESPONSE" = "200" ]; then
    echo "✅ OK (HTTP $RESPONSE)"
    
    # API 설정 확인
    API_CONFIG=$(curl -s "$SERVICE_URL/health" 2>/dev/null | jq -r '.apiConfigured' 2>/dev/null || echo "unknown")
    echo "  API Configured: $API_CONFIG"
  elif [ "$RESPONSE" = "000" ]; then
    echo "❌ 연결 실패"
  else
    echo "⚠️  HTTP $RESPONSE"
  fi
  
  # 최근 배포 시간
  LAST_UPDATED=$(gcloud run services describe $SERVICE \
    --region $REGION \
    --format="value(metadata.creationTimestamp)")
  echo "  Last Updated: $LAST_UPDATED"
  
  # 리소스 사용량
  MEMORY=$(gcloud run services describe $SERVICE \
    --region $REGION \
    --format="value(spec.template.spec.containers[0].resources.limits.memory)")
  CPU=$(gcloud run services describe $SERVICE \
    --region $REGION \
    --format="value(spec.template.spec.containers[0].resources.limits.cpu)")
  echo "  Resources: CPU=$CPU, Memory=$MEMORY"
  
  echo ""
done

echo "================================"
echo "📊 Cloud Tasks 큐 상태"
echo "================================"
echo ""

# Cloud Tasks 큐 확인
QUEUES=$(gcloud tasks queues list --location=$REGION --format="value(name)" 2>/dev/null || echo "")

if [ -z "$QUEUES" ]; then
  echo "⚠️  Cloud Tasks 큐가 없습니다."
else
  echo "$QUEUES" | while read QUEUE_PATH; do
    QUEUE_NAME=$(basename $QUEUE_PATH)
    echo "[$QUEUE_NAME]"
    
    # 큐 상태
    TASK_COUNT=$(gcloud tasks list --queue=$QUEUE_NAME --location=$REGION --format="value(name)" 2>/dev/null | wc -l || echo "0")
    echo "  대기 중인 작업: $TASK_COUNT"
    
    # 큐 설정
    MAX_CONCURRENT=$(gcloud tasks queues describe $QUEUE_NAME --location=$REGION --format="value(rateLimits.maxConcurrentDispatches)" 2>/dev/null || echo "unknown")
    echo "  최대 동시 실행: $MAX_CONCURRENT"
    
    echo ""
  done
fi

echo "================================"
echo "💰 비용 확인"
echo "================================"
echo ""
echo "Cloud Run 대시보드에서 확인하세요:"
echo "  https://console.cloud.google.com/run?project=$PROJECT_ID"
echo ""
echo "청구 대시보드:"
echo "  https://console.cloud.google.com/billing"
echo ""

