#ifdef Q_OS_WIN
#include "WindowsGlass.h"

#include <QWindow>
#include <QSysInfo>
#include <QDebug>

#include <windows.h>
#include <dwmapi.h>

// ─── Windows 11: Mica / Acrylic via DWMWA_SYSTEMBACKDROP_TYPE ────────────── #
// Available on Windows 11 build 22621+ (22H2)
#ifndef DWMWA_SYSTEMBACKDROP_TYPE
#define DWMWA_SYSTEMBACKDROP_TYPE 38
#endif

enum DWM_SYSTEMBACKDROP_TYPE_EXTRA {
    DWMSBT_AUTO            = 0,
    DWMSBT_NONE            = 1,
    DWMSBT_MAINWINDOW      = 2,   // Mica
    DWMSBT_TRANSIENTWINDOW = 3,   // Acrylic
    DWMSBT_TABBEDWINDOW    = 4,
};

// ─── Windows 10: Acrylic via SetWindowCompositionAttribute (undocumented) ─── #
enum ACCENT_STATE {
    ACCENT_DISABLED                   = 0,
    ACCENT_ENABLE_GRADIENT            = 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT = 2,
    ACCENT_ENABLE_BLURBEHIND          = 3,
    ACCENT_ENABLE_ACRYLICBLURBEHIND   = 4,   // Win 10 1803+
};

struct ACCENT_POLICY {
    DWORD AccentState;
    DWORD AccentFlags;
    DWORD GradientColor;   // AABBGGRR — AA=alpha, dark tint
    DWORD AnimationId;
};

enum WINDOWCOMPOSITIONATTRIB { WCA_ACCENT_POLICY = 19 };

struct WINDOWCOMPOSITIONATTRIBDATA {
    WINDOWCOMPOSITIONATTRIB Attribute;
    PVOID                   pData;
    SIZE_T                  cbData;
};

typedef BOOL(WINAPI* PFN_SetWindowCompositionAttribute)(HWND, WINDOWCOMPOSITIONATTRIBDATA*);

// ─── Helpers ─────────────────────────────────────────────────────────────── #

static bool isWindows11OrNewer() {
    // Win11 first build = 22000
    return QSysInfo::kernelVersion().split('.').value(2).toInt() >= 22000;
}

static bool applyMica(HWND hwnd) {
    // Extend DWM frame to cover entire client area
    MARGINS m = {-1, -1, -1, -1};
    if (FAILED(DwmExtendFrameIntoClientArea(hwnd, &m)))
        return false;

    // Enable Mica backdrop
    int backdrop = DWMSBT_MAINWINDOW;
    HRESULT hr = DwmSetWindowAttribute(hwnd, DWMWA_SYSTEMBACKDROP_TYPE,
                                       &backdrop, sizeof(backdrop));
    if (FAILED(hr)) {
        // Fallback: try DWMWA_MICA_EFFECT (older Win11 builds)
        BOOL micaOn = TRUE;
        DwmSetWindowAttribute(hwnd, 1029 /*DWMWA_MICA_EFFECT*/, &micaOn, sizeof(micaOn));
    }

    // Enable dark mode title bar to match dark glass UI
    BOOL dark = TRUE;
    DwmSetWindowAttribute(hwnd, 20 /*DWMWA_USE_IMMERSIVE_DARK_MODE*/, &dark, sizeof(dark));

    qInfo() << "WindowsGlass: Mica applied (Win11)";
    return true;
}

static bool applyAcrylic(HWND hwnd) {
    auto fn = reinterpret_cast<PFN_SetWindowCompositionAttribute>(
        GetProcAddress(GetModuleHandleW(L"user32.dll"), "SetWindowCompositionAttribute"));
    if (!fn) return false;

    // Dark semi-transparent acrylic tint: AABBGGRR
    // 0xCC0D0D0D = 80% opacity, very dark charcoal
    ACCENT_POLICY policy {
        ACCENT_ENABLE_ACRYLICBLURBEHIND,
        0,
        0xCC0D0D0D,
        0
    };
    WINDOWCOMPOSITIONATTRIBDATA data { WCA_ACCENT_POLICY, &policy, sizeof(policy) };
    fn(hwnd, &data);

    // Dark title bar
    BOOL dark = TRUE;
    DwmSetWindowAttribute(hwnd, 20, &dark, sizeof(dark));

    // Extend DWM frame
    MARGINS m = {-1, -1, -1, -1};
    DwmExtendFrameIntoClientArea(hwnd, &m);

    qInfo() << "WindowsGlass: Acrylic applied (Win10)";
    return true;
}

// ─── Public ───────────────────────────────────────────────────────────────── #

void WindowsGlass::applyGlassEffect(QWindow* window) {
    HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (!hwnd) {
        qWarning() << "WindowsGlass: no HWND";
        return;
    }

    if (isWindows11OrNewer()) {
        if (!applyMica(hwnd))
            applyAcrylic(hwnd);
    } else {
        applyAcrylic(hwnd);
    }
}

#endif // Q_OS_WIN
