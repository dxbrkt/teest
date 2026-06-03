#!/usr/bin/env bash
# Build the C++ Qt frontend (macOS)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/build"

# Locate cmake (Homebrew installs to Cellar)
CMAKE="$(find /opt/homebrew/Cellar/cmake -name cmake -type f 2>/dev/null | head -1)"
if [ -z "$CMAKE" ]; then CMAKE="cmake"; fi
command -v "$CMAKE" &>/dev/null || { echo "❌  cmake not found. Run: brew install cmake qt"; exit 1; }

# Locate Qt6 (Homebrew Cellar)
QT_PREFIX="$(ls -d /opt/homebrew/Cellar/qt/*/ 2>/dev/null | tail -1)"
if [ -z "$QT_PREFIX" ]; then
    QT_PREFIX="$(brew --prefix qt 2>/dev/null || echo '')"
fi

echo "🔨  CMake: $CMAKE"
echo "🔨  Qt:    $QT_PREFIX"
echo "🔨  Configuring…"

"$CMAKE" -S "$SCRIPT_DIR" -B "$BUILD_DIR" \
         -DCMAKE_BUILD_TYPE=Release \
         ${QT_PREFIX:+-DCMAKE_PREFIX_PATH="$QT_PREFIX"}

echo "🔨  Building…"
"$CMAKE" --build "$BUILD_DIR" --config Release --parallel "$(sysctl -n hw.ncpu)"

APP="$BUILD_DIR/Tf2SkinGeneratorUI.app"
echo ""
echo "✅  Build complete!"
echo "    App bundle: $APP"
echo ""
echo "Launch from project root:"
echo "    cd $ROOT_DIR && $APP/Contents/MacOS/Tf2SkinGeneratorUI"
