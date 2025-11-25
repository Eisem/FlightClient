#include "HttpService.h"

static HttpService* s_instance = nullptr;

HttpService* HttpService::instance() {
    if (!s_instance) s_instance = new HttpService();
    return s_instance;
}

HttpService::HttpService(QObject *parent) : QObject(parent) {
    m_manager = new QNetworkAccessManager(this);
    m_baseUrl = "http://127.0.0.1:8080/api";
}

void HttpService::setToken(const QString &token) {
    m_token = token;
}

QNetworkReply* HttpService::post(const QString &endpoint, const QJsonObject &data) {
    QUrl url(m_baseUrl + endpoint);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    if (!m_token.isEmpty()) {
        request.setRawHeader("Authorization", ("Bearer " + m_token).toUtf8());
    }
    QByteArray rawData = QJsonDocument(data).toJson();
    return m_manager->post(request, rawData);
}
