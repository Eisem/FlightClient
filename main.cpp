#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext> // 用于注入 C++ 变量到 QML
#include <QSettings>   // 用于读取配置文件
#include <QDebug>      // 用于打印调试信息
#include <QDir>        // 用于获取路径
#include <QCoreApplication>

// FluentUI 库引用
#include <FluentUI/src/FluentUI.h>

int main(int argc, char *argv[])
{
    // 如果是高分屏，Qt6 通常自动处理，Qt5 可能需要手动设置属性
    // QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    // --- 新增: 读取 config.ini 配置 ---

    // 1. 获取可执行程序所在的目录路径 (构建目录)
    QString appDir = QCoreApplication::applicationDirPath();
    QString configPath = QDir(appDir).filePath("config.ini");

    qDebug() << "正在尝试加载配置文件:" << configPath;

    // 2. 初始化 QSettings
    QSettings settings(configPath, QSettings::IniFormat);

    // 3. 读取配置 (如果没有文件，使用第二个参数作为默认值)
    // 假设你的 ini 文件结构是 [Network] ip=...
    QString serverIp = settings.value("Network/ip", "127.0.2.1").toString();
    QString serverPort = settings.value("Network/port", "8080").toString();

    // 拼接完整的基础 URL，方便 QML 直接使用
    QString baseUrl = QString("http://%1:%2").arg(serverIp, serverPort);

    qDebug() << "后端地址已设置为:" << baseUrl;

    // 4. 将变量注入到 QML 上下文
    // 在 QML 中可以直接使用变量名 "backendBaseUrl" 和 "backendIp"
    engine.rootContext()->setContextProperty("backendBaseUrl", baseUrl);
    engine.rootContext()->setContextProperty("backendIp", serverIp);

    // --- 配置结束 ---

    // FluentUI 初始化 (通常需要在加载 QML 前调用)
    // FluentUI::getInstance()->registerTypes(&engine); // 根据具体版本，可能需要这行

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("FlightClient", "Main");

    return app.exec();
}
