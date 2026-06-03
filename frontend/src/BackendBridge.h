#pragma once
#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantMap>
#include <QVariantList>
#include <QTimer>
#include <functional>

class BackendBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool ready READ isReady NOTIFY readyChanged)
    Q_PROPERTY(QString currentJobId READ currentJobId NOTIFY currentJobIdChanged)
    Q_PROPERTY(int port READ getPort CONSTANT)

public:
    explicit BackendBridge(int port, QObject* parent = nullptr);
    bool isReady() const { return m_ready; }
    QString currentJobId() const { return m_currentJobId; }
    int getPort() const { return m_port; }

public slots:
    // Data fetching
    void loadWeapons();
    void loadConfig();
    void saveConfig(const QVariantMap& cfg);
    void loadHats(const QString& tf2Root);

    // Build
    void startBuild(const QVariantMap& params);
    void cancelBuild();

signals:
    void readyChanged();
    void currentJobIdChanged();
    void weaponsLoaded(const QVariantList& classes);
    void configLoaded(const QVariantMap& cfg);
    void configSaved();
    void hatsLoaded(const QVariantList& hats);
    void buildStarted(const QString& jobId);
    void jobProgress(int pct, const QString& message);
    void buildFinished(bool success, const QString& result);
    void apiError(const QString& message);

private:
    void get(const QString& path, std::function<void(QByteArray)> cb);
    void post(const QString& path, const QByteArray& body, std::function<void(QByteArray)> cb);
    QUrl url(const QString& path) const;
    void pollJob(const QString& jobId);

    QNetworkAccessManager* m_nam;
    QTimer* m_pollTimer;
    int m_port;
    bool m_ready = false;
    QString m_currentJobId;
};
