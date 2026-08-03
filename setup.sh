#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-}"
if [ -z "$FLUTTER_BIN" ]; then
  if [ -x /home/axel/flutter-sdk/bin/flutter ]; then
    FLUTTER_BIN=/home/axel/flutter-sdk/bin/flutter
  elif [ -x /home/axel/flutter/bin/flutter ]; then
    FLUTTER_BIN=/home/axel/flutter/bin/flutter
  else
    FLUTTER_BIN=flutter
  fi
fi

cd "$PROJECT_DIR"
"$FLUTTER_BIN" pub get
"$FLUTTER_BIN" create --org com.webpack123 --project-name limpio_dart .
"$FLUTTER_BIN" analyze
"$FLUTTER_BIN" test
echo "Listo. Ejecuta: $FLUTTER_BIN run"
