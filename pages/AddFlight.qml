import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI

FluScrollablePage {
    id: root

    // === 0. 自定义智能输入框组件 (保持不变) ===
    component SmartTextBox : FluTextBox {
        property string hint: ""
        cleanEnabled: false
        text: hint
        color: (text === hint && !activeFocus) ? FluTheme.fontSecondaryColor : FluTheme.fontPrimaryColor
        onActiveFocusChanged: {
            if (activeFocus) { if (text === hint) text = "" }
            else { if (text === "") text = hint }
        }
        function reset() { text = hint; focus = false }
        readonly property bool hasValidInput: text !== "" && text !== hint
    }

    // === 1. 数据模型 (保持不变) ===
    ListModel {
        id: cityModel
        ListElement { name: "北京(BJS)"; code: "BJS" }
        ListElement { name: "上海(SHA)"; code: "SHA" }
        ListElement { name: "广州(CAN)"; code: "CAN" }
        ListElement { name: "深圳(SZX)"; code: "SZX" }
        ListElement { name: "成都(CTU)"; code: "CTU" }
        ListElement { name: "杭州(HGH)"; code: "HGH" }
        ListElement { name: "武汉(WUH)"; code: "WUH" }
        ListElement { name: "西安(XIY)"; code: "XIY" }
        ListElement { name: "重庆(CKG)"; code: "CKG" }
        ListElement { name: "青岛(TAO)"; code: "TAO" }
        ListElement { name: "长沙(CSX)"; code: "CSX" }
        ListElement { name: "南京(NKG)"; code: "NKG" }
        ListElement { name: "厦门(XMN)"; code: "XMN" }
        ListElement { name: "昆明(KMG)"; code: "KMG" }
        ListElement { name: "大连(DLC)"; code: "DLC" }
        ListElement { name: "天津(TSN)"; code: "TSN" }
        ListElement { name: "郑州(CGO)"; code: "CGO" }
        ListElement { name: "三亚(SYX)"; code: "SYX" }
        ListElement { name: "海口(HAK)"; code: "HAK" }
        ListElement { name: "哈尔滨(HRB)"; code: "HRB" }
    }

    // === 2. 内部状态 (保持不变) ===
    property string originCity: "选择出发地"
    property string destCity: "选择目的地"
    property date depDate: new Date()
    property date arrDate: new Date()
    property bool isSelectingOrigin: true

    function formatDate(d) { return Qt.formatDate(d, "yyyy-MM-dd") }
    function getCityCode(cityName) {
        var matches = cityName.match(/\(([^)]+)\)/);
        if (matches && matches.length > 1) return matches[1];
        return "";
    }

    // === 重置表单 (保持不变) ===
    function resetForm() {
        inputFlightNo.reset(); inputAirline.reset(); inputModel.reset()
        inputDepTime.reset(); inputArrTime.reset()
        inputEcoSeats.reset(); inputEcoPrice.reset()
        inputBusSeats.reset(); inputBusPrice.reset()
        inputFirstSeats.reset(); inputFirstPrice.reset()
        originCity = "选择出发地"; destCity = "选择目的地"
        depDate = new Date(); arrDate = new Date()
    }

    // === 3. 提交逻辑 (保持不变) ===
    function submitFlight() {
        if (!inputFlightNo.hasValidInput || !inputAirline.hasValidInput) {
            showError("请填写航班号和航司信息"); return;
        }
        if (getCityCode(originCity) === "" || getCityCode(destCity) === "") {
            showError("请选择有效的出发地和目的地"); return;
        }
        // ... (数据提交逻辑保持不变) ...
        var data = {
            "flight_number": inputFlightNo.text,
            "origin": getCityCode(originCity),
            "destination": getCityCode(destCity),
            "departure_date": formatDate(depDate),
            "departure_time": inputDepTime.text,
            "landing_date": formatDate(arrDate),
            "landing_time": inputArrTime.text,
            "airline": inputAirline.text,
            "aircraft_model": inputModel.text,
            "economy_seats": Number(inputEcoSeats.text),
            "economy_price": Number(inputEcoPrice.text),
            "business_seats": Number(inputBusSeats.text),
            "business_price": Number(inputBusPrice.text),
            "first_class_seats": Number(inputFirstSeats.text),
            "first_class_price": Number(inputFirstPrice.text),
            "date": formatDate(depDate)
        }

        // 模拟成功
        showSuccess("模拟添加成功: " + inputFlightNo.text);
        resetForm();
    }

    // === 4. 界面布局 ===
    ColumnLayout {
        Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
        width: Math.min(root.width * 0.9, 1200)
        spacing: 20
        Layout.topMargin: 20
        Layout.bottomMargin: 40

        FluFrame {
            Layout.fillWidth: true
            padding: 24

            ColumnLayout {
                anchors.fill: parent
                spacing: 20

                // --- 第一行：基本信息 (保持不变) ---
                FluText { text: "基本信息"; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    SmartTextBox { id: inputFlightNo; hint: "航班号 (如 MU5555)"; Layout.fillWidth: true; Layout.preferredWidth: 200 }
                    SmartTextBox { id: inputAirline; hint: "航空公司"; Layout.fillWidth: true; Layout.preferredWidth: 200 }
                    SmartTextBox { id: inputModel; hint: "机型"; Layout.fillWidth: true; Layout.preferredWidth: 200 }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }

                // --- 第二行：航线与时间 (保持不变) ---
                FluText { text: "航线与时间"; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true; spacing: 15
                    Rectangle {
                        Layout.fillWidth: true; height: 50
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"
                        border.color: "#e0e0e0"; radius: 4
                        MouseArea {
                            id: btnOrigin; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.isSelectingOrigin = true; cityPopup.parent = btnOrigin; cityPopup.open() }
                            RowLayout { anchors.centerIn: parent; Text { text: root.originCity; font.bold: true; font.pixelSize: 16; color: FluTheme.fontPrimaryColor } }
                        }
                    }
                    FluIcon { iconSource: FluentIcons.Forward; iconSize: 20; color: "#ccc" }
                    Rectangle {
                        Layout.fillWidth: true; height: 50
                        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#f5f7fa"
                        border.color: "#e0e0e0"; radius: 4
                        MouseArea {
                            id: btnDest; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.isSelectingOrigin = false; cityPopup.parent = btnDest; cityPopup.open() }
                            RowLayout { anchors.centerIn: parent; Text { text: root.destCity; font.bold: true; font.pixelSize: 16; color: FluTheme.fontPrimaryColor } }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 15
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 5
                        Text { text: "起飞 (日期 + 时间)"; font.pixelSize: 12; color: "#888" }
                        RowLayout {
                            Rectangle {
                                Layout.fillWidth: true; Layout.minimumWidth: 120; Layout.preferredWidth: 1; height: 34
                                border.color: "#ccc"; radius: 4; color: "transparent"
                                Text { anchors.centerIn: parent; text: formatDate(root.depDate); color: FluTheme.fontPrimaryColor }
                                FluCalendarPicker { anchors.fill: parent; opacity: 0; onAccepted: { root.depDate = current } }
                            }
                            SmartTextBox { id: inputDepTime; hint: "如08:00"; Layout.fillWidth: true; Layout.minimumWidth: 80; Layout.preferredWidth: 1}
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 5
                        Text { text: "降落 (日期 + 时间)"; font.pixelSize: 12; color: "#888" }
                        RowLayout {
                            Rectangle {
                                Layout.fillWidth: true; Layout.minimumWidth: 120; Layout.preferredWidth: 1; height: 34
                                border.color: "#ccc"; radius: 4; color: "transparent"
                                Text { anchors.centerIn: parent; text: formatDate(root.arrDate); color: FluTheme.fontPrimaryColor }
                                FluCalendarPicker { anchors.fill: parent; opacity: 0; onAccepted: { root.arrDate = current } }
                            }
                            SmartTextBox { id: inputArrTime; hint: "如10:30"; Layout.fillWidth: true; Layout.minimumWidth: 80; Layout.preferredWidth: 1}
                        }
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: "#eee" }

                // --- 第三行：舱位库存与价格 (关键修改) ---
                FluText { text: "舱位库存与价格"; font.bold: true }

                GridLayout {
                    columns: 4
                    rowSpacing: 15
                    columnSpacing: 15
                    Layout.fillWidth: true

                    Text { text: "舱位等级"; font.bold: true; Layout.alignment: Qt.AlignRight }
                    Text { text: "剩余座位数"; font.bold: true; Layout.preferredWidth: 140 }
                    Text { text: "价格 (¥)"; font.bold: true; Layout.preferredWidth: 140 }
                    Item { Layout.fillWidth: true }

                    // --- 经济舱 ---
                    Text { text: "经济舱"; Layout.alignment: Qt.AlignRight }
                    SmartTextBox {
                        id: inputEcoSeats; hint: "如100"
                        Layout.preferredWidth: 140
                    }
                    SmartTextBox {
                        id: inputEcoPrice; hint: "如500"
                        Layout.preferredWidth: 140
                    }
                    Item { Layout.fillWidth: true }

                    // --- 商务舱 ---
                    Text { text: "商务舱"; Layout.alignment: Qt.AlignRight }
                    SmartTextBox {
                        id: inputBusSeats; hint: "如20"
                        Layout.preferredWidth: 140
                    }
                    SmartTextBox {
                        id: inputBusPrice; hint: "如1200"
                        Layout.preferredWidth: 140
                    }
                    Item { Layout.fillWidth: true }

                    // --- 头等舱 ---
                    Text { text: "头等舱"; Layout.alignment: Qt.AlignRight }
                    SmartTextBox {
                        id: inputFirstSeats; hint: "如8"
                        Layout.preferredWidth: 140
                    }
                    SmartTextBox {
                        id: inputFirstPrice; hint: "如2800"
                        Layout.preferredWidth: 140
                    }
                    Item { Layout.fillWidth: true }
                }

                Item { Layout.preferredHeight: 15 }
                FluFilledButton {
                    text: "确认添加航班"
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    font.pixelSize: 16
                    font.bold: true
                    onClicked: submitFlight()
                }
            }
        }
    }

    // === 5. 弹窗  ===
    Popup {
        id: cityPopup
        y: parent.height + 5
        x: (parent.width - width) / 2
        width: 300
        height: 400
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: FluTheme.dark ? "#2d2d2d" : "#ffffff"
            radius: 8
            border.color: FluTheme.dark ? "#444" : "#e4e4e4"
            FluShadow { radius: 8 }
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 40
                color: "transparent"
                Text { anchors.centerIn: parent; text: root.isSelectingOrigin ? "选择出发城市" : "选择到达城市"; font.bold: true }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#eee" }
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                model: cityModel
                delegate: Rectangle {
                    width: parent.width; height: 40; color: "transparent"
                    MouseArea {
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isSelectingOrigin) root.originCity = model.name
                            else root.destCity = model.name
                            cityPopup.close()
                        }
                        Rectangle { anchors.fill: parent; color: FluTheme.primaryColor; opacity: parent.containsMouse ? 0.1 : 0 }
                    }
                    Text { anchors.left: parent.left; anchors.leftMargin: 20; anchors.verticalCenter: parent.verticalCenter; text: model.name }
                }
            }
        }
    }
}
