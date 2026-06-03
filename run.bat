@echo off
:: run.bat — собирает C++ фронтенд (если нужно) и запускает TF2 Skin Generator
setlocal enabledelayedexpansion

set SCRIPT_DIR=%~dp0
set FRONTEND_DIR=%SCRIPT_DIR%frontend
set BUILD_DIR=%FRONTEND_DIR%\build_win
set EXE=%BUILD_DIR%\Release\Tf2SkinGeneratorUI.exe

:: ── Ищем Qt ───────────────────────────────────────────────────────────────── ::
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
    echo.
    echo [ERROR] Qt 6 не найден.
    echo         Установи Qt с https://www.qt.io/download
    echo         Выбери компонент: Qt 6.x.x ^> MSVC 2019/2022 64-bit
    echo.
    pause
    exit /b 1
)
echo [OK] Qt: %QT_DIR%

:: ── Проверяем cmake ───────────────────────────────────────────────────────── ::
where cmake >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] cmake не найден. Установи CMake: https://cmake.org/download
    echo         Или установи Qt — он включает CMake в installer.
    echo.
    pause
    exit /b 1
)

:: ── Проверяем Python ─────────────────────────────────────────────────────── ::
set PYTHON_CMD=
where python >nul 2>&1 && set PYTHON_CMD=python
if "%PYTHON_CMD%"=="" (
    where python3 >nul 2>&1 && set PYTHON_CMD=python3
)
if "%PYTHON_CMD%"=="" (
    echo.
    echo [ERROR] Python не найден.
    echo         Установи Python 3.10+ с https://python.org
    echo         При установке отметь "Add Python to PATH"
    echo.
    pause
    exit /b 1
)
echo [OK] Python: %PYTHON_CMD%

:: ── Устанавливаем Python-зависимости ─────────────────────────────────────── ::
echo [..] Проверяем Python-зависимости...
%PYTHON_CMD% -m pip install -r "%SCRIPT_DIR%requirements.txt" -q --disable-pip-version-check
if errorlevel 1 (
    echo [WARN] pip install завершился с ошибкой — продолжаем...
)
echo [OK] Python-зависимости установлены

:: ── Собираем C++ фронтенд (только если exe не существует) ────────────────── ::
if exist "%EXE%" (
    echo [OK] Фронтенд уже собран, пропускаем сборку
    goto :launch
)

echo.
echo [..] Сборка C++ фронтенда (первый запуск — займёт 1-3 минуты)...
echo.

cmake -S "%FRONTEND_DIR%" -B "%BUILD_DIR%" ^
    -DCMAKE_PREFIX_PATH="%QT_DIR%" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -Wno-dev
if errorlevel 1 (
    echo.
    echo [ERROR] CMake configure завершился с ошибкой.
    echo         Убедись что установлены Visual Studio Build Tools:
    echo         https://visualstudio.microsoft.com/visual-cpp-build-tools/
    echo.
    pause
    exit /b 1
)

cmake --build "%BUILD_DIR%" --config Release --parallel
if errorlevel 1 (
    echo.
    echo [ERROR] Сборка завершилась с ошибкой.
    pause
    exit /b 1
)
echo.
echo [OK] Сборка завершена

:: ── Запуск ───────────────────────────────────────────────────────────────── ::
:launch
echo.
echo [..] Запуск TF2 Skin Generator...
cd /d "%SCRIPT_DIR%"
start "" "%EXE%"
