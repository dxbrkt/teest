#pragma once
#ifdef Q_OS_WIN

#include <QWindow>

namespace WindowsGlass {
    // Apply Mica (Win 11) or Acrylic blur (Win 10) to the window.
    // Call after the window is shown.
    void applyGlassEffect(QWindow* window);
}

#endif
