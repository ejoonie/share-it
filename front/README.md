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

Deploy the generated `.output/public` directory as the nginx static root.

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

## Environment variables

- `NUXT_PUBLIC_SITE_URL` default: `https://sharablepiggy.com`
- `NUXT_PUBLIC_API_BASE_URL` default: `https://api.sharablepiggy.com`
- `NUXT_PUBLIC_IOS_STORE_URL`
- `NUXT_PUBLIC_ANDROID_STORE_URL`

trigger2