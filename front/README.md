# Sharable Piggy Front

Nuxt 3 기반의 정적 웹 프런트입니다.

## 역할

- `https://sharablepiggy.com/` 공식 홈페이지
- `https://sharablepiggy.com/topics/:token` 공유 초대 랜딩 및 앱 딥링크 폴백
- `/privacy`, `/terms` 정책 페이지
- `/.well-known/apple-app-site-association`, `/.well-known/assetlinks.json` 앱 링크 검증 파일 제공

## 개발

```sh
cd front
npm install
npm run dev
```

## 정적 빌드

```sh
cd front
npm run generate
```

생성된 `.output/public` 디렉터리를 nginx 정적 루트로 배포합니다.

```nginx
server {
  server_name sharablepiggy.com;
  root /var/www/sharable-piggy/.output/public;

  location / {
    try_files $uri $uri/ /index.html;
  }

  location /.well-known/ {
    default_type application/json;
    try_files $uri =404;
  }
}
```

## 환경 변수

- `NUXT_PUBLIC_SITE_URL` 기본값: `https://sharablepiggy.com`
- `NUXT_PUBLIC_API_BASE_URL` 기본값: `https://api.sharablepiggy.com`
- `NUXT_PUBLIC_IOS_STORE_URL`
- `NUXT_PUBLIC_ANDROID_STORE_URL`
