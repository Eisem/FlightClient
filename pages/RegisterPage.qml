import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI

FluPage {
    id: registerPage

    // signal loginSuccessSignal()
    signal registerBackClicked()

    // 用于显示错误信息的变量
    property string errorMessage: ""

    // === 核心逻辑: JS 实现的 HTTP 请求 ===
    function performRegister(username, password) {
        if(username === "admin" && password === "123456"){
            console.log("123456 login")
            loginPage.loginSuccessSignal()
            return;
        }

        // 1. 清空之前的错误
        errorMessage = ""

        // 2. 创建 XMLHttpRequest 对象
        var xhr = new XMLHttpRequest()
        var url = AppConfig.apiBase + "/login" // 你的后端地址

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        // 3. 监听状态变化
        xhr.onreadystatechange = function() {
            // readyState == 4 表示请求完成
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try{
                    var response = JSON.parse(xhr.responseText)

                    if(response.status === "success" && response.data.uid){
                        appWindow.currentUid = response.data.uid
                        showSuccess("登录成功")
                        loginPage.loginSuccessSignal()
                    }else if(response.status === "success"){
                        errorMessage = "登录异常：返回数据缺少 UID"
                    }else{
                        errorMessage = response.message
                    }
                }catch(e){
                    console.log("解析失败:", e)
                    errorMessage = "服务器响应错误: " + xhr.status + " (无法解析响应内容)"
                }
            }
        }

        // 4. 发送 JSON 数据
        var data = {
            "username": username,
            "password": password
        }
        xhr.send(JSON.stringify(data))
    }

    FluIconButton{
        iconSource: FluentIcons.ChromeBack
        iconSize: 15
        text:"返回登录" // 鼠标悬停时显示

        // 定位到左上角
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.leftMargin: 8

        onClicked: {
            registerPage.registerBackClicked()
        }
    }

    // 界面部分
    Column {
        anchors.centerIn: parent
        spacing: 20

        FluText {
            text: "用户注册"
            font.pixelSize: 24
            font.bold: true
        }

        FluTextBox {
            id: inputUsername
            placeholderText: "请输入用户名 (admin)"
            width: 250
        }

        FluTextBox {
            id: inputPassword
            placeholderText: "请输入密码 (123456)"
            echoMode: TextInput.Password
            width: 250
        }

        // 错误提示文字
        FluText {
            visible: errorMessage !== ""
            text: errorMessage
            color: "red"
            wrapMode: Text.Wrap
            width: 250
        }

        FluFilledButton {
            text: "register"
            width: 250
            onClicked: {
                // 调用上面定义的 JS 函数
                //performRegister(inputUsername.text, inputPassword.text)


            }
        }

    }

}
