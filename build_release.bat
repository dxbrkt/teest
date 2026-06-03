@echo off
chcp 65001 >nul
:: build_release.bat - builds a self-contained release for end users
:: Result: dist\TF2SkinGenerator\ (zip this folder and share it)
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set OUT_DIR=%SCRIPT_DIR%dist\TF2SkinGenerator

echo ============================================
echo  TF2 Skin Generator - Release Builder
echo ============================================
echo.

:: ── Find Qt ───────────────────────────────────────────────────────────────── ::
set QT_DIR=
for %%P in (
    "C:\Qt\6.11.0\msvc2022_64"
    "C:\Qt\6.10.0\msvc2022_64"
    "C:\Qt\6.9.0\msvc2022_64"
    "C:\Qt\6.8.0\msvc2022_64"
    "C:\Qt\6.7.0\msvc2022_64"
    "C:\Qt\6.7.0\msvc2019_64"
    "C:\Qt\6.6.0\msvc2019_64"
    "C:\Qt\6.5.0\msvc2019_64"
    "C:\Qt\6.7.0\mingw_64"
    "C:\Qt\6.6.0\mingw_64"
) do (
    if exist "%%~P\lib\cmake\Qt6" (
        set QT_DIR=%%~P
        goto :qt_found
    )
)
:qt_found
if "%QT_DIR%"=="" (
    echo [ERROR] Qt 6 not found. Install from https://www.qt.io/download
    pause & exit /b 1
)
echo [OK] Qt: %QT_DIR%

where cmake >nul 2>&1
if errorlevel 1 ( echo [ERROR] cmake not found & pause & exit /b 1 )

where pyinstaller >nul 2>&1
if errorlevel 1 (
    echo [..] Installing PyInstaller...
    pip install pyinstaller -q
)

:: ── Step 1: Build C++ frontend ────────────────────────────────────────────── ::
echo.
echo [Step 1/4] Building C++ frontend...
cmake -S "%SCRIPT_DIR%frontend" -B "%SCRIPT_DIR%frontend\build_release" ^
    -DCMAKE_PREFIX_PATH="%QT_DIR%" ^
    -DCMAKE_BUILD_TYPE=Release -Wno-dev
if errorlevel 1 ( echo [ERROR] CMake configure failed & pause & exit /b 1 )
cmake --build "%SCRIPT_DIR%frontend\build_release" --config Release --parallel
if errorlevel 1 ( echo [ERROR] Build failed & pause & exit /b 1 )
echo [OK] C++ frontend built

:: ── Step 2: Bundle Python backend with PyInstaller ────────────────────────── ::
echo.
echo [Step 2/4] Bundling Python backend...
pyinstaller --noconfirm "%SCRIPT_DIR%backend.spec" ^
    --distpath "%SCRIPT_DIR%dist_pyinstaller" ^
    --workpath "%SCRIPT_DIR%build_pyinstaller"
if errorlevel 1 ( echo [ERROR] PyInstaller failed & pause & exit /b 1 )
echo [OK] Python backend bundled

:: ── Step 3: Assemble release folder ──────────────────────────────────────── ::
echo.
echo [Step 3/4] Assembling release...
if exist "%OUT_DIR%" rmdir /s /q "%OUT_DIR%"
mkdir "%OUT_DIR%"

:: Copy frontend exe
copy "%SCRIPT_DIR%frontend\build_release\Release\Tf2SkinGeneratorUI.exe" ^
     "%OUT_DIR%\TF2SkinGenerator.exe" >nul

:: Copy bundled backend (single exe - everything inside)
copy "%SCRIPT_DIR%dist_pyinstaller\backend_server.exe" "%OUT_DIR%\backend_server.exe" >nul 2>&1
:: If it's a folder bundle, copy whole folder
if exist "%SCRIPT_DIR%dist_pyinstaller\backend_server\" (
    xcopy /E /I /Q "%SCRIPT_DIR%dist_pyinstaller\backend_server" "%OUT_DIR%" >nul
)

:: Copy tools (crowbar, vpk, vtf needed at runtime)
if exist "%SCRIPT_DIR%tools" (
    xcopy /E /I /Q "%SCRIPT_DIR%tools" "%OUT_DIR%\tools" >nul
)

:: ── Step 4: windeployqt - bundle Qt DLLs ─────────────────────────────────── ::
echo.
echo [Step 4/4] Running windeployqt...
"%QT_DIR%\bin\windeployqt.exe" "%OUT_DIR%\TF2SkinGenerator.exe" ^
    --qmldir "%SCRIPT_DIR%frontend\qml" ^
    --release --no-translations
if errorlevel 1 ( echo [WARN] windeployqt had errors - continuing... )
echo [OK] Qt DLLs bundled

:: ── Done ─────────────────────────────────────────────────────────────────── ::
echo.
echo ============================================
echo  DONE! Release folder:
echo  %OUT_DIR%
echo.
echo  Zip that folder and share it.
echo  Users just run TF2SkinGenerator.exe
echo  No installs required.
echo ============================================
echo.
pause
