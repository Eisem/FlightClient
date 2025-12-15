import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluPage {
    id: root

    // =========================================================
    // 1. 接收参数
    // =========================================================
    property bool isRoundTrip: false
    property var outboundFlight: null
    property var inboundFlight: null
    property int totalPrice: 0
    property string currentSeatClass: outboundFlight ? (outboundFlight.seatClass || "经济舱") : "经济舱"

    // === 新增：选座状态 ===
    property string selectedSeatLetterOut: "A"
    property string selectedSeatLetterIn: "A"

    // =========================================================
    // 2. 辅助函数
    // =========================================================
    function calcDuration(dep, arr) {
        if(!dep || !arr) return "--:--"
        var d = dep.split(":"); var a = arr.split(":");
        var minDep = parseInt(d[0]) * 60 + parseInt(d[1]);
        var minArr = parseInt(a[0]) * 60 + parseInt(a[1]);
        if(minArr < minDep) minArr += 24 * 60; // 跨天
        var diff = minArr - minDep;
        var h = Math.floor(diff / 60);
        var m = diff % 60;
        return h + "时" + m + "分";
    }

    function generateSeatNumber(isOutbound) {
        // 简单的模拟生成座位号逻辑
        var row = Math.floor(Math.random() * 30) + 1;
        var letter = isOutbound ? selectedSeatLetterOut : selectedSeatLetterIn;
        return row + letter;
    }

    function mapSeatType(clsName) {
        if (clsName === "头等舱") return 2;
        if (clsName === "商务舱") return 1;
        return 0;
    }

    function getCityName(str) { return str ? str.replace(/\(.*\)/, "").replace("机场", "").trim() : "" }

    // =========================================================
    // 3. 业务逻辑 (完全保留)
    // =========================================================
    function handleSubmitOrder() {
        if (appWindow.currentUid === "") {
            showError("用户未登录");
            return;
        }
        showLoading("正在占座并创建订单...");
        var outId = "";
        var inId = "";
        createOrderStep(outboundFlight, true, function(id1) {
            outId = id1.toString();
            if (isRoundTrip && inboundFlight) {
                createOrderStep(inboundFlight, false, function(id2) {
                    inId = id2.toString();
                    handleJump(outId, inId);
                });
            } else {
                handleJump(outId, "");
            }
        });
    }

    function handleJump(outId, inId) {
        hideLoading();
        showSuccess("订单已生成");
        delayTimer.callback = function() {
            payPopup.showPay(outId, inId, root.totalPrice, appWindow.currentUid);
        }
        delayTimer.start();
    }

    Timer {
        id: delayTimer; interval: 500; repeat: false
        property var callback: null
        onTriggered: if(callback) callback()
    }

    // =========================================================
    // 4. 网络请求 (完全保留)
    // =========================================================
    function createOrderStep(flightData, isOutbound, callback) {
        var payload = {
            "user_id": parseInt(appWindow.currentUid),
            "flight_id": flightData.flight_id || 0,
            "seat_type": mapSeatType(currentSeatClass),
            "prefer_letter": isOutbound ? selectedSeatLetterOut : selectedSeatLetterIn,
        }

        console.log("发送创建订单数据：", JSON.stringify(payload))

        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/create_order"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        console.log("后端返回创建结果：", xhr.responseText)
                        if(response.status === "success" && response.order_id){
                            callback(response.order_id)
                        } else {
                            hideLoading();
                            showError(response.message || "创建失败")
                        }
                    } catch(e) { hideLoading(); showError("解析错误") }
                } else {
                    hideLoading(); showError("服务器错误: " + xhr.status)
                }
            }
        }
        xhr.send(JSON.stringify(payload))
    }

    // =========================================================
    // 5. UI 组件定义
    // =========================================================

    // A. 行程卡片
    component ItineraryCard : Rectangle {
        property var flight
        property string tag

        Layout.fillWidth: true
        height: 140
        radius: 8
        color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
        FluShadow { radius: 8; elevation: 2; color: "#11000000" }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16; spacing: 15

            // 顶部 Header
            RowLayout {
                Layout.fillWidth: true; spacing: 8
                Rectangle {
                    width: 36; height: 18; radius: 2
                    color: tag === "去程" ? "#0086F6" : "#FF9500"
                    Text { anchors.centerIn: parent; text: tag; color: "white"; font.pixelSize: 11 }
                }
                Text {
                    text: (flight ? getCityName(flight.dep_airport) : "") + " - " + (flight ? getCityName(flight.arr_airport) : "")
                    font.pixelSize: 16; font.bold: true; color: FluTheme.fontPrimaryColor
                }
                Item { Layout.fillWidth: true }
                Column {
                    Layout.alignment: Qt.AlignRight; spacing: 2
                    Text { text: flight ? flight.departure_date : ""; font.pixelSize: 13; color: "#666"; anchors.right: parent.right }
                }
            }

            // 中间：时间与机场
            RowLayout {
                Layout.fillWidth: true
                // 出发
                Column {
                    Layout.preferredWidth: 100
                    Text { text: flight ? flight.departure_time : "--:--"; font.pixelSize: 30; font.bold: true; color: FluTheme.fontPrimaryColor }
                    Text { text: getCityName(flight ? flight.dep_airport : "") + "机场"; font.pixelSize: 14; color: "#333" }
                }

                // 中间：箭头与时长
                Item {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    Column {
                        anchors.centerIn: parent; width: parent.width * 0.85; spacing: 4
                        Text { text: flight ? flight.flight_number : ""; font.pixelSize: 12; color: "#333"; anchors.horizontalCenter: parent.horizontalCenter }

                        RowLayout {
                            width: parent.width; spacing: 6
                            Rectangle { Layout.fillWidth: true; height: 1; color: "#CCCCCC"; Layout.alignment: Qt.AlignVCenter }
                            FluIcon { iconSource: FluentIcons.Airplane; iconSize: 14; color: "#0086F6"; Layout.alignment: Qt.AlignCenter; rotation: 0 }
                            Rectangle { Layout.fillWidth: true; height: 1; color: "#CCCCCC"; Layout.alignment: Qt.AlignVCenter }
                        }

                        Text {
                            text: calcDuration(flight?flight.departure_time:null, flight?flight.landing_time:null)
                            font.pixelSize: 12; color: "#333"; anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }

                // 到达
                Column {
                    Layout.preferredWidth: 100; Layout.alignment: Qt.AlignRight
                    Text { text: flight ? flight.landing_time : "--:--"; font.pixelSize: 30; font.bold: true; color: FluTheme.fontPrimaryColor; anchors.right: parent.right }
                    Text { text: getCityName(flight ? flight.arr_airport : "") + "机场"; font.pixelSize: 14; color: "#333"; anchors.right: parent.right }
                }
            }
        }
    }

    // B. 乘车人卡片
    component PassengerCard : Rectangle {
        Layout.fillWidth: true; height: 60; radius: 8
        color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
        FluShadow { radius: 8; elevation: 2; color: "#11000000" }

        RowLayout {
            anchors.fill: parent; anchors.margins: 16
            Text { text: "乘机人"; font.pixelSize: 14; color: "#999" }
            Item { width: 10 }
            Text { text: "UID: " + (appWindow.currentUid || "未登录"); font.pixelSize: 16; font.bold: true; color: FluTheme.fontPrimaryColor }
            Text {
                text: "成人票"; font.pixelSize: 12; color: "#0086F6"
                Rectangle { anchors.fill: parent; anchors.margins: -4; color: "transparent"; border.color: "#0086F6"; radius: 4 }
                Layout.leftMargin: 10
            }
            Item { Layout.fillWidth: true }
            Text { text: root.currentSeatClass; font.pixelSize: 14; color: "#666" }
        }
    }

    // C. 选座组件
    component SeatButton : Rectangle {
        property string seatChar
        property bool isSelected
        signal clicked()

        width: 40; height: 40; radius: 6
        color: isSelected ? "#FF9500" : (FluTheme.dark ? "#333" : "#F2F2F2")
        border.color: isSelected ? "#FF9500" : (FluTheme.dark ? "#555" : "#E0E0E0")

        Rectangle {
            width: parent.width - 10; height: 4
            color: parent.border.color
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom; anchors.bottomMargin: 5
            radius: 2; opacity: 0.5
        }
        Text { anchors.centerIn: parent; text: seatChar; font.bold: true; color: isSelected ? "white" : "#666" }
        MouseArea { anchors.fill: parent; onClicked: parent.clicked() }
    }

    // =========================================================
    //  选座辅助组件
    // =========================================================

    // 1. 过道组件
    component AisleSpacer : Item {
        width: 30; height: 40
        Rectangle {
            anchors.centerIn: parent
            width: 24; height: 40
            radius: 4
            color: "#F5F5F5"
            border.color: "#E0E0E0"; border.width: 1
            Text {
                anchors.centerIn: parent
                text: "过\n道"
                font.pixelSize: 10
                color: "#999"
                lineHeight: 0.9
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    // 2. 窗户组件
    component WindowIndicator : Rectangle {
        width: 9; height: 32 // 细长的条
        radius: 3
        color: "#D0D0D0" // 浅灰色，像窗户边框
        Layout.alignment: Qt.AlignVCenter // 垂直居中
    }

    // 3. 座位行组件 (修改了布局，增加了窗户和居中弹簧)
    component SeatRow : RowLayout {
        property string labelText: ""
        property string currentSelected: ""
        property var onSeatClicked: null

        spacing: 15 // 稍微调小一点间距，让整体更紧凑

        // 标题 (固定在左侧，不参与居中挤压，或者也参与)
        Text {
            text: labelText
            color: "#999"; font.pixelSize: 12
            visible: text !== ""
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 30 // 给个固定宽防止跳动
        }

        // --- 【核心修改】左侧弹簧 (Spring) ---
        // 这个 Item 会占据左边所有多余的空间，把后面的内容往右推
        Item { Layout.fillWidth: true }

        // 左窗户
        WindowIndicator {}

        // 左边座位组
        Row {
            spacing: 8
            Repeater {
                model: {
                    var cls = root.currentSeatClass
                    if (cls === "头等舱") return ["A"]
                    if (cls === "商务舱") return ["A", "B"]
                    return ["A", "B", "C"]
                }
                delegate: SeatButton {
                    seatChar: modelData
                    isSelected: currentSelected === modelData
                    onClicked: { if(onSeatClicked) onSeatClicked(modelData) }
                }
            }
        }

        // 中间过道
        AisleSpacer {}

        // 右边座位组
        Row {
            spacing: 8
            Repeater {
                model: {
                    var cls = root.currentSeatClass
                    if (cls === "头等舱") return ["B"]
                    if (cls === "商务舱") return ["C", "D"]
                    return ["D", "E", "F"]
                }
                delegate: SeatButton {
                    seatChar: modelData
                    isSelected: currentSelected === modelData
                    onClicked: { if(onSeatClicked) onSeatClicked(modelData) }
                }
            }
        }

        // 右窗户
        WindowIndicator {}

        // --- 【核心修改】右侧弹簧 (Spring) ---
        // 这个 Item 会占据右边所有多余的空间，把前面的内容往左推
        // 左右两个弹簧一起用力，中间的内容就居中了
        Item { Layout.fillWidth: true }
    }

    // D. 选座服务卡片
    component SeatSelectionCard : Rectangle {
        Layout.fillWidth: true
        height: isRoundTrip ? 240 : 130
        radius: 8
        color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
        FluShadow { radius: 8; elevation: 2; color: "#11000000" }

        ColumnLayout {
            anchors.fill: parent; anchors.margins: 16
            spacing: 15

            RowLayout {
                Text { text: "选座服务"; font.pixelSize: 12; font.bold: true; color: "#FF8800" }
                Item { Layout.fillWidth: true }
                Text { text: "可选1个座位"; font.pixelSize: 12; color: "#0086F6" }
            }

            // 1. 去程选座
            SeatRow {
                labelText: isRoundTrip ? "去程" : ""
                currentSelected: root.selectedSeatLetterOut
                onSeatClicked: function(seat) {
                    root.selectedSeatLetterOut = seat
                }
            }

            // 分割线
            Rectangle {
                visible: isRoundTrip
                Layout.fillWidth: true; height: 1; color: "#f0f0f0"
            }

            // 2. 返程选座
            SeatRow {
                visible: isRoundTrip
                labelText: "返程"
                currentSelected: root.selectedSeatLetterIn
                onSeatClicked: function(seat) {
                    root.selectedSeatLetterIn = seat
                }
            }

            Text {
                text: "若剩余席位无法满足您的需求，系统将自动为您分配席位。"
                color: "#999"; font.pixelSize: 12
            }
        }
    }

    // =========================================================
    // 6. 主视图布局 (完全保留)
    // =========================================================
    Flickable {
        anchors.fill: parent
        anchors.bottomMargin: 80
        contentHeight: layoutCol.height + 40
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
                nav_view.push("qrc:/qt/qml/FlightClient/pages/FlightSearch.qml")
            }
        }

        ColumnLayout {
            id: layoutCol
            width: parent.width * 0.94
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top; anchors.topMargin: 50
            spacing: 12

            ItineraryCard { flight: outboundFlight; tag: isRoundTrip ? "去程" : "单程" }
            ItineraryCard { visible: isRoundTrip; flight: inboundFlight; tag: "返程" }
            PassengerCard {}
            SeatSelectionCard {}

            // 底部协议提示文本
            Text {
                text: "点击去支付按钮表示已阅读并同意 <font color='#0086F6'>《航空运输总条件》</font> <font color='#0086F6'>《服务条款》</font>"
                color: "#999"
                font.pixelSize: 12
                textFormat: Text.RichText // 开启富文本以支持颜色
                Layout.fillWidth: true
                // horizontalAlignment: Text.AlignHCenter
                Layout.topMargin: 5
            }

            Item { height: 20 }
        }
    }

    // =========================================================
    // 7. 底部支付栏 (完全保留)
    // =========================================================
    Rectangle {
        width: parent.width; height: 80
        color: FluTheme.dark ? "#2D2D2D" : "#FFFFFF"
        anchors.bottom: parent.bottom
        FluShadow { anchors.fill: parent; radius: 0; elevation: 10; color: "#11000000" }

        RowLayout {
            anchors.fill: parent; anchors.margins: 20
            Column {
                Text { text: "应付总额"; color: "#666"; font.pixelSize: 14 }
                Text { text: "¥" + totalPrice; color: "#FF4D4F"; font.pixelSize: 24; font.bold: true }
            }
            Item { Layout.fillWidth: true }
            FluFilledButton {
                text: "去支付"
                width: 160; height: 44
                normalColor: "#FF9500"; hoverColor: "#E68600"; textColor: "white"
                font.bold: true; font.pixelSize: 18
                onClicked: handleSubmitOrder()
            }
        }
    }
}
