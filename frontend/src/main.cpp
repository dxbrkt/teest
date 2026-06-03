#include <QtWebEngineQuick/qtwebenginequickglobal.h>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QProcess>
#include <QTimer>
#include <QFile>
#include <QDir>
#include <QThread>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QEventLoop>
#include <QQuickWindow>
#include <QIcon>
#include <QDebug>

#include "BackendBridge.h"

#ifdef Q_OS_MACOS
#include "MacOSGlass.h"
#endif
#ifdef Q_OS_WIN
#include "WindowsGlass.h"
#endif

// Poll /api/ping until the backend answers or timeout expires.
static bool waitForBackend(int port, int timeoutMs = 12000) {
    QNetworkAccessManager nam;
    QUrl pingUrl(QString("http://127.0.0.1:%1/api/ping").arg(port));
    qint64 deadline = QDateTime::currentMSecsSinceEpoch() + timeoutMs;

    while (QDateTime::currentMSecsSinceEpoch() < deadline) {
        QEventLoop loop;
        auto* reply = nam.get(QNetworkRequest(pingUrl));
        QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        QTimer::singleShot(800, &loop, &QEventLoop::quit);
        loop.exec();

        if (reply->error() == QNetworkReply::NoError) {
            reply->deleteLater();
            return true;
        }
        reply->deleteLater();
        QThread::msleep(150);
    }
    return false;
}

// Read port from backend.port file (written by backend_server.py on startup).
static int readPortFile(const QString& rootDir, int waitMs = 8000) {
    QString portPath = rootDir + "/backend.port";
    qint64 deadline = QDateTime::currentMSecsSinceEpoch() + waitMs;
    while (QDateTime::currentMSecsSinceEpoch() < deadline) {
        QFile f(portPath);
        if (f.open(QIODevice::ReadOnly)) {
            bool ok = false;
            int port = f.readAll().trimmed().toInt(&ok);
            if (ok && port > 0) return port;
        }
        QThread::msleep(100);
    }
    return 0;
}

int main(int argc, char* argv[]) {
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    // WebEngine нужно инициализировать до создания QGuiApplication
    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("TF2 Skin Generator");
    app.setOrganizationName("TF2SG");

    // Project root = directory containing this executable's parent (../.. up from .app bundle)
    QString rootDir = QDir::currentPath();

    // ── Start Python backend ──────────────────────────────────────────────── #
    // Remove stale port file from a previous run so we don't read wrong port
    QFile::remove(rootDir + "/backend.port");

    QProcess* backend = new QProcess(&app);
    backend->setWorkingDirectory(rootDir);
    backend->setProcessChannelMode(QProcess::MergedChannels);

    // Try python3 first, then python
    QString pythonBin = "python3";
    backend->start(pythonBin, {rootDir + "/backend_server.py"});
    if (!backend->waitForStarted(3000)) {
        pythonBin = "python";
        backend->start(pythonBin, {rootDir + "/backend_server.py"});
        if (!backend->waitForStarted(3000)) {
            qCritical() << "Cannot start Python backend";
            return 1;
        }
    }

    // ── Wait for backend port ─────────────────────────────────────────────── #
    int port = readPortFile(rootDir);
    if (port == 0) {
        qCritical() << "Backend did not write port file in time";
        backend->kill();
        return 1;
    }

    if (!waitForBackend(port)) {
        qCritical() << "Backend did not become ready on port" << port;
        backend->kill();
        return 1;
    }

    qInfo() << "Backend ready on port" << port;

    // ── Setup QML ─────────────────────────────────────────────────────────── #
    BackendBridge bridge(port);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Backend", &bridge);

    // Enable translucent background for glassmorphism
    QQuickWindow::setDefaultAlphaBuffer(true);

    engine.load(QUrl(QStringLiteral("qrc:/TF2SG/qml/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        backend->kill();
        return -1;
    }

    // ── Apply native glass effect ─────────────────────────────────────────── #
    if (auto* win = qobject_cast<QQuickWindow*>(engine.rootObjects().first())) {
        QTimer::singleShot(50, [win]() {
#ifdef Q_OS_MACOS
            MacOSGlass::applyGlassEffect(win);
#endif
#ifdef Q_OS_WIN
            WindowsGlass::applyGlassEffect(win);
#endif
        });
    }

    QObject::connect(&app, &QGuiApplication::aboutToQuit, [&]() {
        backend->terminate();
        if (!backend->waitForFinished(3000))
            backend->kill();
    });

    return app.exec();
}
