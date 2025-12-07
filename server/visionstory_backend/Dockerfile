# Node.js 20 기반 이미지
FROM node:20-slim

# 작업 디렉토리 설정
WORKDIR /app

# package.json과 package-lock.json 복사
COPY package*.json ./

# 의존성 설치
RUN npm ci --only=production

# 애플리케이션 소스 복사
COPY . .

# 업로드 디렉토리 생성
RUN mkdir -p public/uploads public/results

# 포트 설정
ENV PORT=8080
EXPOSE 8080

# 애플리케이션 시작
CMD ["node", "src/index.js"]

