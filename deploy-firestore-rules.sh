#!/bin/bash

# Firestore 보안 규칙 배포
# 사용법: ./deploy-firestore-rules.sh [project-id]

PROJECT_ID=${1:-$(gcloud config get-value project)}

echo "🔐 Firestore 보안 규칙 배포"
echo "프로젝트: $PROJECT_ID"
echo ""

# Firebase CLI 설치 확인
if ! command -v firebase &> /dev/null; then
  echo "❌ Firebase CLI가 설치되어 있지 않습니다."
  echo ""
  echo "설치 방법:"
  echo "  npm install -g firebase-tools"
  echo ""
  exit 1
fi

# Firebase 로그인 확인
if ! firebase projects:list &> /dev/null; then
  echo "🔑 Firebase 로그인 필요"
  firebase login
fi

# 규칙 배포
echo "📤 Firestore 규칙 배포 중..."
firebase deploy --only firestore:rules --project $PROJECT_ID

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Firestore 규칙 배포 완료!"
  echo ""
  echo "Firebase Console에서 확인:"
  echo "  https://console.firebase.google.com/project/$PROJECT_ID/firestore/rules"
else
  echo ""
  echo "❌ 배포 실패"
  echo ""
  echo "수동 배포:"
  echo "  1. https://console.firebase.google.com/project/$PROJECT_ID/firestore/rules"
  echo "  2. firestore.rules 파일 내용 복사"
  echo "  3. 규칙 편집기에 붙여넣기"
  echo "  4. '게시' 클릭"
fi

