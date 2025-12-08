import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.settings 1.0 // 用于保存本地记录
import FluentUI

FluPage {
    id: chatPage

    // 定义消息类型常量
    readonly property int type_ME: 0
    readonly property int type_AI: 1

    // === 1. 数据模型 ===
    ListModel {
        id: chatModel
        // 结构: { type: int, content: string, time: string }
    }

    // === 2. 本地存储设置 ===
    Settings {
        id: chatSettings
        category: "ChatHistory"
        // 动态属性，稍后在加载时通过 JS 读写，或者直接用固定的 Key 存所有数据
        property string savedData: ""
    }

    Component.onCompleted: {
        loadHistory()
        // 如果是第一次进入且没有记录，可以模拟一条欢迎语
        if (chatModel.count === 0) {
            appendMessage(type_AI, "您好！我是您的智能出行助手，请问有什么可以帮您？")
        }
    }

    // 页面销毁前保存记录
    Component.onDestruction: {
        saveHistory()
    }

    // === 3. 核心逻辑 ===

    // 加载历史记录
    function loadHistory() {
        if (!appWindow.currentUid) return

        // 生成针对当前用户的 Key
        var userKey = "history_" + appWindow.currentUid
        var jsonStr = chatSettings.value(userKey, "")

        if (jsonStr !== "") {
            try {
                var list = JSON.parse(jsonStr)
                chatModel.clear()
                for (var i = 0; i < list.length; i++) {
                    chatModel.append(list[i])
                }
                listView.positionViewAtEnd() // 滚动到底部
            } catch (e) {
                console.log("历史记录解析失败")
            }
        }
    }

    // 保存历史记录
    function saveHistory() {
        if (!appWindow.currentUid) return

        var list = []
        for (var i = 0; i < chatModel.count; i++) {
            var item = chatModel.get(i)
            list.push({
                "type": item.type,
                "content": item.content,
                "time": item.time
            })
        }
        var userKey = "history_" + appWindow.currentUid
        chatSettings.setValue(userKey, JSON.stringify(list))
    }

    // 添加消息到界面
    function appendMessage(type, content) {
        var now = new Date()
        var timeStr = now.getHours().toString().padStart(2, '0') + ":" +
                      now.getMinutes().toString().padStart(2, '0')

        chatModel.append({
            "type": type,
            "content": content,
            "time": timeStr
        })

        // 延迟一小会儿滚动到底部，确保界面渲染完成
        timerScroll.restart()
    }

    Timer {
        id: timerScroll
        interval: 100
        onTriggered: listView.positionViewAtEnd()
    }

    // 发送消息给后端
    function sendMessage() {
        var msg = inputArea.text.trim()
        if (msg === "") return

        // 1. 先显示自己的消息
        appendMessage(type_ME, msg)
        inputArea.text = "" // 清空输入框

        // 2. 准备网络请求
        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/ai_chat" // 你的后端接口地址

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        // 假设后端返回 { "status": "success", "reply": "AI的回复内容..." }
                        if (response.status === "success" && response.data.chat) {
                            appendMessage(type_AI, response.data.chat)
                        } else {
                            appendMessage(type_AI, "抱歉，我现在有点糊涂了。(后端格式错误)")
                        }
                    } catch (e) {
                        appendMessage(type_AI, "数据解析错误")
                    }
                } else {
                    appendMessage(type_AI, "网络连接失败: " + xhr.status)
                }
                // 收到回复后保存一次，防止崩溃丢失
                saveHistory()
            }
        }

        // 3. 构建发送数据 (UID 单独放在 Body 中)
        var data = {
            "message": msg               // 聊天内容
        }

        console.log("发送AI消息:", JSON.stringify(data))
        xhr.send(JSON.stringify(data))
    }

    // === 4. 界面布局 ===
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // 聊天列表区域
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: chatModel
            spacing: 15

            // 底部留白，防止被输入框遮挡视觉
            footer: Item { height: 20 }
            header: Item { height: 10 }

            delegate: Item {
                width: listView.width
                height: msgRow.height

                RowLayout {
                    id: msgRow
                    // 核心布局逻辑：如果是 AI，左对齐；如果是 我，右对齐
                    anchors.left: model.type === type_AI ? parent.left : undefined
                    anchors.right: model.type === type_ME ? parent.right : undefined
                    anchors.margins: 20
                    spacing: 10

                    // 1. AI 头像 (只在 type == AI 时显示)
                    Avatar{
                        id:avatar1
                        size:36
                        source: "qrc:/qt/qml/FlightClient/figures/123.jpg"
                        visible: model.type === type_AI
                    }

                    // 2. 消息气泡
                    Rectangle {
                        id: bubble
                        // 限制最大宽度为屏幕的 70%
                        Layout.maximumWidth: listView.width * 0.7
                        Layout.preferredWidth: msgText.implicitWidth + 24
                        Layout.preferredHeight: msgText.implicitHeight + 20

                        radius: 8
                        // 颜色区分：AI用灰色/白色，我用主题色
                        color: model.type === type_ME ? FluTheme.primaryColor : (FluTheme.dark ? Qt.rgba(1,1,1,0.1) : Qt.rgba(0,0,0,0.05))

                        Text {
                            id: msgText
                            text: model.content
                            anchors.centerIn: parent
                            width: parent.width - 24
                            wrapMode: Text.Wrap // 自动换行

                            font.pixelSize: 15
                            color: model.type === type_ME ? "white" : FluTheme.fontPrimaryColor
                        }
                    }

                    // 3. 我的头像 (只在 type == ME 时显示)
                    Avatar{
                        id:avatar2
                        size:36
                        source: "qrc:/qt/qml/FlightClient/figures/123.jpg"
                        visible: model.type !== type_AI
                    }
                }
            }
        }

        // 底部输入区域
        Rectangle {
            Layout.fillWidth: true
            height: 70
            color: FluTheme.dark ? Qt.rgba(0,0,0,0.2) : Qt.rgba(1,1,1,0.8)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                FluTextBox {
                    id: inputArea
                    Layout.fillWidth: true
                    placeholderText: "请输入您的问题..."
                    // 回车发送
                    Keys.onReturnPressed: sendMessage()
                    Keys.onEnterPressed: sendMessage()
                }

                FluFilledButton {
                    text: "发送"
                    onClicked: sendMessage()
                    disabled: inputArea.text.trim() === ""
                }
            }
        }
    }
}
