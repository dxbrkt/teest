@echo off
:: Build the C++ Qt frontend (Windows)
setlocal

set SCRIPT_DIR=%~dp0
set BUILD_DIR=%SCRIPT_DIR%build_win

:: Find cmake
where cmake >nul 2>&1
if errorlevel 1 (
    echo [ERROR] cmake not found. Install Qt + CMake from https://www.qt.io/download
    pause & exit /b 1
)

:: Common Qt install paths — adjust if yours differs
set QT_CANDIDATES=^
    C:\Qt\6.7.0\msvc2019_64 ^
    C:\Qt\6.6.0\msvc2019_64 ^
    C:\Qt\6.5.0\msvc2019_64 ^
    C:\Qt\6.7.0\mingw_64 ^
    C:\Qt\6.6.0\mingw_64

set QT_DIR=
for %%P in (%QT_CANDIDATES%) do (
    if exist "%%P\lib\cmake\Qt6" (
        set QT_DIR=%%P
        goto :found_qt
    )
)

:found_qt
if "%QT_DIR%"=="" (
    echo [WARN] Qt not found in common paths. Trying without -DCMAKE_PREFIX_PATH.
    echo        Set QT_DIR manually if build fails, e.g.:
    echo        set QT_DIR=C:\Qt\6.7.0\msvc2019_64
)

echo [INFO] Qt:    %QT_DIR%
echo [INFO] Build: %BUILD_DIR%
echo.

:: Configure
if "%QT_DIR%"=="" (
    cmake -S "%SCRIPT_DIR%" -B "%BUILD_DIR%" -DCMAKE_BUILD_TYPE=Release
) else (
    cmake -S "%SCRIPT_DIR%" -B "%BUILD_DIR%" -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH="%QT_DIR%"
)
if errorlevel 1 ( echo [ERROR] Configure failed & pause & exit /b 1 )

:: Build
cmake --build "%BUILD_DIR%" --config Release --parallel
if errorlevel 1 ( echo [ERROR] Build failed & pause & exit /b 1 )

echo.
echo [OK] Build complete!
echo      Binary: %BUILD_DIR%\Release\Tf2SkinGeneratorUI.exe
echo.
echo Run from project root:
echo      cd %SCRIPT_DIR%..
echo      %BUILD_DIR%\Release\Tf2SkinGeneratorUI.exe
pause
