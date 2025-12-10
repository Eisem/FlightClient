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
    function performRegister(username, password1, password2, telephone,email) {
        errorMessage = ""
        if(password1 !== password2){
            errorMessage = "输入的密码不一致"
            return
        }
        //
        if(username === "admin"){
            showSuccess("注册成功")
            registerPage.registerBackClicked()
            return
        }

        // 1. 清空之前的错误


        // 2. 创建 XMLHttpRequest 对象
        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/register" // 你的后端地址

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        // 3. 监听状态变化
        xhr.onreadystatechange = function() {
            // readyState == 4 表示请求完成
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        // 【修改点3】根据后端 C++ 的结构修改字段获取方式
                        // 后端返回的是: { "status": "success", "user": { "id": 1, ... } }
                        if(response.status === "success"){
                            showSuccess("注册成功")
                            registerPage.registerBackClicked()
                        }else{
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
        var data = {
            "username": username,
            "password": password1,
            "telephone": telephone,
            "email":email,
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

    Item {
        id: effectLayer
        anchors.fill: bgSource
        opacity: 0 // <--- 初始状态：完全透明 (即不可见，显示底下的清晰图)

        // 毛玻璃 (代码没变，只是被包进来了)
        MultiEffect {
            source: bgSource
            anchors.fill: parent
            blurEnabled: true
            blurMax: 64
            blur: 1.0
            saturation: 0.5
        }

        // 黑色遮罩 (代码没变，也被包进来了)
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.2
        }
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
        id:registerbox
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
                    performRegister(inputUsername.text, inputPassword1.text,inputPassword2.text,inputTelephone.text,inputEmial.text)

                }
            }
        }
    }

    // 新增并行与串行动画控制器
    // 逻辑：Component 加载完成后自动运行 (running: true)
    ParallelAnimation {
        id: startAnim
        running: true

        // 动画 A：背景由清晰变模糊
        // 控制 effectLayer 的透明度从 0 (看不见) 变成 1 (完全覆盖)
        NumberAnimation {
            target: effectLayer
            property: "opacity"
            from: 0
            to: 1
            duration: 300     // 持续 800 毫秒
            easing.type: Easing.OutCubic // 缓动曲线：先快后慢
        }

        // 动画 B：登录框向上浮动
        // 控制 verticalCenterOffset 从 150 (下方) 回归到 0 (正中)
        NumberAnimation {
            target: registerbox
            property: "anchors.verticalCenterOffset"
            from: 150
            to: 0
            duration: 300
            easing.type: Easing.OutBack // 缓动曲线：带一点回弹效果，更有动感
        }

        // 动画 C：登录框淡入
        NumberAnimation {
            target: registerbox
            property: "opacity"
            from: 0
            to: 1
            duration: 300
        }
    }
}
