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
#include <QStandardPaths>
#include <QIcon>
#include <QDebug>
#include <QDateTime>

#include "BackendBridge.h"

#ifdef Q_OS_MACOS
#include "MacOSGlass.h"
#endif
#ifdef Q_OS_WIN
#include "WindowsGlass.h"
#endif

// пингуем бэкенд пока не ответит или не вышло время
static bool waitForBackend(int port, int timeoutMs = 15000) {
    QNetworkAccessManager nam;
    QUrl pingUrl(QString("http://127.0.0.1:%1/api/ping").arg(port));
    qint64 deadline = QDateTime::currentMSecsSinceEpoch() + timeoutMs;

    while (QDateTime::currentMSecsSinceEpoch() < deadline) {
        QEventLoop loop;
        auto* reply = nam.get(QNetworkRequest(pingUrl));
        QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
        QTimer::singleShot(900, &loop, &QEventLoop::quit);
        loop.exec();

        if (reply->error() == QNetworkReply::NoError) {
            reply->deleteLater();
            return true;
        }
        reply->deleteLater();
        QThread::msleep(200);
    }
    return false;
}

// читаем порт из файла — ждём пока бэкенд его запишет
static int readPortFile(const QString& portFilePath, int waitMs = 10000) {
    qint64 deadline = QDateTime::currentMSecsSinceEpoch() + waitMs;
    while (QDateTime::currentMSecsSinceEpoch() < deadline) {
        QFile f(portFilePath);
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
    // WebEngine должен инициализироваться до QGuiApplication
    QtWebEngineQuick::initialize();

    QGuiApplication app(argc, argv);
    app.setApplicationName("TF2 Skin Generator");
    app.setOrganizationName("TF2SG");

    // папка где лежит наш бинарник
    QString appDir = QCoreApplication::applicationDirPath();

    // для dev-режима используем currentPath() — пользователь запускает из корня проекта
    // для бандлированного режима — рядом с бинарником
    QString projectRoot = QDir::currentPath();

    // ── Определяем как запускать бэкенд ──────────────────────────────────── //
    // Сначала ищем бандлированный PyInstaller-бинарник рядом с exe
    // Потом fallback на python3 для режима разработки

    QString bundledBackend = appDir + "/backend_server";
#ifdef Q_OS_WIN
    bundledBackend += ".exe";
#endif

    // порт-файл: в бандле пишем в temp, в dev — рядом с проектом
    bool isBundled = QFile::exists(bundledBackend);
    QString portFilePath;
    if (isBundled) {
        portFilePath = QDir::tempPath() + "/tf2sg_backend.port";
    } else {
        portFilePath = projectRoot + "/backend.port";
    }

    // чистим старый порт-файл чтобы не прочитать устаревший
    QFile::remove(portFilePath);

    // ── Запуск бэкенда ────────────────────────────────────────────────────── //
    QProcess* backend = new QProcess(&app);
    backend->setProcessChannelMode(QProcess::MergedChannels);

    if (isBundled) {
        // запускаем собранный бинарник
        backend->setWorkingDirectory(appDir);
        backend->start(bundledBackend, {});
        qInfo() << "Starting bundled backend:" << bundledBackend;
    } else {
        // dev режим — запускаем python
        backend->setWorkingDirectory(projectRoot);
        QString py = "python3";
        backend->start(py, {projectRoot + "/backend_server.py"});
        if (!backend->waitForStarted(2000)) {
            py = "python";
            backend->start(py, {projectRoot + "/backend_server.py"});
        }
        qInfo() << "Starting dev backend:" << projectRoot + "/backend_server.py";
    }

    if (!backend->waitForStarted(5000)) {
        qCritical() << "Cannot start backend";
        return 1;
    }

    // ── Ждём порт и готовности ────────────────────────────────────────────── //
    int port = readPortFile(portFilePath);
    if (port == 0) {
        qCritical() << "Backend did not write port file. Output:" << backend->readAll();
        backend->kill();
        return 1;
    }

    if (!waitForBackend(port)) {
        qCritical() << "Backend not ready on port" << port;
        backend->kill();
        return 1;
    }

    qInfo() << "Backend ready on port" << port;

    // ── QML ───────────────────────────────────────────────────────────────── //
    BackendBridge bridge(port);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("Backend", &bridge);

    QQuickWindow::setDefaultAlphaBuffer(true);
    engine.load(QUrl(QStringLiteral("qrc:/TF2SG/qml/main.qml")));

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Failed to load QML";
        backend->kill();
        return -1;
    }

    // ── Нативное стекло ───────────────────────────────────────────────────── //
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
        // убираем порт-файл при выходе
        QFile::remove(portFilePath);
    });

    return app.exec();
}
