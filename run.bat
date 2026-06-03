@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set FRONTEND_DIR=%SCRIPT_DIR%frontend
set BUILD_DIR=%FRONTEND_DIR%\build_win
set EXE=%BUILD_DIR%\Release\Tf2SkinGeneratorUI.exe

echo ============================================
echo  TF2 Skin Generator - Developer Mode
echo ============================================
echo.
echo  Requires: Qt 6, CMake, Python, VS Build Tools
echo ============================================
echo.

:: ── Find Qt ───────────────────────────────────────────────────────────────── ::
set QT_DIR=
if exist "C:\Qt\6.11.0\msvc2022_64\lib\cmake\Qt6" set QT_DIR=C:\Qt\6.11.0\msvc2022_64
if exist "C:\Qt\6.10.0\msvc2022_64\lib\cmake\Qt6" set QT_DIR=C:\Qt\6.10.0\msvc2022_64
if exist "C:\Qt\6.9.0\msvc2022_64\lib\cmake\Qt6"  set QT_DIR=C:\Qt\6.9.0\msvc2022_64
if exist "C:\Qt\6.8.0\msvc2022_64\lib\cmake\Qt6"  set QT_DIR=C:\Qt\6.8.0\msvc2022_64
if exist "C:\Qt\6.7.0\msvc2022_64\lib\cmake\Qt6"  set QT_DIR=C:\Qt\6.7.0\msvc2022_64
if exist "C:\Qt\6.7.0\msvc2019_64\lib\cmake\Qt6"  set QT_DIR=C:\Qt\6.7.0\msvc2019_64
if exist "C:\Qt\6.6.0\msvc2019_64\lib\cmake\Qt6"  set QT_DIR=C:\Qt\6.6.0\msvc2019_64
if exist "C:\Qt\6.7.0\mingw_64\lib\cmake\Qt6"     set QT_DIR=C:\Qt\6.7.0\mingw_64
if exist "C:\Qt\6.6.0\mingw_64\lib\cmake\Qt6"     set QT_DIR=C:\Qt\6.6.0\mingw_64

if "%QT_DIR%"=="" (
    echo [ERROR] Qt 6 not found.
    echo.
    echo  Install Qt 6 from qt.io/download
    echo  Select: Qt 6.x - MSVC 2022 64-bit
    echo.
    pause
    exit /b 1
)
echo [OK] Qt: %QT_DIR%

:: ── Check cmake ───────────────────────────────────────────────────────────── ::
where cmake >nul 2>&1
if errorlevel 1 (
    echo [ERROR] cmake not found. Install CMake from cmake.org
    pause
    exit /b 1
)

:: ── Check Python ──────────────────────────────────────────────────────────── ::
set PYTHON_CMD=
where python >nul 2>&1
if not errorlevel 1 set PYTHON_CMD=python
if "%PYTHON_CMD%"=="" (
    where python3 >nul 2>&1
    if not errorlevel 1 set PYTHON_CMD=python3
)
if "%PYTHON_CMD%"=="" (
    echo [ERROR] Python not found. Install Python 3.10+ from python.org
    echo  Check "Add Python to PATH" during install.
    pause
    exit /b 1
)
echo [OK] Python: %PYTHON_CMD%

:: ── Install Python dependencies ───────────────────────────────────────────── ::
echo [..] Installing Python dependencies...
%PYTHON_CMD% -m pip install -r "%SCRIPT_DIR%requirements.txt" -q --disable-pip-version-check
echo [OK] Python dependencies ready

:: ── Build C++ frontend (only if exe does not exist) ───────────────────────── ::
if exist "%EXE%" (
    echo [OK] Frontend already built
    goto :launch
)

echo.
echo [..] Building C++ frontend (first run - takes 1-3 min)...
echo.

cmake -S "%FRONTEND_DIR%" -B "%BUILD_DIR%" -DCMAKE_PREFIX_PATH="%QT_DIR%" -DCMAKE_BUILD_TYPE=Release -Wno-dev
if errorlevel 1 (
    echo.
    echo [ERROR] CMake configure failed.
    echo  Install Visual Studio Build Tools: visualstudio.microsoft.com/visual-cpp-build-tools
    echo.
    pause
    exit /b 1
)

cmake --build "%BUILD_DIR%" --config Release --parallel
if errorlevel 1 (
    echo [ERROR] Build failed.
    pause
    exit /b 1
)
echo [OK] Build complete

:launch
echo.
echo [..] Launching...
cd /d "%SCRIPT_DIR%"
start "" "%EXE%"
