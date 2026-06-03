@echo off
chcp 65001 >nul
:: run.bat - builds C++ frontend (if needed) and launches TF2 Skin Generator
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set FRONTEND_DIR=%SCRIPT_DIR%frontend
set BUILD_DIR=%FRONTEND_DIR%\build_win
set EXE=%BUILD_DIR%\Release\Tf2SkinGeneratorUI.exe

echo ============================================
echo  TF2 Skin Generator - Developer Launch
echo ============================================
echo.
echo  NOTE: This script is for DEVELOPERS only.
echo  It requires Qt 6, CMake, Python and Visual
echo  Studio Build Tools to be installed.
echo.
echo  For end users: use the pre-built release
echo  from the Releases page on GitHub.
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
    echo [ERROR] Qt 6 not found.
    echo.
    echo  Please install Qt 6 from: https://www.qt.io/download
    echo  During install select: Qt 6.x.x ^> MSVC 2022 64-bit
    echo.
    pause
    exit /b 1
)
echo [OK] Qt: %QT_DIR%

:: ── Check cmake ───────────────────────────────────────────────────────────── ::
where cmake >nul 2>&1
if errorlevel 1 (
    echo [ERROR] cmake not found.
    echo.
    echo  Install CMake from: https://cmake.org/download
    echo  Or install via Qt installer (it includes CMake).
    echo.
    pause
    exit /b 1
)

:: ── Check Python ──────────────────────────────────────────────────────────── ::
set PYTHON_CMD=
where python >nul 2>&1 && set PYTHON_CMD=python
if "%PYTHON_CMD%"=="" (
    where python3 >nul 2>&1 && set PYTHON_CMD=python3
)
if "%PYTHON_CMD%"=="" (
    echo [ERROR] Python not found.
    echo.
    echo  Install Python 3.10+ from: https://python.org
    echo  During install check "Add Python to PATH"
    echo.
    pause
    exit /b 1
)
echo [OK] Python: %PYTHON_CMD%

:: ── Install Python dependencies ───────────────────────────────────────────── ::
echo [..] Installing Python dependencies...
%PYTHON_CMD% -m pip install -r "%SCRIPT_DIR%requirements.txt" -q --disable-pip-version-check
if errorlevel 1 (
    echo [WARN] pip install finished with errors - continuing...
)
echo [OK] Python dependencies ready

:: ── Build C++ frontend (only if exe does not exist) ───────────────────────── ::
if exist "%EXE%" (
    echo [OK] Frontend already built, skipping build
    goto :launch
)

echo.
echo [..] Building C++ frontend (first run - may take 1-3 minutes)...
echo.

cmake -S "%FRONTEND_DIR%" -B "%BUILD_DIR%" ^
    -DCMAKE_PREFIX_PATH="%QT_DIR%" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -Wno-dev
if errorlevel 1 (
    echo.
    echo [ERROR] CMake configure failed.
    echo.
    echo  Make sure Visual Studio Build Tools are installed:
    echo  https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo.
    pause
    exit /b 1
)

cmake --build "%BUILD_DIR%" --config Release --parallel
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed.
    pause
    exit /b 1
)
echo.
echo [OK] Build complete

:: ── Launch ───────────────────────────────────────────────────────────────── ::
:launch
echo.
echo [..] Launching TF2 Skin Generator...
cd /d "%SCRIPT_DIR%"
start "" "%EXE%"
