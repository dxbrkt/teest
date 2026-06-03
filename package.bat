@echo off
:: package.bat — собирает TF2 Skin Generator в .exe для Windows
:: Результат: dist\TF2SkinGenerator\TF2SkinGenerator.exe
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

:: ── ищем Qt ───────────────────────────────────────────────────────────────── ::
set QT_DIR=
for %%P in (
    "C:\Qt\6.7.0\msvc2019_64"
    "C:\Qt\6.6.0\msvc2019_64"
    "C:\Qt\6.5.0\msvc2019_64"
    "C:\Qt\6.7.0\mingw_64"
    "C:\Qt\6.6.0\mingw_64"
) do (
    if exist "%%~P\bin\windeployqt.exe" (
        set QT_DIR=%%~P
        goto :qt_found
    )
)
echo [ERROR] Qt не найден. Установи с https://www.qt.io/download
pause & exit /b 1

:qt_found
echo [OK] Qt: %QT_DIR%

:: ── 1. C++ фронтенд ──────────────────────────────────────────────────────── ::
echo.
echo === Шаг 1: сборка C++ фронтенда ===
cmake -S "%SCRIPT_DIR%frontend" -B "%SCRIPT_DIR%frontend\build_release" ^
    -DCMAKE_PREFIX_PATH="%QT_DIR%" -DCMAKE_BUILD_TYPE=Release
cmake --build "%SCRIPT_DIR%frontend\build_release" --config Release --parallel
if errorlevel 1 ( echo [ERROR] C++ сборка упала & pause & exit /b 1 )
echo [OK] C++ фронтенд готов

:: ── 2. Python бэкенд через PyInstaller ───────────────────────────────────── ::
echo.
echo === Шаг 2: сборка Python бэкенда ===
pyinstaller --noconfirm "%SCRIPT_DIR%backend.spec" ^
    --distpath "%SCRIPT_DIR%dist_pyinstaller" ^
    --workpath "%SCRIPT_DIR%build_pyinstaller"
if errorlevel 1 ( echo [ERROR] PyInstaller упал & pause & exit /b 1 )
echo [OK] Python бэкенд готов

:: ── 3. Собираем финальную папку ──────────────────────────────────────────── ::
echo.
echo === Шаг 3: финальная сборка ===
set OUT_DIR=%SCRIPT_DIR%dist\TF2SkinGenerator
rmdir /s /q "%OUT_DIR%" 2>nul
mkdir "%OUT_DIR%"

:: копируем exe фронтенда
copy "%SCRIPT_DIR%frontend\build_release\Release\Tf2SkinGeneratorUI.exe" "%OUT_DIR%\TF2SkinGenerator.exe"

:: копируем весь PyInstaller-бандл бэкенда
xcopy /E /I /Q "%SCRIPT_DIR%dist_pyinstaller\backend_server" "%OUT_DIR%"

:: tools
if exist "%SCRIPT_DIR%tools" (
    xcopy /E /I /Q "%SCRIPT_DIR%tools" "%OUT_DIR%\tools"
)

:: ── 4. windeployqt ───────────────────────────────────────────────────────── ::
echo.
echo === Шаг 4: windeployqt ===
"%QT_DIR%\bin\windeployqt.exe" "%OUT_DIR%\TF2SkinGenerator.exe" ^
    --qmldir "%SCRIPT_DIR%frontend\qml" ^
    --release
if errorlevel 1 ( echo [WARN] windeployqt завершился с ошибкой )
echo [OK] Qt зависимости добавлены

echo.
echo === Готово! ===
echo Папка: %OUT_DIR%
echo Запуск: %OUT_DIR%\TF2SkinGenerator.exe
pause
