import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

FluPage {
    id: root

    // =========================================================
    // 1. 接收参数 (从 Orders.qml 传过来)
    //    直接定义具体的字段，方便从 Model 传值
    // =========================================================
    property string orderId: ""
    property string flightNumber: ""
    property string depCity: ""
    property string arrCity: ""
    property string depTime: "" // 格式: "2025-12-05 08:30"
    property string arrTime: "" // 格式: "11:45"
    property double price: 0
    property int status: 0 // 0:待支付, 1:已完成

    // 辅助处理函数 (保留原有的字符串处理)
    function getCityName(str) { return str ? str.replace(/\(.*\)/, "").replace("机场", "").trim() : "" }
    function getDate(fullTime) { return fullTime ? fullTime.split(" ")[0] : "" }
    function getTime(fullTime) { return fullTime ? fullTime.split(" ")[1] : fullTime }

    // =========================================================
    // 2. UI 界面
    // =========================================================

    Flickable {
        anchors.fill: parent
        contentHeight: contentCol.height + 40
        clip: true

        // 返回按钮
        FluIconButton {
            iconSource: FluentIcons.ChromeBack
            iconSize: 15
            text: "返回列表"
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.leftMargin: 10
            onClicked: {
                nav_view.push("qrc:/qt/qml/FlightClient/pages/Orders.qml")
            }
        }

        ColumnLayout {
            id: contentCol
            width: parent.width * 0.8
            anchors.horizontalCenter: parent.horizontalCenter
            Layout.maximumWidth: 800
            spacing: 20

            // 顶部占位
            Item { Layout.preferredHeight: 40 }

            // --- 状态大标题 ---
            ColumnLayout {
                Layout.alignment: Qt.AlignCenter
                spacing: 5

                FluIcon {
                    Layout.alignment: Qt.AlignCenter
                    iconSource: root.status === 1 ? FluentIcons.Completed : FluentIcons.Clock
                    iconSize: 40
                    color: root.status === 1 ? "#4CAF50" : "#FF9500"
                }

                Text {
                    Layout.alignment: Qt.AlignCenter
                    text: root.status === 1 ? "订单已完成" : "等待支付"
                    font.pixelSize: 24
                    font.bold: true
                    color: FluTheme.fontPrimaryColor
                }
            }

            // --- 核心信息卡片 (复用 BookingPage 风格) ---
            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 20; Layout.rightMargin: 20
                Layout.preferredHeight: innerCol.implicitHeight + 40 // 高度自适应
                color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
                radius: 8

                FluShadow { radius: 8; elevation: 2; color: "#11000000" }

                ColumnLayout {
                    id: innerCol
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // 第一行：[单程] 珠海 - 北京
                        RowLayout {
                            spacing: 8
                            // 蓝色标签
                            Rectangle {
                                width: 36; height: 20
                                color: "#0086F6"
                                radius: 2
                                Text {
                                    anchors.centerIn: parent
                                    text: "单程"
                                    color: "white"; font.pixelSize: 11
                                }
                            }
                            // 城市标题
                            Text {
                                text: getCityName(root.depCity) + " - " + getCityName(root.arrCity)
                                font.pixelSize: 18; font.bold: true
                                color: FluTheme.fontPrimaryColor
                            }
                            Item { Layout.fillWidth: true } // 占位，把后面挤过去
                        }
                    }

                    // 分割线
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f0f0f0" }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            // Layout.alignment: Qt.AlignCenter
                            text: "订单号:  " + root.orderId
                            font.pixelSize: 12
                            color: "#666"
                        }

                        Text {
                            text: "出发地点： " + getCityName(root.depCity)+"机场"
                            color: "#666"; font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "到达地点： " + getCityName(root.arrCity)+"机场"
                            color: "#666"; font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "航班号： " + root.flightNumber
                            color: "#666"; font.pixelSize: 12
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "预计出发时间:  " + root.depTime
                            color: "#666"; font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "预计到达时间:  " + getDate(depTime) + " " + root.arrTime
                            color: "#666"; font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                    }

                    // 分割线
                    Rectangle { Layout.fillWidth: true; height: 1; color: "#f0f0f0" }

                    RowLayout {
                        Layout.fillWidth: true

                        // 乘机人UID (左侧)
                        FluIcon { iconSource: FluentIcons.Contact; iconSize: 16; color: "#999" }
                        Text {
                            text: "乘机人UID: " + appWindow.currentUid;
                            color: "#999"; font.pixelSize: 12
                        }

                        Item { Layout.fillWidth: true }

                        // 价格 (右侧)
                        Text { text: "总额"; color: "#666"; font.pixelSize: 12; Layout.alignment: Qt.AlignBaseline }
                        Text {
                            text: "¥" + root.price
                            color: "#FF4D4F"; font.pixelSize: 20; font.bold: true; Layout.alignment: Qt.AlignBaseline
                        }
                    }
                }
            }

            // --- 底部操作区 (可选) ---
            // 如果是已完成的订单，这里可以放 "打印行程单" 或 "退改签" 按钮
            // 如果不需要，可以留空
            RowLayout {
                Layout.topMargin: 20
                Layout.alignment: Qt.AlignHCenter
                spacing: 20
                visible: root.status === 1 // 仅已完成显示

                FluButton {
                    text: "打印行程单"
                    onClicked: showInfo("功能开发中...")
                }
                FluButton {
                    text: "联系客服"
                    onClicked: showInfo("请拨打 95588")
                }
            }
        }
    }
}
