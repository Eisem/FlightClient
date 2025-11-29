import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI
import FlightClient
import QtQuick.Layouts
import QtQuick.Effects

FluPage {
    id: loginPage

    signal loginSuccessSignal()
    signal clickRegisterButton()
    signal loginBackClicked()

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

    Image{
        id: bgSource
        source: "qrc:/qt/qml/FlightClient/figures/loginBackground.png"
        // anchors.fill: parent

        // 处理边缘效应，边缘发亮透明
        anchors.centerIn: parent
        width: parent.width + 100
        height: parent.height + 100

        fillMode: Image.PreserveAspectCrop // 等比裁剪填满屏幕
        visible: false  // // 隐藏原始图，只显示特效后的图
    }

    // 特效层 (模糊 + 遮罩)
    MultiEffect {
        source: bgSource
        anchors.fill: bgSource

        // 开启模糊
        blurEnabled: true
        blurMax: 64      // 模糊的最大范围
        blur: 1.0       // 当前模糊强度 (0.0 - 1.0)，1.0 最模糊

        // 调节饱和度 (可选，稍微降低一点饱和度会让文字更清楚)
        saturation: 0.5
    }

    // 黑色遮罩层
    // 加上一层淡淡的黑色，防止背景太亮导致白色文字看不清
    Rectangle {
        anchors.fill: bgSource
        color: "black"
        opacity: 0.2 // 调节这里改变背景暗度
    }

    // 防止超出屏幕的部分挡住其他窗口
    clip: true

    FluIconButton{
        iconSource: FluentIcons.ChromeBack
        iconSize: 15
        text:"返回主页" // 鼠标悬停时显示

        // 定位到左上角
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.leftMargin: 8

        onClicked: {
            loginPage.loginBackClicked()
        }
    }

    FluFrame{
        radius: 15
        anchors.centerIn: parent
        width:400
        height: 450
        //RGBA，调透明度
        color: Qt.rgba(1, 1, 1, 0.5)
        Column {
            anchors.centerIn: parent
            spacing: 20
            FluText {
                anchors.onTopChanged: parent

                text: "系统登录"
                width: 150
                x:75
                font.pixelSize:24
                font.bold: true
            }



            Item {
                width: 250; height: 50

                Text {
                    id: labelText // 给它个 ID，方便别人引用
                    text: "用户名："
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter // 垂直居中
                    font.pixelSize:15
                    font.bold: true
                }

                FluTextBox {
                    id:inputUsername
                    // 重点：我的左边，要锁在 labelText 的右边
                    anchors.left: labelText.right

                    anchors.right:parent.right
                    placeholderText: "请输入用户名 (admin)"
                    anchors.verticalCenter: parent.verticalCenter
                    width: 200
                }
            }

            Item {
                width: 250; height: 50

                Text {
                    id: labelText2 // 给它个 ID，方便别人引用
                    text: "密   码:"
                    anchors.left: parent.left
                    anchors.right:labelText.right
                    anchors.verticalCenter: parent.verticalCenter // 垂直居中
                    font.pixelSize:15
                    font.bold: true
                }

                FluTextBox {
                    id:inputPassword
                    // 重点：我的左边，要锁在 labelText 的右边
                    anchors.left: labelText2.right
                    anchors.leftMargin: 10
                    anchors.right:parent.right
                    placeholderText: "请输入密码 (123456)"
                    anchors.verticalCenter: parent.verticalCenter
                    echoMode: TextInput.Password
                    width: 200
                }
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
                x:50
                width: 150
                onClicked: {
                    // 调用上面定义的 JS 函数
                    performLogin(inputUsername.text, inputPassword.text)

                }
            }
            FluFilledButton{
                text: "注册"
                x:50
                width: 150
                onClicked: {
                    loginPage.clickRegisterButton()
                }
            }
    }
    // 界面部分
    }
    FluCheckBox{
        id: useBackend
        text: "是否与后端联调"
        checked: false
        anchors.bottom: parent.bottom
        anchors.left: parent.left
    }

}
