#pragma once
#ifdef Q_OS_MACOS

#include <QWindow>

namespace MacOSGlass {
    // Apply native NSVisualEffectView frosted-glass to the window background.
    // Call this after the QQuickWindow is shown.
    void applyGlassEffect(QWindow* window);
}

#endif
