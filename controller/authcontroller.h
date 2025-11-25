#ifndef AUTHCONTROLLER_H
#define AUTHCONTROLLER_H

#include <QObject>

class AuthController : public QObject
{
    Q_OBJECT
public:
    explicit AuthController(QObject *parent = nullptr);
    Q_INVOKABLE void login(QString username, QString password);

signals:
    void loginSuccess();
    void loginFailed(QString message);
};

#endif // AUTHCONTROLLER_H
