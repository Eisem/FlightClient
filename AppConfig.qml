// AppConfig.qml
pragma Singleton
import QtQuick

QtObject {
    // 你的后端基础地址 (不带具体的 /login)
    // 以后要改 IP 只需要改这里
    readonly property string apiBase: "http://127.0.0.1:8080/api"
}
