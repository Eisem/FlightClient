#ifndef HTTPSERVICE_H
#define HTTPSERVICE_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonObject>
#include <QJsonDocument>

class HttpService : public QObject
{
    Q_OBJECT
public:
    static HttpService* instance();
    QNetworkReply* post(const QString &endpoint, const QJsonObject &data);
    void setToken(const QString &token);

private:
    explicit HttpService(QObject *parent = nullptr);
    QNetworkAccessManager *m_manager;
    QString m_baseUrl;
    QString m_token;
};

#endif // HTTPSERVICE_H
