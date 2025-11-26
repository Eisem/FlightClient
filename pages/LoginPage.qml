import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI
import FlightClient

FluPage {
    id: loginPage

    signal loginSuccessSignal()
    signal clickRegisterButton()

    // 用于显示错误信息的变量
    property string errorMessage: ""

    // === 核心逻辑: JS 实现的 HTTP 请求 ===
    function performLogin(username, password) {
        if(!useBackend.checked){
            console.log("前端本地登录")
            loginPage.loginSuccessSignal()
            return;
        }
        console.log("尝试连接后端登录")

        // 1. 清空之前的错误
        errorMessage = ""

        // 2. 创建 XMLHttpRequest 对象
        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/login" // 你的后端地址
        console.log(url)
//=====================================^^^^^^^====这里的路由根据实际情况修改
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        // 3. 监听状态变化
        xhr.onreadystatechange = function() {
            // readyState == 4 表示请求完成
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try{
//=========================      这一段是需要根据情况修改的          ============
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
//===========================================================================
                }catch(e){
                    console.log("解析失败:", e)
                    errorMessage = "服务器响应错误: " + xhr.status + " (无法解析响应内容)"
                }
            }
        }

        // 4. 发送 JSON 数据
//=+=+=+=+=+=+=+=+=+=+=     这一段需要根据实际修改   +=+=+=+=+=+=
        var data = {
            "username": username,
            "password": password
        }
        xhr.send(JSON.stringify(data))
//+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
    }

    // 界面部分
    Column {
        anchors.centerIn: parent
        spacing: 20

        FluText {
            text: "系统登录"
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
            text: "登录"
            width: 250
            onClicked: {
                // 调用上面定义的 JS 函数
                performLogin(inputUsername.text, inputPassword.text)

            }
        }



    }

    FluFilledButton{
        text: "注册"
        width: 100
        onClicked: {
            loginPage.clickRegisterButton()
        }
    }

    FluCheckBox{
        id: useBackend
        text: "是否与后端联调"
        checked: True
        y:300
    }
}
