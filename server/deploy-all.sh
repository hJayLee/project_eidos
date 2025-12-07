#!/bin/bash

# 전체 백엔드 서비스 배포 스크립트
# 사용법: ./deploy-all.sh [project-id] [region]

set -e  # 에러 발생 시 중단

PROJECT_ID=${1:-$(gcloud config get-value project)}
REGION=${2:-"asia-northeast3"}

echo "🚀 백엔드 서비스 배포 시작"
echo "프로젝트: $PROJECT_ID"
echo "리전: $REGION"
echo ""

# 서비스 목록
SERVICES=(
  "visionstory_backend"
  # "slide_generator"  # 주석 해제하여 활성화
  # "video_processor"  # 주석 해제하여 활성화
)

# 배포된 서비스 URL 저장
declare -A SERVICE_URLS

# 각 서비스 배포
for SERVICE in "${SERVICES[@]}"; do
  echo "================================"
  echo "📦 $SERVICE 배포 중..."
  echo "================================"
  
  if [ -d "$SERVICE" ]; then
    cd "$SERVICE"
    
    # deploy.sh가 있으면 실행, 없으면 기본 배포
    if [ -f "deploy.sh" ]; then
      ./deploy.sh "$PROJECT_ID" "$REGION"
    else
      # 기본 배포
      SERVICE_NAME=$(echo "$SERVICE" | tr '_' '-')
      
      echo "컨테이너 빌드 중..."
      gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME
      
      echo "Cloud Run 배포 중..."
      gcloud run deploy $SERVICE_NAME \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --timeout=3600s \
        --memory=1Gi
    fi
    
    # 배포된 URL 가져오기
    SERVICE_NAME=$(echo "$SERVICE" | tr '_' '-')
    SERVICE_URL=$(gcloud run services describe $SERVICE_NAME \
      --region $REGION \
      --format="value(status.url)")
    SERVICE_URLS[$SERVICE]=$SERVICE_URL
    
    echo "✅ $SERVICE 배포 완료: $SERVICE_URL"
    echo ""
    
    cd ..
  else
    echo "⚠️  $SERVICE 디렉토리가 없습니다. 건너뜁니다."
    echo ""
  fi
done

echo "================================"
echo "🎉 모든 서비스 배포 완료!"
echo "================================"
echo ""
echo "📋 배포된 서비스 목록:"
for SERVICE in "${!SERVICE_URLS[@]}"; do
  echo "  - $SERVICE: ${SERVICE_URLS[$SERVICE]}"
done
echo ""

# config 파일 생성
echo "📝 서비스 URL 저장 중..."
cat > deployed-services.json << EOF
{
  "project": "$PROJECT_ID",
  "region": "$REGION",
  "deployed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "services": {
EOF

FIRST=true
for SERVICE in "${!SERVICE_URLS[@]}"; do
  if [ "$FIRST" = true ]; then
    FIRST=false
  else
    echo "," >> deployed-services.json
  fi
  echo "    \"$SERVICE\": \"${SERVICE_URLS[$SERVICE]}\"" >> deployed-services.json
done

cat >> deployed-services.json << EOF

  }
}
EOF

echo "✅ 서비스 URL이 deployed-services.json에 저장되었습니다"
echo ""

# Health check
echo "🏥 Health Check 실행 중..."
for SERVICE in "${!SERVICE_URLS[@]}"; do
  URL="${SERVICE_URLS[$SERVICE]}"
  echo -n "  $SERVICE: "
  
  RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$URL/health" 2>/dev/null || echo "000")
  
  if [ "$RESPONSE" = "200" ]; then
    echo "✅ OK"
  else
    echo "⚠️  HTTP $RESPONSE"
  fi
done
echo ""

echo "🎊 배포 완료!"
echo ""
echo "다음 명령어로 로그를 확인할 수 있습니다:"
for SERVICE in "${!SERVICE_URLS[@]}"; do
  SERVICE_NAME=$(echo "$SERVICE" | tr '_' '-')
  echo "  gcloud run services logs read $SERVICE_NAME --region $REGION --limit=50"
done

