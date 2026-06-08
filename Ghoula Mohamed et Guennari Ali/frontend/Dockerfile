# Étape 1 : Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build
WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .

ARG USE_MOCK=false
ARG API_BASE_URL=http://localhost:8090/api
RUN flutter build web --release --base-href / \
    --dart-define=USE_MOCK=$USE_MOCK \
    --dart-define=API_BASE_URL=$API_BASE_URL

# Étape 2 : Serveur Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
