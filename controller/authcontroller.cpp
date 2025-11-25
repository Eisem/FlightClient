#include "AuthController.h"
#include "HttpService.h"
#include <QTimer>

AuthController::AuthController(QObject *parent) : QObject(parent) {}

void AuthController::login(QString username, QString password) {
    // === 1. 死数据测试逻辑 ===
    // 只要输入 admin/123456，直接算成功，不发网络请求
    if (username == "admin" && password == "123456") {
        // 模拟一点延迟，让体验像网络请求
        QTimer::singleShot(500, this, [=](){
            HttpService::instance()->setToken("mock-token-123456");
            emit loginSuccess();
        });
        return;
    }

    // === 2. 真实网络逻辑 (如果不是 admin 则走这里) ===
    QJsonObject json;
    json["username"] = username;
    json["password"] = password;

    QNetworkReply *reply = HttpService::instance()->post("/login", json);

    connect(reply, &QNetworkReply::finished, this, [=]() {
        if (reply->error() == QNetworkReply::NoError) {
            // 这里写真实的解析逻辑...
            // emit loginSuccess();
        } else {
            // 如果服务器没开，肯定走这里
            emit loginFailed("登录失败：请使用测试账号 admin / 123456");
        }
        reply->deleteLater();
    });
}
