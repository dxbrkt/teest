#include "BackendBridge.h"
#include <QNetworkRequest>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QUrlQuery>
#include <QDebug>

BackendBridge::BackendBridge(int port, QObject* parent)
    : QObject(parent), m_port(port)
{
    m_nam = new QNetworkAccessManager(this);
    m_pollTimer = new QTimer(this);
    m_pollTimer->setInterval(400);
    connect(m_pollTimer, &QTimer::timeout, this, [this]() {
        if (!m_currentJobId.isEmpty())
            pollJob(m_currentJobId);
    });
    m_ready = true;
    emit readyChanged();
}

QUrl BackendBridge::url(const QString& path) const {
    return QUrl(QString("http://127.0.0.1:%1%2").arg(m_port).arg(path));
}

void BackendBridge::get(const QString& path, std::function<void(QByteArray)> cb) {
    auto* reply = m_nam->get(QNetworkRequest(url(path)));
    connect(reply, &QNetworkReply::finished, this, [this, reply, cb]() {
        if (reply->error() == QNetworkReply::NoError) {
            cb(reply->readAll());
        } else {
            emit apiError(reply->errorString());
        }
        reply->deleteLater();
    });
}

void BackendBridge::post(const QString& path, const QByteArray& body,
                         std::function<void(QByteArray)> cb) {
    QNetworkRequest req(url(path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    auto* reply = m_nam->post(req, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply, cb]() {
        if (reply->error() == QNetworkReply::NoError) {
            cb(reply->readAll());
        } else {
            emit apiError(reply->errorString());
        }
        reply->deleteLater();
    });
}

// ── Public slots ─────────────────────────────────────────────────────────── #

void BackendBridge::loadWeapons() {
    get("/api/weapons", [this](QByteArray data) {
        auto doc = QJsonDocument::fromJson(data);
        auto arr = doc.object()["classes"].toArray();
        QVariantList classes;
        for (auto v : arr) classes << v.toObject().toVariantMap();
        emit weaponsLoaded(classes);
    });
}

void BackendBridge::loadConfig() {
    get("/api/config", [this](QByteArray data) {
        auto doc = QJsonDocument::fromJson(data);
        emit configLoaded(doc.object().toVariantMap());
    });
}

void BackendBridge::saveConfig(const QVariantMap& cfg) {
    auto body = QJsonDocument(QJsonObject::fromVariantMap(cfg)).toJson(QJsonDocument::Compact);
    post("/api/config", body, [this](QByteArray) {
        emit configSaved();
    });
}

void BackendBridge::loadHats(const QString& tf2Root) {
    QString enc = QUrl::toPercentEncoding(tf2Root);
    get("/api/hats?tf2_root=" + enc, [this](QByteArray data) {
        auto doc = QJsonDocument::fromJson(data);
        auto arr = doc.object()["hats"].toArray();
        QVariantList hats;
        for (auto v : arr) hats << v.toObject().toVariantMap();
        emit hatsLoaded(hats);
    });
}

void BackendBridge::startBuild(const QVariantMap& params) {
    auto body = QJsonDocument(QJsonObject::fromVariantMap(params)).toJson(QJsonDocument::Compact);
    post("/api/build", body, [this](QByteArray data) {
        auto doc = QJsonDocument::fromJson(data);
        QString jobId = doc.object()["job_id"].toString();
        m_currentJobId = jobId;
        emit currentJobIdChanged();
        emit buildStarted(jobId);
        m_pollTimer->start();
    });
}

void BackendBridge::cancelBuild() {
    if (m_currentJobId.isEmpty()) return;
    post("/api/jobs/" + m_currentJobId + "/cancel", {}, [](QByteArray) {});
}

void BackendBridge::pollJob(const QString& jobId) {
    get("/api/jobs/" + jobId, [this, jobId](QByteArray data) {
        auto doc = QJsonDocument::fromJson(data);
        auto obj = doc.object();
        QString status = obj["status"].toString();
        int pct = obj["progress"].toInt();
        QString msg = obj["message"].toString();

        emit jobProgress(pct, msg);

        if (status == "done") {
            m_pollTimer->stop();
            m_currentJobId.clear();
            emit currentJobIdChanged();
            emit buildFinished(true, obj["result"].toString());
        } else if (status == "error") {
            m_pollTimer->stop();
            m_currentJobId.clear();
            emit currentJobIdChanged();
            emit buildFinished(false, obj["error"].toString());
        } else if (status == "cancelled") {
            m_pollTimer->stop();
            m_currentJobId.clear();
            emit currentJobIdChanged();
            emit buildFinished(false, "Cancelled");
        }
    });
}
