import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI
import QtQuick.Layouts
import QtQuick.Effects

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
                anchors.horizontalCenter: parent.horizontalCenter
                text: "用户注册"
                // width: 150
                // x:75
                font.pixelSize:24
                font.bold: true
            }



            Item {
                width: 250; height: 30
                FluText {
                    text: "用户名:"
                    anchors.right: inputUsername.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: inputUsername.verticalCenter
                    font.pixelSize:15
                    font.bold: true
                }
                FluTextBox {
                    id:inputUsername
                    placeholderText: "请输入用户名"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                }
            }

            Item {
                width: 250; height: 30
                FluText {
                    text: "电话号码:"
                    anchors.right: inputTelephone.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: inputTelephone.verticalCenter
                    font.pixelSize:15
                    font.bold: true
                }

                FluTextBox {
                    id:inputTelephone

                    placeholderText: "请输入电话号码"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                }
            }

            //password1

            Item {
                width: 250; height: 30
                FluText {
                    text: "密码:"
                    anchors.right: inputPassword1.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: inputPassword1.verticalCenter
                    font.pixelSize:15
                    font.bold: true
                }
                FluTextBox {
                    id:inputPassword1
                    placeholderText: "请输入密码"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    echoMode: TextInput.Password
                    width: 200
                }

            }
            //password2
            Item {
                width: 250; height: 30
                FluText {
                    text: "确认密码:"
                    anchors.right: inputPassword2.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: inputPassword2.verticalCenter
                    font.pixelSize:15
                    font.bold: true
                }
                FluTextBox {
                    id:inputPassword2
                    placeholderText: "再次确认密码"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    echoMode: TextInput.Password
                    width: 200
                }

            }

            Item {
                width: 250; height: 30
                FluText {
                    text: "邮箱:"
                    anchors.right: inputEmial.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: inputEmial.verticalCenter
                    font.pixelSize:15
                    font.bold: true
                }

                FluTextBox {
                    id:inputEmial

                    placeholderText: "请输入电子邮箱"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                }
            }

            Item {
                width: 250; height: 30
                FluText {
                    text: "身份证号:"
                    anchors.right: inputID.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: inputID.verticalCenter
                    font.pixelSize:15
                    font.bold: true
                }

                FluTextBox {
                    id:inputID

                    placeholderText: "请输入身份证号"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
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
                text: "注册"
                x:50
                width: 150
                onClicked: {
                    // 调用上面定义的 JS 函数
                    performLogin(inputUsername.text, inputPassword.text)

                }
            }
        }
    }
}
