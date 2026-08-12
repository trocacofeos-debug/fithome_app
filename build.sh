#!/bin/bash
set -e

echo "==> Instalando Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

flutter config --enable-web

echo "==> Recriando .env a partir das Environment Variables da Vercel..."
{
  echo "R2_ENDPOINT=$R2_ENDPOINT"
  echo "R2_ACCESS_KEY_ID=$R2_ACCESS_KEY_ID"
  echo "R2_SECRET_ACCESS_KEY=$R2_SECRET_ACCESS_KEY"
  echo "R2_BUCKET=$R2_BUCKET"
  echo "R2_PUBLIC_URL=$R2_PUBLIC_URL"
} > .env

echo "==> Instalando dependências..."
flutter pub get

echo "==> Compilando para Web (release)..."
flutter build web --release

echo "==> Build concluído em build/web"