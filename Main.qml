import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI

FluWindow {
    id: appWindow
    width: 1000
    height: 640
    title: "航班管理系统"
    visible: true
    minimumHeight: 640
    minimumWidth: 1000
    // === 新增: 全局存储 UID ===
    // 所有页面都可以通过 appWindow.currentUid 访问
    property string currentUid: ""

    Loader {
        id: pageLoader
        anchors.fill: parent
        source: "pages/DashboardPage.qml"
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

    Connections {
        target: pageLoader.item
        ignoreUnknownSignals: true

        // 监听登录成功信号
        function onClickLoginButton() {
            // 登录成功后，跳转到 Dashboard
            console.log("start register")
            appWindow.gotoLoginPage()
        }
    }

    Connections{
        target: pageLoader.item
        ignoreUnknownSignals: true

        function onRegisterBackClicked(){
            appWindow.gotoLoginPage()
        }
    }

    Connections{
        target: pageLoader.item
        ignoreUnknownSignals: true

        function onLoginBackClicked(){
            appWindow.gotoDashboard()
        }
    }

    Connections{
        target: pageLoader.item
        ignoreUnknownSignals: true

        function onClickUserCenterButton(){
            appWindow.gotoUserCenterPage()
        }
    }

    function gotoDashboard() {
        pageLoader.source = "pages/DashboardPage.qml"
    }

    function gotoRegisterPage() {
        pageLoader.source = "pages/RegisterPage.qml"
    }

    function gotoLoginPage() {
        pageLoader.source = "pages/LoginPage1.qml"
    }

    function gotoUserCenterPage() {
        pageLoader.source = "pages/UserCenterPage.qml"
    }


    function logout() {
        // 退出时清空 UID
        appWindow.currentUid = ""
        pageLoader.source = "pages/LoginPage.qml"
    }
}
