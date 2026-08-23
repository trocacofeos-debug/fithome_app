#!/bin/bash
set -e

echo "==> Instalando Flutter SDK..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

flutter config --enable-web

echo "==> Recriando .env a partir das Environment Variables da Vercel..."
# O .env é ignorado pelo Git de propósito (não deve ir pro GitHub), então
# esse arquivo simplesmente não existe quando a Vercel clona o repositório.
# Por isso recriamos ele aqui, na hora do build, usando as Environment
# Variables configuradas no painel da Vercel (Settings → Environment
# Variables).
{
  echo "UPLOAD_API_URL=$UPLOAD_API_URL"
  echo "API_BASE_URL=$API_BASE_URL"
} > .env

echo "==> Instalando dependências Flutter..."
flutter pub get

echo "==> Compilando para Web (release)..."
flutter build web --release

echo "==> Build concluído em build/web"