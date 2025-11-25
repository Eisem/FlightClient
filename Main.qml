import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI

FluWindow {
    id: appWindow
    width: 1000
    height: 640
    title: ""
    visible: true

    // === 新增: 全局存储 UID ===
    // 所有页面都可以通过 appWindow.currentUid 访问
    property string currentUid: ""

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: "pages/LoginPage.qml"
    }

    Connections {
        target: pageLoader.item
        ignoreUnknownSignals: true

        // 监听登录成功信号
        function onLoginSuccessSignal() {
            // 登录成功后，跳转到 Dashboard
            console.log("登录成功，UID:", appWindow.currentUid)
            appWindow.gotoDashboard()
        }
    }

    Connections {
        target: pageLoader.item
        ignoreUnknownSignals: true

        // 监听登录成功信号
        function onClickRegisterButton() {
            // 登录成功后，跳转到 Dashboard
            console.log("start register")
            appWindow.gotoRegisterPage()
        }
    }

    function gotoDashboard() {
        pageLoader.source = "pages/DashboardPage.qml"
    }

    function gotoRegisterPage() {
        pageLoader.source = "pages/RegisterPage.qml"
    }

    function logout() {
        // 退出时清空 UID
        appWindow.currentUid = ""
        pageLoader.source = "pages/LoginPage.qml"
    }
}
