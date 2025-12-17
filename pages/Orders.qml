import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluPage {
    id: root

    // === 1. 状态管理 (保留原逻辑) ===
    property int currentFilterIndex: 0
    property int nextFilterIndex: 0

    PayDialog {
        id: payDialog
        // 当支付成功信号触发时，刷新订单列表
        onPaymentSuccess: {
            console.log("支付成功，正在刷新订单列表...")
            root.fetchOrders() // 重新拉取数据，状态会变为“已支付”
        }
    }

// === 2. 页面加载时获取数据 ===
    Component.onCompleted: {
        fetchOrders()
    }

    // === 3. 网络请求逻辑 ===

    // 获取订单列表
    function fetchOrders() {
        console.log("start fetch orders")
        if (appWindow.currentUid === "") return

        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/get_orders"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.status === "success") {
                            orderModel.clear()
                            var orders = response.data
                            for (var i = 0; i < orders.length; i++) {
                                orderModel.append(orders[i])
                            }
                        }
                    } catch (e) {
                        console.log("JSON解析错误")
                    }
                }
            }
        }
        var data = { "user_id": parseInt(appWindow.currentUid) }
        xhr.send(JSON.stringify(data))
    }

    // 【新增】删除订单函数
    function deleteOrder(orderId) {
        // 这里可以加一个确认弹窗，为了简单直接演示核心逻辑：
        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/delete_order" // 你的后端删除接口

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.status === "success") {
                            showSuccess("订单删除成功")
                            // 删除成功后刷新列表
                            root.fetchOrders()
                        } else {
                            showError(response.message || "删除失败")
                        }
                    } catch (e) {
                        showError("服务器响应解析失败")
                    }
                } else {
                    showError("网络请求失败: " + xhr.status)
                }
            }
        }

        // 构建后端需要的参数
        var data = {
            "user_id": parseInt(appWindow.currentUid),
            "order_id": orderId // 这里透传 model 中的 order_id
        }
        xhr.send(JSON.stringify(data))
    }



    // === 2. 核心动画逻辑 (保留原逻辑) ===
    SequentialAnimation {
        id: refreshAnim
        ParallelAnimation {
            NumberAnimation { target: orderListView; property: "opacity"; to: 0; duration: 100 }
            NumberAnimation { target: listTrans; property: "y"; to: 100; duration: 100 }
        }
        ScriptAction {
            script: {
                currentFilterIndex = nextFilterIndex
                orderListView.positionViewAtBeginning()
            }
        }
        ParallelAnimation {
            NumberAnimation { target: orderListView; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: listTrans; property: "y"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        }
    }

    // === 数据模型 (微调：补全了 arr_time 以便动态显示) ===
    ListModel {
        id: orderModel
        ListElement { order_id: 1; flight_number: "CA1234"; dep_city: "珠海(ZUH)"; arr_city: "北京(BJS)"; dep_time: "2025-12-05 08:30"; arr_time: "11:45"; price: 1250; status: 0; seat_number: "12A"}
        ListElement { order_id: 2; flight_number: "CZ5678"; dep_city: "上海(SHA)"; arr_city: "成都(CTU)"; dep_time: "2025-11-28 14:00"; arr_time: "17:20"; price: 980; status: 1; seat_number: "12A"}
        ListElement { order_id: 3; flight_number: "MU2233"; dep_city: "广州(CAN)"; arr_city: "西安(XIY)"; dep_time: "2025-10-15 09:15"; arr_time: "12:10"; price: 880; status: 1; seat_number: "12A"}
        ListElement { order_id: 4; flight_number: "ZH9988"; dep_city: "深圳(SZX)"; arr_city: "杭州(HGH)"; dep_time: "2025-12-06 18:00"; arr_time: "20:15"; price: 1100; status: 0; seat_number: "12A"}
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ===========================================
        // A. 顶部导航栏 (完全保留)
        // ===========================================
        Rectangle {
            id: headerContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: FluTheme.dark ? Qt.rgba(32/255, 32/255, 32/255, 1) : "#FFFFFF"
            z: 999

            FluShadow { radius: 0; elevation: 2; anchors.fill: parent }

            RowLayout {
                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 15

                Rectangle {
                    Layout.preferredWidth: 240; Layout.preferredHeight: 36
                    color: FluTheme.dark ? Qt.rgba(255,255,255,0.1) : "#E0E0E0"
                    radius: 18

                    RowLayout {
                        anchors.fill: parent; anchors.margins: 3; spacing: 0

                        component FilterTab : Rectangle {
                            id: tabRect
                            property string text
                            property int index
                            Layout.fillHeight: true; Layout.fillWidth: true; radius: 15

                            color: currentFilterIndex === index ? (FluTheme.dark ? "#666" : "#FFFFFF") : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }

                            FluShadow { visible: currentFilterIndex === index; radius: 15; elevation: 1; color: "#33000000" }

                            Text {
                                anchors.centerIn: parent
                                text: tabRect.text
                                font.pixelSize: 13
                                font.bold: currentFilterIndex === index
                                color: currentFilterIndex === index ? FluTheme.fontPrimaryColor : (FluTheme.dark ? "#CCC" : "#666")
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (root.currentFilterIndex !== index) {
                                        root.nextFilterIndex = index
                                        refreshAnim.start()
                                    }
                                }
                            }
                        }
                        FilterTab { text: "全部"; index: 0 }
                        FilterTab { text: "待支付"; index: 1 }
                        FilterTab { text: "已完成"; index: 2 }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }

        // ===========================================
        // B. 列表内容区 (动画保留，卡片微调)
        // ===========================================
        ListView {
            id: orderListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: orderModel
            spacing: 16 // 稍微增加间距，更透气
            topMargin: 15; leftMargin: 20; rightMargin: 20; bottomMargin: 20

            // 动画控制对象
            transform: Translate { id: listTrans; y: 0 }

            delegate: Item {
                // 筛选逻辑
                property bool isMatch: (currentFilterIndex === 0) ||
                                       (currentFilterIndex === 1 && model.status === 0) ||
                                       (currentFilterIndex === 2 && model.status === 1)

                width: orderListView.width - 40
                x: (orderListView.width - width) / 2

                // 显隐逻辑
                height: isMatch ? 170 : 0 // 稍微增加高度以容纳日期
                visible: isMatch

                // === 卡片本体 ===
                Rectangle {
                    id: cardBg
                    anchors.fill: parent
                    anchors.bottomMargin: 10
                    visible: parent.visible
                    radius: 10 // 圆角稍微加大
                    border.width: 1
                    border.color: FluTheme.dark ? "#333" : "#e0e0e0"

                    // --- 1. 顶部 Header (订单号 + 状态) ---
                    Item {
                        id: headerArea
                        height: 44
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 16; anchors.rightMargin: 16

                        FluText {
                            text: "订单号: " + model.order_id.toString().padStart(8, '0')
                            color: "#999999"; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        }

                        // 状态标签
                        Rectangle {
                            width: 60; height: 24; radius: 6
                            color: model.status === 0 ? Qt.rgba(1, 0.58, 0, 0.1) : Qt.rgba(0.29, 0.68, 0.31, 0.1)
                            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right

                            Text {
                                anchors.centerIn: parent
                                text: model.status === 0 ? "待支付" : "已完成"
                                color: model.status === 0 ? "#FF9500" : "#4CAF50"
                                font.pixelSize: 12; font.bold: true
                            }
                        }
                    }

                    // 分割线
                    Rectangle {
                        id: divider; height: 1; color: FluTheme.dark ? "#3E3E3E" : "#F5F5F5"
                        anchors.top: headerArea.bottom; anchors.left: parent.left; anchors.right: parent.right
                    }

                    // --- 2. 中部航班信息 (微调布局) ---
                    Item {
                        id: infoArea
                        anchors.top: divider.bottom; anchors.bottom: footerArea.top
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 24; anchors.rightMargin: 24

                        // 左侧：出发
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            spacing: 4

                            // 增加日期显示
                            FluText {
                                text: model.dep_time.substring(5, 10) // 提取 "12-05"
                                font.pixelSize: 12; color: "#999"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            FluText {
                                text: model.dep_time.split(" ")[1] // 提取 "08:30"
                                font.pixelSize: 26; font.bold: true // 加大字号
                                color: FluTheme.fontPrimaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            FluText {
                                text: model.dep_city
                                color: "#666"; font.pixelSize: 14; font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        // 中间：航班号 + 箭头
                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            // 增加航班号显示
                            Text {
                                text: model.flight_number
                                font.pixelSize: 12; color: "#999"; font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // 装饰性的航线图
                            Item {
                                width: 80; height: 20
                                Rectangle {
                                    width: parent.width; height: 1; color: "#E0E0E0"
                                    anchors.centerIn: parent
                                }
                                FluIcon {
                                    iconSource: FluentIcons.Airplane; iconSize: 14; color: FluTheme.primaryColor
                                    anchors.centerIn: parent
                                    rotation: 0 // 飞机头朝右
                                    // 给飞机加个背景遮挡线条
                                    Rectangle { anchors.fill: parent; color: cardBg.color; z:-1 }
                                }
                            }

                            Text {
                                text: "直飞"; font.pixelSize: 11; color: "#ccc"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        // 右侧：到达
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            spacing: 4

                            FluText {
                                // 简单的逻辑：如果是跨天，可以显示 "+1天" (这里仅做静态展示)
                                text: model.dep_time.substring(5, 10)
                                font.pixelSize: 12; color: "#999"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            FluText {
                                text: model.arr_time || "00:00" // 绑定数据，不再硬编码
                                font.pixelSize: 26; font.bold: true
                                color: FluTheme.fontPrimaryColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            FluText {
                                text: model.arr_city
                                color: "#666"; font.pixelSize: 14; font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // --- 3. 底部 Footer (价格 + 操作) ---
                    Item {
                        id: footerArea
                        height: 52
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 16; anchors.rightMargin: 16

                        // 价格左对齐
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            spacing: 2
                            Text {
                                text: "¥"
                                color: "#FF4D4F"; font.pixelSize: 14; font.bold: true
                                anchors.baseline: priceText.baseline
                            }
                            Text {
                                id: priceText
                                text: model.price
                                color: "#FF4D4F"; font.pixelSize: 22; font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // 按钮组右对齐
                        Row {
                            spacing: 12; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right

                            // === 重点修改：删除按钮 ===
                            FluButton {
                                text: "删除订单"
                                height: 32
                                // 只有已完成(状态1)或已取消的订单可以删除
                                visible: (model.status === 1 || model.status === "已完成")
                                onClicked: {
                                    // 调用上面定义的删除函数
                                    root.deleteOrder(model.order_id)
                                }
                            }

                            FluButton {
                                text: "查看详情"
                                height: 32
                                visible: model.status !== 0
                                onClicked: {
                                    showInfo("查看详情: " + model.order_id)
                                    nav_view.push("qrc:/qt/qml/FlightClient/pages/OrderDetailPage.qml", {
                                        "orderId": model.order_id,
                                        "flightNumber": model.flight_number,
                                        "depCity": model.dep_city,
                                        "arrCity": model.arr_city,
                                        "depTime": model.dep_time,
                                        "arrTime": model.arr_time,
                                        "price": parseFloat(model.price), // 确保转为数字
                                        "status": model.status,
                                        "seat_number": model.seat_number
                                    })
                                }
                            }

                            FluFilledButton {
                                text: "去支付"
                                height: 32
                                visible: model.status === 0
                                normalColor: "#FF9500"; hoverColor: "#FFAA33" // 调整了悬停色
                                onClicked: {
                                    // 【修改这里】调用弹窗的 showPay 函数
                                    // 注意：model.price 和 model.order_id 是你 ListElement 或后端返回的字段
                                    payDialog.showPay(model.order_id.toString(), "", model.price.toString())
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
