cmake_minimum_required(VERSION 3.16)

# OBJCXX only needed on macOS (MacOSGlass.mm)
if(APPLE)
    project(Tf2SkinGeneratorUI LANGUAGES CXX OBJCXX)
else()
    project(Tf2SkinGeneratorUI LANGUAGES CXX)
endif()

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ── Qt6 ──────────────────────────────────────────────────────────────────── #
find_package(Qt6 REQUIRED COMPONENTS
    Core Gui Quick QuickControls2 Network WebEngineQuick WebEngineCore)

# ── Sources ───────────────────────────────────────────────────────────────── #
set(SOURCES
    src/main.cpp
    src/BackendBridge.h
    src/BackendBridge.cpp
)

if(APPLE)
    list(APPEND SOURCES src/MacOSGlass.h src/MacOSGlass.mm)
endif()

if(WIN32)
    list(APPEND SOURCES src/WindowsGlass.h src/WindowsGlass.cpp)
endif()

# WIN32 = no console window on Windows; MACOSX_BUNDLE = .app bundle on macOS
if(WIN32)
    qt_add_executable(Tf2SkinGeneratorUI WIN32 ${SOURCES})
else()
    qt_add_executable(Tf2SkinGeneratorUI ${SOURCES})
endif()

# ── QML module ────────────────────────────────────────────────────────────── #
qt_add_qml_module(Tf2SkinGeneratorUI
    URI TF2SG
    VERSION 1.0
    RESOURCES
        src/CritIcon.png
    QML_FILES
        qml/main.qml
        qml/AppWindow.qml
        qml/components/GlassCard.qml
        qml/components/GlassButton.qml
        qml/components/GlassComboBox.qml
        qml/components/GlassCheckBox.qml
        qml/components/GlassTextField.qml
        qml/components/GlassSeparator.qml
        qml/components/TabButton.qml
        qml/components/SidebarClassBtn.qml
        qml/components/WeaponCard.qml
        qml/panels/WeaponPanel.qml
        qml/panels/PreviewPanel.qml
        qml/panels/SettingsPanel.qml
)

# ── Link ──────────────────────────────────────────────────────────────────── #
target_link_libraries(Tf2SkinGeneratorUI PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
    Qt6::WebEngineQuick
    Qt6::WebEngineCore
)

if(APPLE)
    find_library(APPKIT_LIB AppKit REQUIRED)
    target_link_libraries(Tf2SkinGeneratorUI PRIVATE ${APPKIT_LIB})

    set_target_properties(Tf2SkinGeneratorUI PROPERTIES
        MACOSX_BUNDLE TRUE
        MACOSX_BUNDLE_GUI_IDENTIFIER "com.tf2sg.skinGenerator"
        MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
    )
endif()

if(WIN32)
    # dwmapi.lib for DWM glass effects
    target_link_libraries(Tf2SkinGeneratorUI PRIVATE dwmapi)
endif()

# ── Install ───────────────────────────────────────────────────────────────── #
install(TARGETS Tf2SkinGeneratorUI
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION bin
)
