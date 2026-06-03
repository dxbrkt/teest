#import <AppKit/AppKit.h>
#include "MacOSGlass.h"
#include <QWindow>

namespace MacOSGlass {

void applyGlassEffect(QWindow* qwindow) {
    NSView* view = reinterpret_cast<NSView*>(qwindow->winId());
    if (!view) return;
    NSWindow* win = view.window;
    if (!win) return;

    // Transparent background + extend content under title bar
    win.backgroundColor = [NSColor clearColor];
    win.opaque = NO;
    win.titlebarAppearsTransparent = YES;
    win.styleMask |= NSWindowStyleMaskFullSizeContentView;

    // Hide the native title text (we draw our own in QML)
    win.titleVisibility = NSWindowTitleHidden;

    // NSVisualEffectView fills the entire window (behind Qt content)
    NSVisualEffectView* fx = [[NSVisualEffectView alloc]
        initWithFrame:view.superview ? view.superview.bounds : view.bounds];
    fx.material = NSVisualEffectMaterialHUDWindow;
    fx.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    fx.state = NSVisualEffectStateActive;
    fx.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    fx.wantsLayer = YES;

    NSView* container = view.superview ? view.superview : view;
    [container addSubview:fx positioned:NSWindowBelow relativeTo:view];
}

} // namespace MacOSGlass
