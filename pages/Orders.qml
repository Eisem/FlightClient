import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluPage {
    id: root
    // === 1. 状态管理 ===
    property int currentFilterIndex: 0
    property int nextFilterIndex: 0 // 【新增】用于暂存即将切换的目标索引

    // === 2. 核心动画逻辑 (解决乱跳问题的关键) ===
    SequentialAnimation {
        id: refreshAnim

        // 第一步：旧列表快速隐身 + 下沉
        ParallelAnimation {
            NumberAnimation { target: orderListView; property: "opacity"; to: 0; duration: 100 }
            NumberAnimation { target: listTrans; property: "y"; to: 100; duration: 100 } // 下沉 100px
        }

        // 第二步：趁列表看不见，偷偷切换数据 (此时界面布局会瞬间重排，但用户看不见)
        ScriptAction {
            script: {
                currentFilterIndex = nextFilterIndex
                // 可选：切换后自动滚回顶部
                orderListView.positionViewAtBeginning()
            }
        }

        // 第三步：新列表从下往上优雅升起
        ParallelAnimation {
            NumberAnimation { target: orderListView; property: "opacity"; to: 1; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { target: listTrans; property: "y"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        }
    }

    ListModel {
        id: orderModel
        ListElement { order_id: "ORD20251202001"; flight_number: "CA1234"; dep_city: "珠海(ZUH)"; arr_city: "北京(BJS)"; dep_time: "2025-12-05 08:30"; price: 1250; status: 0 }
        ListElement { order_id: "ORD20251128099"; flight_number: "CZ5678"; dep_city: "上海(SHA)"; arr_city: "成都(CTU)"; dep_time: "2025-11-28 14:00"; price: 980; status: 1 }
        ListElement { order_id: "ORD20251015022"; flight_number: "MU2233"; dep_city: "广州(CAN)"; arr_city: "西安(XIY)"; dep_time: "2025-10-15 09:15"; price: 880; status: 1 }
        ListElement { order_id: "ORD20251205088"; flight_number: "ZH9988"; dep_city: "深圳(SZX)"; arr_city: "杭州(HGH)"; dep_time: "2025-12-06 18:00"; price: 1100; status: 0 }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ===========================================
        // A. 顶部导航栏 (使用之前修复过的高对比度版本)
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
                    color: FluTheme.dark ? Qt.rgba(255,255,255,0.1) : "#E0E0E0" // 深灰底座
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
                                    // 【修改】不直接改 currentFilterIndex，而是触发动画
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
        // B. 列表内容区
        // ===========================================
        ListView {
            id: orderListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: orderModel
            spacing: 12
            topMargin: 15; leftMargin: 20; rightMargin: 20; bottomMargin: 20

            // 【新增】位移变换对象，供动画控制
            transform: Translate { id: listTrans; y: 0 }

            delegate: Item {
                property bool isMatch: (currentFilterIndex === 0) ||
                                       (currentFilterIndex === 1 && model.status === 0) ||
                                       (currentFilterIndex === 2 && model.status === 1)

                width: orderListView.width - 40
                anchors.horizontalCenter: parent.horizontalCenter

                // 【修改】高度直接变化，删掉了 Behavior 动画
                // 因为我们在外部做了整体的淡入淡出，这里如果再有动画反而会穿帮
                height: isMatch ? 160 : 0
                visible: isMatch

                // 卡片内容
                Rectangle {
                    anchors.fill: parent
                    anchors.bottomMargin: 10
                    visible: parent.visible
                    radius: 8
                    color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
                    border.width: 1
                    border.color: FluTheme.dark ? "#3E3E3E" : "#E0E0E0"

                    // === 1. 顶部 Header ===
                    Item {
                        id: headerArea
                        height: 40
                        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 15; anchors.rightMargin: 15

                        FluText {
                            text: "订单号: " + model.order_id
                            color: "#999"; font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        }
                        Rectangle {
                            width: 54; height: 22; radius: 4
                            color: model.status === 0 ? Qt.rgba(1, 0.6, 0, 0.1) : Qt.rgba(0, 0.8, 0, 0.1)
                            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
                            Text {
                                anchors.centerIn: parent
                                text: model.status === 0 ? "待支付" : "已完成"
                                color: model.status === 0 ? "#FF9500" : "#4CAF50"
                                font.pixelSize: 11; font.bold: true
                            }
                        }
                    }

                    Rectangle {
                        id: divider; height: 1; color: "#F0F0F0"
                        anchors.top: headerArea.bottom; anchors.left: parent.left; anchors.right: parent.right
                    }

                    // === 2. 中部信息 ===
                    Item {
                        id: infoArea
                        anchors.top: divider.bottom; anchors.bottom: footerArea.top
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 20; anchors.rightMargin: 20

                        Item {
                            height: childrenRect.height; width: 80
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                            FluText { id: dT; text: model.dep_time.split(" ")[1]; font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            FluText { text: model.dep_city; color: "#666"; font.pixelSize: 13; anchors.top: dT.bottom; anchors.topMargin: 4; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                        Item {
                            height: 40; width: 60; anchors.centerIn: parent
                            FluIcon { iconSource: FluentIcons.Forward; iconSize: 18; color: "#ccc"; anchors.centerIn: parent; anchors.verticalCenterOffset: -8 }
                            Text { text: "直飞"; font.pixelSize: 10; color: "#ddd"; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom }
                        }
                        Item {
                            height: childrenRect.height; width: 80
                            anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
                            FluText { id: aT; text: "12:00"; font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            FluText { text: model.arr_city; color: "#666"; font.pixelSize: 13; anchors.top: aT.bottom; anchors.topMargin: 4; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }

                    // === 3. 底部 ===
                    Item {
                        id: footerArea
                        height: 50
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 20; anchors.rightMargin: 20

                        Text {
                            text: "¥" + model.price
                            color: "#FF4D4F"; font.pixelSize: 20; font.bold: true
                            anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left
                        }
                        Row {
                            spacing: 10; anchors.verticalCenter: parent.verticalCenter; anchors.right: parent.right
                            FluButton { text: "查看详情"; height: 30; visible: model.status !== 0; onClicked: showInfo("查看详情: " + model.order_id) }
                            FluFilledButton { text: "去支付"; height: 30; visible: model.status === 0; normalColor: "#FF9500"; hoverColor: "#E68600"; onClicked: showSuccess("跳转支付: " + model.order_id) }
                        }
                    }
                }
            }
        }
    }
}
