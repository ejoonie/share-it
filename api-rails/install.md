# api-rails 초기 MVP 설치 가이드

아래 순서대로 진행하면 `sp-api` 경로에 **Rails API-only + Grape + PostgreSQL + Puma + Nginx(HTTPS 준비)** 구조를 만들 수 있습니다.  
현재 `api` 디렉터리의 Topics API를 기준으로, MVP는 **토픽 생성 / 내 토픽 목록 조회**만 우선 구현합니다.

---

## 1) 사전 설치

- Docker / Docker Compose
- (로컬 개발용) Ruby 3.3+, Bundler, PostgreSQL 클라이언트

---

## 2) Rails API 프로젝트 생성

```bash
cd /home/runner/work/share-it/share-it

# rails가 없다면
# gem install rails -v 7.1.5

rails new sp-api --api -d postgresql
cd sp-api
```

---

## 3) Gem 추가

`/home/runner/work/share-it/share-it/sp-api/Gemfile`에 아래 gem을 추가:

```ruby
gem "grape"
gem "grape-entity"
gem "rack-cors"
gem "jwt"
```

설치:

```bash
bundle install
```

---

## 4) Topics MVP 모델/마이그레이션 (Rails convention)

```bash
bin/rails g model Topic owner_id:string title:string is_default:boolean
```

생성된 migration 수정 포인트:

- `owner_id`, `title`는 `null: false`
- `is_default` 기본값 `false`
- `owner_id, created_at` 복합 index (`내 토픽 목록` 조회용)

예시:

```ruby
add_index :topics, [:owner_id, :created_at]
```

---

## 5) CORS 설정

`/home/runner/work/share-it/share-it/sp-api/config/initializers/cors.rb`

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*"
    resource "*", headers: :any, methods: %i[get post patch put delete options head]
  end
end
```

---

## 6) Grape API 추가 (Topics: 생성/목록)

`/home/runner/work/share-it/share-it/sp-api/app/api/entities/topic_entity.rb`

```ruby
module Entities
  class TopicEntity < Grape::Entity
    expose :id
    expose :owner_id
    expose :title
    expose :is_default
    expose :created_at
    expose :updated_at
  end
end
```

`/home/runner/work/share-it/share-it/sp-api/app/api/v1/topics_api.rb`

```ruby
module V1
  class TopicsAPI < Grape::API
    format :json

    helpers do
      def user_id
        headers["x-user-id"] || headers["X-User-Id"] || error!({ message: "x-user-id header is required" }, 401)
      end
    end

    resource :topics do
      desc "토픽 생성"
      params do
        requires :title, type: String, regexp: /\S/
      end
      post do
        title = params[:title].strip

        topic = Topic.create!(
          owner_id: user_id,
          title: title,
          is_default: false
        )
        status 201
        present topic, with: Entities::TopicEntity
      end

      desc "내 토픽 목록"
      get :owned do
        topics = Topic.where(owner_id: user_id).order(created_at: :desc)
        { topics: Entities::TopicEntity.represent(topics) }
      end
    end
  end
end
```

`/home/runner/work/share-it/share-it/sp-api/app/api/base_api.rb`

```ruby
class BaseAPI < Grape::API
  prefix :api
  version :v1, using: :path

  mount V1::TopicsAPI
end
```

`/home/runner/work/share-it/share-it/sp-api/config/routes.rb`

```ruby
Rails.application.routes.draw do
  mount BaseAPI => "/"
end
```

---

## 7) Docker 구성 (dev/prod 분리)

`/home/runner/work/share-it/share-it/api-rails/docker-compose.dev.yml`  
(`dev`: DB는 호스트의 localhost PostgreSQL 사용)

```yaml
services:
  app:
    image: ruby:3.3
    working_dir: /app
    volumes:
      - ../sp-api:/app
    environment:
      RAILS_ENV: development
      DATABASE_URL: postgres://postgres:postgres@host.docker.internal:5432/sp_api_development
    extra_hosts:
      - "host.docker.internal:host-gateway"
    command: bash -lc "bundle check || bundle install && bin/rails db:prepare && bundle exec puma -C config/puma.rb"

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - app
```

`/home/runner/work/share-it/share-it/api-rails/docker-compose.prod.yml`  
(`prod`: DB 포함)

```yaml
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD}
      POSTGRES_DB: sp_api_production
    volumes:
      - pgdata:/var/lib/postgresql/data

  app:
    image: ruby:3.3
    working_dir: /app
    volumes:
      - ../sp-api:/app
    environment:
      RAILS_ENV: production
      DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD:?set POSTGRES_PASSWORD}@db:5432/sp_api_production
    command: bash -lc "bundle check || bundle install && bin/rails db:prepare && bundle exec puma -C config/puma.rb"
    depends_on:
      - db

  nginx:
    image: nginx:1.27-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - app

volumes:
  pgdata:
```

`/home/runner/work/share-it/share-it/api-rails/nginx/default.conf`

```nginx
server {
  listen 80;
  server_name _;

  location /.well-known/acme-challenge/ {
    root /var/www/certbot;
  }

  location / {
    proxy_pass http://app:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
```

---

## 8) 실행

```bash
cd /home/runner/work/share-it/share-it/api-rails

# dev (호스트 localhost PostgreSQL 사용)
docker compose -f docker-compose.dev.yml up -d

# prod (db 포함)
export POSTGRES_PASSWORD='change-this'
docker compose -f docker-compose.prod.yml up -d
```

테스트 요청:

```bash
curl -X POST http://localhost/api/v1/topics \
  -H "x-user-id: u_1" \
  -H "content-type: application/json" \
  -d '{"title":"My Expenses"}'

curl -X GET http://localhost/api/v1/topics/owned \
  -H "x-user-id: u_1"
```

---

## 9) Let's Encrypt 적용(EC2 배포 시)

도메인 연결 후 certbot 1회 발급:

```bash
docker run --rm -it \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot -w /var/www/certbot \
  -d your-domain.com -d www.your-domain.com
```

이후 nginx 443 서버 블록에 인증서 경로를 연결해 HTTPS를 활성화합니다.

---

## MVP 범위 요약

- 포함: Topics 생성, 내 Topics 조회
- 제외(차후): 제목 수정, 삭제, 기본 토픽 지정, 구독, 이벤트 API

---

## 10) 바로 복붙해서 쓸 수 있는 샘플 코드 포함

이 저장소에 아래 샘플 파일을 함께 추가해두었습니다.

- `sp-api-template/app/models/topic.rb`
- `sp-api-template/app/api/entities/topic_entity.rb`
- `sp-api-template/app/api/v1/topics_api.rb`
- `sp-api-template/app/api/base_api.rb`
- `sp-api-template/config/routes.rb`
- `sp-api-template/db/migrate/20260508150000_create_topics.rb`
