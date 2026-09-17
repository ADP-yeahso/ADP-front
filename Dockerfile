# Flutter 웹 앱은 API 주소를 런타임이 아닌 빌드 시점에 포함합니다.
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

ARG API_BASE_URL=https://adp-back-production.up.railway.app/api/v1

COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . ./
RUN flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL

FROM nginx:1.27-alpine

COPY deploy/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
