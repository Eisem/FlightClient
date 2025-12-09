import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluPage {
    id: root
    title: "订单确认"

    // =========================================================
    // 1. 接收参数 & 内部状态
    // =========================================================
    property bool isRoundTrip: false
    property var outboundFlight: null
    property var inboundFlight: null
    property int totalPrice: 0
    property string currentSeatClass: outboundFlight ? (outboundFlight.seatClass || "经济舱") : "经济舱"

    // 【核心状态】
    property int outboundOrderId: -1  // 存储去程订单ID
    property int inboundOrderId: -1   // 存储返程订单ID
    property bool isOrdersCreated: false // 是否锁座成功
    property bool isPaid: false          // 是否支付成功

    property string backendBaseUrl: "http://127.0.0.1:8000"

    // =========================================================
    // 2. 生命周期逻辑
    // =========================================================

    // 【核心】页面加载完成后，立即自动创建订单（锁座）
    Component.onCompleted: {
        // 校验登录
        if (appWindow.currentUid === "") {
            showError("用户未登录");
            return; // 实际场景可能需要踢回登录页
        }
        // 立即开始创建订单
        createAllOrders();
    }

    // 注意：这里删除了 onDestruction 取消订单的逻辑
    // 由后端负责清理过期未支付订单

    // =========================================================
    // 3. 业务流程函数
    // =========================================================

    // --- 步骤 A: 创建订单 (进页面自动触发) ---
    function createAllOrders() {
        showLoading("正在为您锁定座位...");

        // 1. 创建去程
        createOrderStep(outboundFlight, function(id1) {
            outboundOrderId = id1; // 存起来

            if (isRoundTrip && inboundFlight) {
                // 2. 创建返程 (如果有)
                createOrderStep(inboundFlight, function(id2) {
                    inboundOrderId = id2; // 存起来
                    finishCreation();
                });
            } else {
                finishCreation();
            }
        });
    }

    function finishCreation() {
        hideLoading();
        isOrdersCreated = true;
        // 锁座成功，启动倒计时
        countdownTimer.start();
        showSuccess("座位已锁定，请在 5 分钟内完成支付");
    }

    // --- 步骤 B: 支付 (点击按钮触发) ---
    function startPayment() {
        // 防御性编程：如果没有订单ID，不允许支付
        if (!isOrdersCreated) return;

        showLoading("正在安全支付...");

        // 1. 支付去程
        payOrderStep(outboundOrderId, outboundFlight.price, function() {
            // 2. 支付返程
            if (isRoundTrip && inboundOrderId !== -1) {
                payOrderStep(inboundOrderId, inboundFlight.price, function() {
                    finishPayment();
                });
            } else {
                finishPayment();
            }
        });
    }

    function finishPayment() {
        hideLoading();
        isPaid = true;         // 标记为已支付
        countdownTimer.stop(); // 停止倒计时
        showSuccess("支付成功！出票中...");

        // 延迟跳转回首页或订单页
        delayTimer.start();
    }

    // =========================================================
    // 4. 底层请求封装
    // =========================================================

    // 创建单笔订单
    function createOrderStep(flightData, callback) {
        var payload = {
            "user_id": parseInt(appWindow.currentUid),
            "flight_id": flightData.flight_id || 0,
            "seat_type": mapSeatType(currentSeatClass),
            "seat_number": generateSeatNumber(),
            "status": "未支付"
        };
        sendRequest("/api/create_order", "POST", payload, function(resp) {
            callback(resp.order_id);
        }, function(err) {
            hideLoading();
            showError("锁座失败，请重试: " + err);
            // 失败处理：可以把 isOrdersCreated 设为 false，并显示“重试”按钮
        });
    }

    // 支付单笔订单
    function payOrderStep(oid, amount, callback) {
        var payload = {
            "order_id": oid.toString(),
            "amount": parseFloat(amount)
        };
        sendRequest("/api/payment", "POST", payload, function(resp) {
            callback();
        }, function(err) {
            hideLoading();
            showError("支付失败: " + err);
        });
    }

    // 通用请求
    function sendRequest(route, method, data, successCallback, errorCallback) {
        var xhr = new XMLHttpRequest();
        xhr.open(method, backendBaseUrl + route, true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var resp = JSON.parse(xhr.responseText);
                        if (resp.status === "success") successCallback(resp);
                        else errorCallback(resp.message || "未知错误");
                    } catch (e) { errorCallback("解析失败"); }
                } else { errorCallback("网络错误: " + xhr.status); }
            }
        };
        xhr.send(data ? JSON.stringify(data) : null);
    }

    // 辅助工具
    function mapSeatType(clsName) {
        if (clsName === "公务/头等舱") return 1;
        if (clsName === "头等舱") return 2;
        return 0;
    }
    // 随机生成座位 (后端要求不为空)
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
    // 5. UI 部分
    // =========================================================

    // 倒计时逻辑
    property int remainingSeconds: 300
    function formatTime(s) { return (Math.floor(s/60)<10?"0":"") + Math.floor(s/60) + ":" + (s%60<10?"0":"") + s%60 }

    Timer {
        id: countdownTimer
        interval: 1000; running: false; repeat: true // 默认不运行，等订单创建完再运行
        onTriggered: {
            if (remainingSeconds > 0) {
                remainingSeconds--;
            } else {
                running = false;
                // 【超时逻辑】只做视觉处理，不发请求
                if (!isPaid) {
                    showError("支付超时，订单已失效");
                    // 按钮状态会在下面自动更新
                }
            }
        }
    }

    Timer {
        id: delayTimer
        interval: 1500
        repeat: false
        onTriggered: appWindow.gotoDashboard()
    }

    // 默认数据(防崩)
    property var defaultFlight: ({dep_airport:"珠海(ZUH)",arr_airport:"北京(BJS)",departure_time:"08:00",landing_time:"11:00",airline:"测试航空",flight_number:"T123",aircraft_model:"737",departure_date:"2025-11-29",flight_id:0})

    // 组件：航班行
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

            // 订单详情卡片
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
                        Text { text: "订单金额"; font.pixelSize: 14; color: "#666"; Layout.alignment: Qt.AlignBaseline }
                        Text { text: "¥ " + totalPrice; font.pixelSize: 28; font.bold: true; color: "#FF9500"; Layout.alignment: Qt.AlignBaseline }
                        Item { Layout.fillWidth: true }
                        Text { text: "剩余时间 "; font.pixelSize: 12; color: "#999" }
                        Text { text: formatTime(remainingSeconds); font.pixelSize: 14; color: "#FF4D4F"; font.family: "Arial" }
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f0f0f0" }
                    FlightTextRow { flight: outboundFlight || defaultFlight; tag: isRoundTrip?"去程":"单程"; tagColor: "#0086F6" }
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

        }
    }

    // 底部栏
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
            FluFilledButton {
                // 按钮文案随状态变化
                text: {
                    if (!isOrdersCreated) return "正在锁座..."
                    if (remainingSeconds <= 0) return "已超时"
                    return "立即支付"
                }
                width: 160; height: 44
                normalColor: (remainingSeconds <= 0 || !isOrdersCreated) ? "#CCC" : "#FF9500"
                hoverColor: "#E68600"
                textColor: "white"
                font.bold: true; font.pixelSize: 18

                // 逻辑：只有[订单已创建] 且 [没超时] 且 [没支付] 才能点
                disabled: (!isOrdersCreated) || (remainingSeconds <= 0) || isPaid

                // 点击触发支付
                onClicked: startPayment()
            }
        }
    }
}
