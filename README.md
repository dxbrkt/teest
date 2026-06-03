# TF2 Skin Generator

Инструмент для создания скинов TF2. Фронтенд написан на C++ (Qt/QML), бэкенд — Python HTTP-сервер.

---

## Требования

### macOS
- [Homebrew](https://brew.sh)
- Qt 6: `brew install qt`
- CMake: `brew install cmake`
- Python 3.10+: `brew install python`
- Python-зависимости: `pip install -r requirements.txt`

### Windows
- [Qt 6](https://www.qt.io/download) (MinGW или MSVC)
- CMake
- Python 3.10+
- Python-зависимости: `pip install -r requirements.txt`

---

## Запуск в режиме разработки

Запускать нужно из **корня проекта**.

### macOS / Linux

```bash
# 1. Собрать C++ фронтенд (один раз)
cd frontend
bash build.sh
cd ..

# 2. Запустить (из корня проекта)
./frontend/build/Tf2SkinGeneratorUI.app/Contents/MacOS/Tf2SkinGeneratorUI
```

Фронтенд сам запустит Python-бэкенд (`backend_server.py`) в фоне.

### Windows

```bat
cd frontend
build.bat
cd ..

frontend\build\Release\Tf2SkinGeneratorUI.exe
```

---

## Сборка финального .app (macOS)

Создаёт `dist/TF2SkinGenerator.app` — единый бандл с бэкендом внутри:

```bash
bash package.sh
open dist/TF2SkinGenerator.app
```

---

## Структура проекта

```
backend_server.py   — Python HTTP-сервер (бэкенд)
frontend/           — C++ Qt/QML фронтенд
  src/              — C++ исходники
  qml/              — QML интерфейс
  CMakeLists.txt
  build.sh / build.bat
src/                — Python-бэкенд (сервисы, данные, конфиг)
tools/              — crowbar, vpk, vtf утилиты
requirements.txt    — Python-зависимости (только бэкенд)
package.sh          — сборка в .app бандл (macOS)
package.bat         — сборка на Windows
```
