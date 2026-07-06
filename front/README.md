# Sharable Piggy Front

This is a Nuxt 3 static web frontend.

## Responsibilities

- Official homepage for `https://sharablepiggy.com/`
- Shared invite landing and app deep-link fallback for `https://sharablepiggy.com/topics/:token`
- Policy pages at `/privacy` and `/terms`
- App-link verification files at `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json`

## Development

```sh
cd front
npm install
npm run dev
```

## Static build

```sh
cd front
npm run generate
```

Deploy the generated `.output/public` directory to S3 via GitHub Actions (see `.github/workflows/deploy-front.yml`).

## AWS / CloudFront setup

### S3 캐시 전략

| 대상 | Cache-Control |
|---|---|
| `*.html` | `no-cache` |
| `.well-known/*` | `no-cache` |
| 그 외 (해시 포함 에셋) | `public, max-age=31536000, immutable` |

배포 시 `--delete` 플래그를 사용하지 않아 기존 에셋을 보존합니다.

### CloudFront URL 재작성

Nuxt generate는 `/privacy` → `privacy/index.html` 구조로 출력합니다.
CloudFront + S3(프라이빗 버킷) 조합에서는 `/privacy` 요청이 S3에서 404가 되어 홈으로 리다이렉트됩니다.

**CloudFront Function으로 해결:**

1. CloudFront 콘솔 → **Functions** → Create function
2. Runtime: `cloudfront-js-2.0`
3. 코드:

```js
function handler(event) {
  var request = event.request;
  var uri = request.uri;

  if (uri.endsWith('/') && uri !== '/') {
    request.uri = uri + 'index.html';
  } else if (!uri.includes('.')) {
    request.uri = uri + '/index.html';
  }

  return request;
}
```

4. Publish 후 → 배포 **Behaviors** → Default → Edit → **Function associations** → Viewer request에 연결

## Environment variables

- `NUXT_PUBLIC_SITE_URL` default: `https://sharablepiggy.com`
- `NUXT_PUBLIC_API_BASE_URL` default: `https://api.sharablepiggy.com`
- `NUXT_PUBLIC_IOS_STORE_URL`
- `NUXT_PUBLIC_ANDROID_STORE_URL`

trigger2