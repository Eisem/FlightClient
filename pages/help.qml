import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import FluentUI

// --- 【新增】支付方式选择卡片 ---
Rectangle {
    Layout.fillWidth: true
    Layout.leftMargin: 20; Layout.rightMargin: 20
    Layout.preferredHeight: 120
    color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"
    radius: 4
    FluShadow { radius: 4; elevation: 2; color: "#11000000" }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 20; spacing: 10
        Text { text: "支付方式"; font.pixelSize: 16; font.bold: true; color: FluTheme.fontPrimaryColor }

        RowLayout {
            spacing: 20
            // 微信支付模拟
            Rectangle {
                width: 120; height: 50; radius: 4
                border.color: "#09BB07"; border.width: 2
                color: "#F2FBF2"
                RowLayout {
                    anchors.centerIn: parent
                    FluIcon { iconSource: FluentIcons.Chat; iconSize: 20; color: "#09BB07" } // 暂用 Chat 图标代替微信
                    Text { text: "微信支付"; color: "#333" }
                }
                // 选中标记
                FluIcon {
                    iconSource: FluentIcons.CheckMark
                    color: "#09BB07"
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    anchors.margins: 2
                    iconSize: 12
                }
            }

            // 支付宝模拟 (置灰，仅展示)
            Rectangle {
                width: 120; height: 50; radius: 4
                border.color: "#e0e0e0"; border.width: 1
                color: "#f9f9f9"
                RowLayout {
                    anchors.centerIn: parent
                    FluIcon { iconSource: FluentIcons.PaymentCard; iconSize: 20; color: "#1677FF" }
                    Text { text: "支付宝"; color: "#999" }
                }
            }
        }
    }
}
