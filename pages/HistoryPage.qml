import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI

FluPage {
    id: historyPage

    // 数据模型，用于存储后端返回的航班/历史列表
    ListModel {
        id: historyModel
    }

    // 页面加载完成后，立即执行查询
    Component.onCompleted: {
        fetchHistoryData()
    }

    // === 核心逻辑：获取历史记录 ===
    function fetchHistoryData() {
        console.log("开始获取历史记录，UID:", appWindow.currentUid)

        if (appWindow.currentUid === "") {
            showError("用户未登录，无法获取历史")
            return
        }

        var xhr = new XMLHttpRequest()
        // 假设后端接口为 /api/history，通过 URL 参数传递 uid
        var url = backendBaseUrl + "/api/history?uid=" + appWindow.currentUid

        // 如果你的后端要求用 POST 发送 uid，请改用 POST 并 send(JSON.stringify({uid: ...}))
        xhr.open("GET", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.status === "success" && response.data) {
                            historyModel.clear()
                            // 遍历后端返回的数组并添加到 ListModel
                            // 假设 data 是一个数组: [{flightNo: "CA123", ...}, ...]
                            for (var i = 0; i < response.data.length; i++) {
                                historyModel.append(response.data[i])
                            }
                            console.log("历史记录加载完成，共 " + response.data.length + " 条")
                        } else {
                            showError(response.message || "获取数据格式错误")
                        }
                    } catch (e) {
                        console.log("JSON解析失败:", e)
                        showError("数据解析错误")
                    }
                } else {
                    showError("服务器错误: " + xhr.status)
                }
            }
        }
        xhr.send()
    }

    // === 界面布局 ===
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // 标题栏（可选，如果 FluPage 自带标题可省略）
        FluText {
            text: "最近查询记录"
            font.pixelSize: 20
            font.bold: true
            Layout.leftMargin: 20
            Layout.topMargin: 10
        }

        // 列表视图
        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: historyModel
            clip: true

            // ============================================================
            // 【重点】请打开 FlightSearch.qml，将其中的 delegate 代码块
            //  完整复制并替换下方的内容
            // ============================================================
            delegate: FluFrame {
                width: parent.width - 20
                height: 80
                radius: 8
                Layout.alignment: Qt.AlignHCenter

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 20

                    // 示例字段，请根据你的 FlightSearch 修改
                    FluText {
                        text: model.flightNo || "航班号"
                        font.bold: true
                        font.pixelSize: 18
                    }

                    Column {
                        FluText { text: model.depCity || "出发地" }
                        FluText { text: model.depTime || "00:00" ; color: "gray" }
                    }

                    FluIcon { iconSource: FluentIcons.Forward }

                    Column {
                        FluText { text: model.arrCity || "目的地" }
                        FluText { text: model.arrTime || "00:00" ; color: "gray" }
                    }

                    Item { Layout.fillWidth: true } // 占位符

                    FluText {
                        text: "¥ " + (model.price || "0")
                        color: FluTheme.primaryColor
                        font.pixelSize: 20
                    }
                }
            }
            // ============================================================
        }
    }
}
