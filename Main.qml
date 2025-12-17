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
    property string userTrueName: ""
    property string userIdCard: ""

    function fetchUserInfo() {
        console.log("全局正在获取用户信息... UID:", appWindow.currentUid)
        if (!appWindow.currentUid) return

        var xhr = new XMLHttpRequest()
        var url = "http://localhost:8080/api/user/info"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText)
                    if (response.status === "success" && response.data) {
                        var d = response.data
                        // === 更新全局属性 ===
                        if(d.truename) appWindow.userTrueName = d.truename
                        if(d.id_card) {
                            appWindow.userIdCard = d.id_card
                            // appWindow.isVerified = true
                        }
                        console.log("全局用户信息更新完毕")
                    }
                } catch (e) {
                    console.log("JSON解析失败:", e)
                }
            }
        }
        var data = { "uid": appWindow.currentUid }
        xhr.send(JSON.stringify(data))
    }

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
            fetchUserInfo()
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
        pageLoader.source = "pages/LoginPage.qml"
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
