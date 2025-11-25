#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <FluentUI/src/FluentUI.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // === 修改: 移除了 C++ 类的注入 ===
    // HttpService 和 AuthController 不再需要

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("FlightClient", "Main");

    return app.exec();
}
