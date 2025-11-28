import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluScrollablePage {
    id: root

    // --- 0. 模拟城市数据模型 ---
    ListModel {
        id: cityModel
        ListElement { name: "珠海(ZUH)"; code: "ZUH" }
        ListElement { name: "北京(BJS)"; code: "BJS" }
        ListElement { name: "上海(SHA)"; code: "SHA" }
        ListElement { name: "广州(CAN)"; code: "CAN" }
        ListElement { name: "深圳(SZX)"; code: "SZX" }
        ListElement { name: "成都(CTU)"; code: "CTU" }
    }

    // === 内部状态 ===
    property string fromCity: "珠海(ZUH)"
    property string toCity: "北京(BJS)"
    property date departureDate: new Date()
    property date returnDate: new Date()
    property bool isRoundTrip: radioRoundTrip.checked
    property string selectedClass: comboClass.currentText
    property bool isSelectingFrom: true

    // 格式化日期：2025-11-28
    function formatDate(d) {
        return Qt.formatDate(d, "yyyy-MM-dd")
    }

    function swapCities() {
        var temp = fromCity; fromCity = toCity; toCity = temp
    }

    // === 主布局 ===
    ColumnLayout {
        Layout.topMargin: 20
        Layout.alignment: Qt.AlignVCenter
        // 限制最大宽度，防止在超宽屏上太扁
        // Layout.maximumWidth: 1200
        spacing: 0

        // 2. 核心搜索卡片
        FluFrame {
            Layout.fillWidth: true
            // 高度自适应，不再写死
            Layout.preferredHeight: contentCol.implicitHeight + 40
            padding: 20
            radius: 8
            // 允许下拉菜单和阴影超出边框
            clip: false

            ColumnLayout {
                id: contentCol
                anchors.fill: parent
                spacing: 20

                // --- 第一行：单程/往返 + 舱位 ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    FluRadioButton { id: radioOneWay; text: "单程"; checked: true }
                    FluRadioButton { id: radioRoundTrip; text: "往返" }
                    Item { Layout.fillWidth: true } // 占位弹簧

                    // 舱位选择
                    FluComboBox {
                        id: comboClass
                        width: 140
                        model: ["经济舱", "公务/头等舱"]
                        currentIndex: 0
                        z: 999 // 保证下拉菜单在最上层
                    }
                }

                // --- 第二行：城市 + 日期 (核心修复区域) ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    // ===========================
                    // 1. 城市选择块 (左侧)
                    // ===========================
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        Layout.minimumWidth: 200
                        color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "#f5f7fa"
                        radius: 6
                        border.color: FluTheme.dark ? "#333" : "#e0e0e0"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // 1.1 出发地
                            MouseArea {
                                id: btnFrom // 【新增】给它一个ID，方便定位
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isSelectingFrom = true
                                    // 【核心修改】将弹窗挂载到当前点击的区域下
                                    cityPopup.parent = btnFrom
                                    cityPopup.open()
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "出发地"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: root.fromCity
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }

                            // 交换图标
                            FluIconButton {
                                iconSource: FluentIcons.Switch
                                iconSize: 16
                                onClicked: swapCities()
                            }

                            // 1.2 目的地
                            MouseArea {
                                id: btnTo // 【新增】给它一个ID
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.isSelectingFrom = false
                                    // 【核心修改】将弹窗挂载到当前点击的区域下
                                    cityPopup.parent = btnTo
                                    cityPopup.open()
                                }
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "目的地"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: root.toCity
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }
                            }
                        }
                    }

                    // 2. 日期选择块 (右侧)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 60
                        Layout.minimumWidth: 200
                        color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "#f5f7fa"
                        radius: 6
                        border.color: FluTheme.dark ? "#333" : "#e0e0e0"

                        RowLayout {
                            anchors.fill: parent
                            spacing: 0

                            // ===========================
                            // 2.1 出发日期
                            // ===========================
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // 1. 视觉层：显示文字（用户看到的）
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "出发日期"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: formatDate(root.departureDate)
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // 2. 交互层：隐形遮罩（用户实际点的）
                                FluCalendarPicker {
                                    id: pickerDepart
                                    anchors.fill: parent // 铺满整个区域
                                    opacity: 0           // 【关键】完全透明，让它不可见
                                    z: 10                // 保证在最上层，能接收点击

                                    onAccepted: {
                                        root.departureDate = current
                                        // FluCalendarPicker 选完日期后会自动关闭弹窗
                                    }
                                }
                            }

                            // 分隔线
                            Rectangle { width: 1; height: 30; color: "#ccc" }

                            // ===========================
                            // 2.2 返回日期
                            // ===========================
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                // 1. 视觉层
                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "返回日期"
                                        color: "#888"
                                        font.pixelSize: 12
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                    Text {
                                        text: root.isRoundTrip ? formatDate(root.returnDate) : "—"
                                        font.bold: true
                                        font.pixelSize: 18
                                        color: FluTheme.fontPrimaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                // 2. 交互层：隐形遮罩
                                FluCalendarPicker {
                                    id: pickerReturn
                                    anchors.fill: parent
                                    opacity: 0 // 透明
                                    z: 10

                                    // 只有往返时才启用
                                    visible: root.isRoundTrip

                                    onAccepted: {
                                        if (current < root.departureDate) {
                                            showError("返回日期不能早于出发日期")
                                            return
                                        }
                                        root.returnDate = current
                                    }
                                }

                                // 禁用时的鼠标样式（可选）
                                MouseArea {
                                    anchors.fill: parent
                                    visible: !root.isRoundTrip
                                    cursorShape: Qt.ForbiddenCursor
                                }
                            }
                        }
                    }

                    // 3. 搜索按钮 (跟在日期后面)
                    FluFilledButton {
                        Layout.preferredHeight: 60 // 高度跟输入框对齐
                        Layout.preferredWidth: 120 // 固定宽度
                        text: "搜索"
                        normalColor: "#FF9500"
                        hoverColor: "#E68600"
                        textColor: "white"
                        font.pixelSize: 18
                        font.bold: true
                        onClicked: {
                            console.log("搜索: " + fromCity + " -> " + toCity)
                            // 这里可以发射信号或调用后端
                        }
                    }
                }
            }
        }
    }

    // ==========================================
    // 城市选择弹窗
    // ==========================================
    Popup {
        id: cityPopup

        // 【核心修改】
        // 1. 删除 anchors.centerIn: parent
        // anchors.centerIn: parent  <-- 删除这行

        // 2. 改为相对定位
        // 因为我们在点击时动态设置了 parent，所以这里的 parent.height 就是点击区域的高度
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
            // ... 内部代码保持不变 ...
            anchors.fill: parent
            spacing: 10

            // 标题栏
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "transparent"

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#eee" }

                Text {
                    anchors.centerIn: parent
                    text: root.isSelectingFrom ? "选择出发城市" : "选择到达城市"
                    font.bold: true
                    font.pixelSize: 16
                    color: FluTheme.fontPrimaryColor
                }
            }

            // 城市列表
            ListView {
                id: cityListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: cityModel

                delegate: Rectangle {
                    width: cityListView.width
                    height: 45
                    color: "transparent"

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.isSelectingFrom) {
                                root.fromCity = model.name
                            } else {
                                root.toCity = model.name
                            }
                            cityPopup.close()
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: FluTheme.primaryColor
                        opacity: itemMouse.containsMouse ? 0.1 : 0
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: model.name
                        font.pixelSize: 14
                        color: FluTheme.fontPrimaryColor
                    }
                }
            }
        }
    }
}
