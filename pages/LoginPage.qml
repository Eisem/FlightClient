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
        var url = backendBaseUrl + "/api/login" // 你的后端地址
        console.log(url)
//=====================================^^^^^^^====这里的路由根据实际情况修改
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        // 3. 监听状态变化
        xhr.onreadystatechange = function() {
            // readyState == 4 表示请求完成
            if (xhr.readyState === XMLHttpRequest.DONE) {
//                 try{
// //=========================      这一段是需要根据情况修改的          ============
//                     var response = JSON.parse(xhr.responseText)

//                     if(response.status === "success" && response.data.uid){
//                         appWindow.currentUid = response.data.uid
//                         showSuccess("登录成功")
//                         loginPage.loginSuccessSignal()
//                     }else if(response.status === "success"){
//                         errorMessage = "登录异常：返回数据缺少 UID"
//                     }else{
//                         errorMessage = response.message
//                     }
// //===========================================================================
//                 }catch(e){
//                     console.log("解析失败:", e)
//                     errorMessage = "服务器响应错误: " + xhr.status + " (无法解析响应内容)"
//                 }

                // 【修改点2】先判断 HTTP 状态码，避免解析 404 或 500 的 HTML 报错页面
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        // 【修改点3】根据后端 C++ 的结构修改字段获取方式
                        // 后端返回的是: { "status": "success", "user": { "id": 1, ... } }
                        if(response.status === "success" && response.user && response.user.id){
                            appWindow.currentUid = response.user.id // 是 user.id 不是 data.uid
                            showSuccess("登录成功")
                            loginPage.loginSuccessSignal()
                        } else {
                            errorMessage = response.message || "登录失败: 未知错误"
                        }
                    } catch(e) {
                        console.log("JSON解析失败:", e)
                        errorMessage = "数据解析错误"
                    }
                } else {
                    // 处理非 200 的情况 (比如 401 密码错误, 404 找不到地址)
                    try {
                        // 尝试解析后端返回的 JSON 错误信息
                        var errResp = JSON.parse(xhr.responseText)
                        errorMessage = errResp.message || ("请求失败: " + xhr.status)
                    } catch(e) {
                        // 如果后端返回的是纯文本而不是JSON（或者网页），直接显示状态码
                        errorMessage = "服务器错误: " + xhr.status + " " + xhr.statusText
                    }
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
