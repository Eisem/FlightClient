import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluPage {
    id: root

    // =========================================================
    // 1. 接收参数 (从 FlightSearch 传过来的)
    // =========================================================
    property bool isRoundTrip: false
    property var outboundFlight: null
    property var inboundFlight: null
    property int totalPrice: 0
    property string currentSeatClass: outboundFlight ? (outboundFlight.seatClass || "经济舱") : "经济舱"

    // =========================================================
    // 2. 业务逻辑
    // =========================================================

    // --- 点击“去支付”按钮触发 ---
    function handleSubmitOrder() {
        // 1. 校验登录
        if (appWindow.currentUid === "") {
            showError("用户未登录");
            return;
        }

        showLoading("正在创建订单...");

        // 临时变量存储生成的ID
        var outId = -1;
        var inId = -1;

        // 2. 链式调用：先创建去程，成功后再创建返程
        createOrderStep(outboundFlight, function(id1) {
            outId = id1; // 拿到去程ID

            if (isRoundTrip && inboundFlight) {
                // 如果是往返，继续创建返程
                createOrderStep(inboundFlight, function(id2) {
                    inId = id2; // 拿到返程ID
                    // 两单都成功，触发跳转逻辑
                    handleJump(outId, inId);
                });
            } else {
                // 如果是单程，直接触发跳转逻辑
                handleJump(outId, -1);
            }
        });
    }

    // --- 处理跳转逻辑 (发射信号) ---
    function handleJump(outId, inId) {
        hideLoading();
        showSuccess("订单已生成");

        // 使用定时器缓冲一下，让 loading 动画自然结束
        delayTimer.callback = function() {
            PayDialog.showpay(outId, inId, root.totalPrice);
        }
        delayTimer.start();
    }

    Timer {
        id: delayTimer
        interval: 500
        repeat: false
        property var callback: null
        onTriggered: if(callback) callback()
    }

    // =========================================================
    // 3. 网络请求部分
    // =========================================================

    function createOrderStep(flightData, callback) {
        console.log("尝试连接后端创建订单")

        // 1. 准备数据 Payload
        var payload = {
            "user_id": parseInt(appWindow.currentUid),
            "flight_id": flightData.flight_id || 0,
            "seat_type": mapSeatType(currentSeatClass),
            "seat_number": generateSeatNumber(), // 随机分配一个座位
            "status": "未支付"
        }

        // 2. 创建 XMLHttpRequest 对象
        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/create_order"
        console.log("请求地址: " + url)

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        // 3. 监听状态变化
        xhr.onreadystatechange = function() {
            // readyState == 4 表示请求完成
            if (xhr.readyState === XMLHttpRequest.DONE) {
                // 先判断 HTTP 状态码
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        // 根据后端返回结构判断成功
                        if(response.status === "success" && response.order_id){
                            // 成功逻辑：调用回调函数，传回 order_id
                            callback(response.order_id)
                        } else {
                            // 业务逻辑失败 (例如 status 不是 success)
                            hideLoading()
                            showError(response.message || "订单创建失败: 未知错误")
                        }
                    } catch(e) {
                        console.log("JSON解析失败:", e)
                        hideLoading()
                        showError("数据解析错误")
                    }
                } else {
                    // 处理非 200 的情况 (比如 500 服务器错误)
                    try {
                        // 尝试解析后端返回的 JSON 错误信息
                        var errResp = JSON.parse(xhr.responseText)
                        hideLoading()
                        showError(errResp.message || ("请求失败: " + xhr.status))
                    } catch(e) {
                        // 如果无法解析，直接显示状态码
                        hideLoading()
                        showError("服务器错误: " + xhr.status + " " + xhr.statusText)
                    }
                }
            }
        }

        // 4. 发送 JSON 数据
        xhr.send(JSON.stringify(payload))
    }

    // --- 辅助工具函数 ---
    function mapSeatType(clsName) {
        if (clsName === "公务/头等舱") return 1;
        // if (clsName === "头等舱") return 2;
        return 0; // 经济舱
    }

    // 随机生成座位
    function generateSeatNumber() {
        return (Math.floor(Math.random()*30)+1) + ["A","B","C","D","E","F"][Math.floor(Math.random()*6)];
    }

    function getCityName(str) { return str ? str.replace(/\(.*\)/, "").replace("机场", "").trim() : "" }
    function getAirportName(str) {
        if (!str) return "";
        var n = str.replace(/\(.*\)/, "").trim();
        return n.indexOf("机场")===-1 ? n+"机场" : n;
    }

    // =========================================================
    // 4. UI 界面部分 (保持设计不变)
    // =========================================================

    component FlightTextRow : Item {
        property var flight
        property string tag
        property color tagColor
        property string dateStr: (flight && flight.departure_date) ? flight.departure_date : "2025-11-29"
        Layout.fillWidth: true; Layout.preferredHeight: 80
        ColumnLayout {
            anchors.fill: parent; spacing: 8
            RowLayout {
                spacing: 10
                Rectangle { color: tagColor; radius: 2; width: 36; height: 18; Text { anchors.centerIn: parent; text: tag; color: "white"; font.pixelSize: 11 } }
                Text { text: getCityName(flight?flight.dep_airport:"") + " - " + getCityName(flight?flight.arr_airport:""); font.pixelSize: 16; color: "#333"; font.bold: true }
                Item { Layout.fillWidth: true }
                Text { text: root.currentSeatClass; color: "#999"; font.pixelSize: 12 }
            }
            Text { text: "飞机 " + getAirportName(flight?flight.dep_airport:"") + " - " + getAirportName(flight?flight.arr_airport:"") + "  出发时间: " + dateStr + " " + (flight?flight.departure_time:""); color: "#666"; font.pixelSize: 12; elide: Text.ElideRight; Layout.fillWidth: true }
        }
    }

    // 主滚动视图
    Flickable {
        anchors.fill: parent; anchors.bottomMargin: 80
        contentHeight: contentCol.height + 40; clip: true

        ColumnLayout {
            id: contentCol
            width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
            Layout.maximumWidth: 800; spacing: 15
            Item { Layout.preferredHeight: 10 }

            // 信息卡片
            Rectangle {
                Layout.fillWidth: true; Layout.leftMargin: 20; Layout.rightMargin: 20
                Layout.preferredHeight: innerCol.implicitHeight + 40
                color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
                radius: 4
                FluShadow { radius: 4; elevation: 2; color: "#11000000" }

                ColumnLayout {
                    id: innerCol
                    anchors.fill: parent; anchors.margins: 25; spacing: 20
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "订单总额"; font.pixelSize: 14; color: "#666"; Layout.alignment: Qt.AlignBaseline }
                        Text { text: "¥ " + totalPrice; font.pixelSize: 28; font.bold: true; color: "#FF9500"; Layout.alignment: Qt.AlignBaseline }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f0f0f0" }
                    FlightTextRow { flight: outboundFlight || {}; tag: isRoundTrip?"去程":"单程"; tagColor: "#0086F6" }
                    Rectangle { visible: isRoundTrip; Layout.fillWidth: true; height: 1; color: "#f0f0f0"; opacity: 0.5 }
                    FlightTextRow { visible: isRoundTrip; flight: inboundFlight; tag: "返程"; tagColor: "#FF9500" }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f0f0f0" }
                    RowLayout {
                        spacing: 15
                        Text { text: "乘机人"; color: "#666"; font.pixelSize: 14 }
                        Text { text: "UID: " + (appWindow.currentUid || "未登录"); color: "#333"; font.pixelSize: 14 }
                    }
                }
            }

            // 底部提示
            RowLayout {
                Layout.fillWidth: true; Layout.leftMargin: 25; Layout.rightMargin: 25
                FluIcon { iconSource: FluentIcons.Info; iconSize: 14; color: "#999" }
                Text { text: "点击去支付即表示您已阅读并同意《购票须知》"; color: "#999"; font.pixelSize: 12; Layout.fillWidth: true; wrapMode: Text.WordWrap }
            }
        }
    }

    // 底部栏 (提交订单)
    Rectangle {
        width: parent.width; height: 80; color: FluTheme.dark ? "#2D2D2D" : "#FFFFFF"; anchors.bottom: parent.bottom
        FluShadow { anchors.fill: parent; radius: 0; elevation: 10; color: "#11000000" }
        RowLayout {
            anchors.fill: parent; anchors.margins: 20
            Column {
                Text { text: "应付总额"; color: "#666"; font.pixelSize: 12 }
                Text { text: "¥" + totalPrice; color: "#FF4D4F"; font.pixelSize: 24; font.bold: true }
            }
            Item { Layout.fillWidth: true }

            // 去支付按钮
            FluFilledButton {
                text: "去支付"
                width: 160; height: 44
                normalColor: "#FF9500"
                hoverColor: "#E68600"
                textColor: "white"
                font.bold: true; font.pixelSize: 18

                // 点击后，执行下单逻辑，下单成功后自动发信号
                onClicked: handleSubmitOrder()
            }
        }
    }
}
