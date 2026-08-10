#!/usr/bin/env bash
# Installs Flutter on the Vercel build machine, then builds the web app.
set -euo pipefail

FLUTTER_DIR="${HOME}/flutter"

if [ ! -x "${FLUTTER_DIR}/bin/flutter" ]; then
  echo "Cloning Flutter SDK (stable)..."
  rm -rf "${FLUTTER_DIR}"
  git clone https://github.com/flutter/flutter.git \
    --branch stable \
    --depth 1 \
    "${FLUTTER_DIR}"
fi

export PATH="${FLUTTER_DIR}/bin:${PATH}"

echo "Flutter version:"
flutter --version

flutter config --no-analytics
flutter config --enable-web
flutter pub get
flutter build web --release

echo "Web build complete → build/web"
