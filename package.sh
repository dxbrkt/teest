#!/bin/bash
# package.sh — собирает TF2 Skin Generator в один .app бандл (macOS)
# Результат: dist/TF2SkinGenerator.app
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

DIST_DIR="$SCRIPT_DIR/dist"
APP_NAME="TF2SkinGenerator"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

# ── ищем Qt ──────────────────────────────────────────────────────────────── #
QT_DIR=""
for candidate in \
    "/opt/homebrew/Cellar/qt/6.11.1" \
    "/opt/homebrew/Cellar/qt/6.10.0" \
    "/opt/homebrew/Cellar/qt/6.9.0" \
    "/opt/homebrew/Cellar/qt/6.8.0" \
    "/opt/homebrew/opt/qt" \
    "$HOME/Qt/6.7.0/macos" \
    "$HOME/Qt/6.6.0/macos"; do
    if [ -f "$candidate/bin/macdeployqt" ]; then
        QT_DIR="$candidate"
        break
    fi
done

if [ -z "$QT_DIR" ]; then
    echo "[ERROR] Qt не найден. Установи: brew install qt"
    exit 1
fi
echo "[OK] Qt: $QT_DIR"

CMAKE_BIN=$(which cmake || echo "/opt/homebrew/Cellar/cmake/4.3.3/bin/cmake")

# ── 1. Собираем C++ фронтенд ─────────────────────────────────────────────── #
echo ""
echo "=== Шаг 1: сборка C++ фронтенда ==="
mkdir -p "$SCRIPT_DIR/frontend/build_release"
$CMAKE_BIN -S "$SCRIPT_DIR/frontend" \
    -B "$SCRIPT_DIR/frontend/build_release" \
    -DCMAKE_PREFIX_PATH="$QT_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -Wno-dev
$CMAKE_BIN --build "$SCRIPT_DIR/frontend/build_release" --parallel "$(sysctl -n hw.ncpu)"
echo "[OK] C++ фронтенд собран"

# ── 2. Собираем Python бэкенд через PyInstaller ───────────────────────────── #
echo ""
echo "=== Шаг 2: сборка Python бэкенда (PyInstaller) ==="
pyinstaller --noconfirm "$SCRIPT_DIR/backend.spec" \
    --distpath "$SCRIPT_DIR/dist_pyinstaller" \
    --workpath "$SCRIPT_DIR/build_pyinstaller"
echo "[OK] Python бэкенд собран"

BACKEND_DIR="$SCRIPT_DIR/dist_pyinstaller/backend_server"

# ── 3. Копируем .app и добавляем бэкенд внутрь ────────────────────────────── #
echo ""
echo "=== Шаг 3: сборка финального .app ==="
mkdir -p "$DIST_DIR"
rm -rf "$APP_BUNDLE"
cp -R "$SCRIPT_DIR/frontend/build_release/Tf2SkinGeneratorUI.app" "$APP_BUNDLE"

MACOS_DIR="$APP_BUNDLE/Contents/MacOS"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

# копируем весь PyInstaller-бандл бэкенда внутрь .app
echo "  → Копируем Python backend в .app..."
cp -R "$BACKEND_DIR/"* "$MACOS_DIR/"

# копируем tools (crowbar, vpk, vtf нужны для сборки)
if [ -d "$SCRIPT_DIR/tools" ]; then
    echo "  → Копируем tools/..."
    cp -R "$SCRIPT_DIR/tools" "$MACOS_DIR/tools"
fi

# копируем кэш если есть
if [ -d "$SCRIPT_DIR/cache" ]; then
    cp -R "$SCRIPT_DIR/cache" "$MACOS_DIR/cache"
fi

# ── 4. macdeployqt — бандлируем Qt библиотеки ─────────────────────────────── #
echo ""
echo "=== Шаг 4: macdeployqt ==="
"$QT_DIR/bin/macdeployqt" "$APP_BUNDLE" \
    -qmldir="$SCRIPT_DIR/frontend/qml" \
    -no-strip
echo "[OK] Qt зависимости добавлены"

# ── 5. Правим Info.plist ──────────────────────────────────────────────────── #
PLIST="$APP_BUNDLE/Contents/Info.plist"
if [ -f "$PLIST" ]; then
    # меняем CFBundleName на красивое
    /usr/libexec/PlistBuddy -c "Set :CFBundleName 'TF2 Skin Generator'" "$PLIST" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'TF2 Skin Generator'" "$PLIST" 2>/dev/null || true
fi

# ── 6. Подписываем ad-hoc (без Apple Developer аккаунта) ─────────────────── #
echo ""
echo "=== Шаг 5: подпись ad-hoc ==="
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null && \
    echo "[OK] Подписано (ad-hoc)" || \
    echo "[WARN] Подпись не удалась — приложение всё равно запустится через Ctrl+клик"

# ── 7. Размер результата ──────────────────────────────────────────────────── #
echo ""
echo "=== Готово! ==="
du -sh "$APP_BUNDLE"
echo "Путь: $APP_BUNDLE"
echo ""
echo "Запуск:"
echo "  open \"$APP_BUNDLE\""
echo "  # или из терминала:"
echo "  \"$MACOS_DIR/TF2SkinGenerator\""
