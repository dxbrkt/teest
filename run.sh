#!/usr/bin/env bash
# run.sh — собирает C++ фронтенд (если нужно) и запускает TF2 Skin Generator
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
BUILD_DIR="$FRONTEND_DIR/build_run"
APP="$BUILD_DIR/Tf2SkinGeneratorUI.app"
EXE="$APP/Contents/MacOS/Tf2SkinGeneratorUI"

# ── Ищем Qt ───────────────────────────────────────────────────────────────── #
QT_DIR=""
for candidate in \
    "/opt/homebrew/Cellar/qt/6.11.1" \
    "/opt/homebrew/Cellar/qt/6.11.0" \
    "/opt/homebrew/Cellar/qt/6.10.0" \
    "/opt/homebrew/Cellar/qt/6.9.0" \
    "/opt/homebrew/Cellar/qt/6.8.0" \
    "/opt/homebrew/opt/qt" \
    "$HOME/Qt/6.7.0/macos" \
    "$HOME/Qt/6.6.0/macos"; do
    if [ -f "$candidate/bin/qmake" ]; then
        QT_DIR="$candidate"
        break
    fi
done

if [ -z "$QT_DIR" ]; then
    echo ""
    echo "[ERROR] Qt 6 не найден."
    echo "        Установи: brew install qt"
    echo ""
    exit 1
fi
echo "[OK] Qt: $QT_DIR"

# ── Проверяем cmake ───────────────────────────────────────────────────────── #
CMAKE="$(which cmake 2>/dev/null || find /opt/homebrew/Cellar/cmake -name cmake -type f 2>/dev/null | head -1)"
if [ -z "$CMAKE" ]; then
    echo ""
    echo "[ERROR] cmake не найден. Установи: brew install cmake"
    echo ""
    exit 1
fi
echo "[OK] CMake: $CMAKE"

# ── Проверяем Python ──────────────────────────────────────────────────────── #
PYTHON_CMD="$(which python3 2>/dev/null || which python 2>/dev/null)"
if [ -z "$PYTHON_CMD" ]; then
    echo ""
    echo "[ERROR] Python не найден. Установи: brew install python"
    echo ""
    exit 1
fi
echo "[OK] Python: $PYTHON_CMD"

# ── Устанавливаем Python-зависимости ─────────────────────────────────────── #
echo "[..] Проверяем Python-зависимости..."
"$PYTHON_CMD" -m pip install -r "$SCRIPT_DIR/requirements.txt" -q --disable-pip-version-check || true
echo "[OK] Python-зависимости установлены"

# ── Собираем C++ фронтенд (только если exe не существует) ────────────────── #
if [ -f "$EXE" ]; then
    echo "[OK] Фронтенд уже собран, пропускаем сборку"
else
    echo ""
    echo "[..] Сборка C++ фронтенда (первый запуск — займёт 1-3 минуты)..."
    echo ""

    mkdir -p "$BUILD_DIR"
    "$CMAKE" -S "$FRONTEND_DIR" \
             -B "$BUILD_DIR" \
             -DCMAKE_PREFIX_PATH="$QT_DIR" \
             -DCMAKE_BUILD_TYPE=Release \
             -Wno-dev

    "$CMAKE" --build "$BUILD_DIR" --parallel "$(sysctl -n hw.ncpu)"
    echo ""
    echo "[OK] Сборка завершена"
fi

# ── Запуск ───────────────────────────────────────────────────────────────── #
echo ""
echo "[..] Запуск TF2 Skin Generator..."
cd "$SCRIPT_DIR"
open "$APP"
