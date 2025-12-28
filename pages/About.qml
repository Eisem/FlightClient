import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI

FluScrollablePage {
    id: aboutPage

    ColumnLayout {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width > 600 ? 600 : parent.width - 40 // 限制最大宽度，在大屏上更好看
        spacing: 20

        // ============================
        // 1. 顶部 Logo 区
        // ============================
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            Layout.topMargin: 20

            Image {
                source: "qrc:/qt/qml/FlightClient/figures/logo1.png" // 确保路径对
                Layout.preferredWidth: 100
                Layout.preferredHeight: 100
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignHCenter

                // 加个简单的阴影让 Logo 立体一点
                FluShadow { radius: 0; elevation: 5 }
            }

            FluText {
                text: "long哥航班管理"
                font.pixelSize: 28
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            FluText {
                text: "版本 v1.0.0 (实训构建版)"
                color: "gray"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }

            FluText {
                text: "一个现代化、高性能的航班管理系统客户端"
                color: FluTheme.dark ? "#DDD" : "#555"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 5
            }
        }

        // ============================
        // 2. 团队成员卡片
        // ============================
        FluFrame {
            Layout.fillWidth: true
            padding: 20
            radius: 8

            ColumnLayout {
                spacing: 15
                width: parent.width

                FluText { text: "开发团队"; font.pixelSize: 18; font.bold: true }
                FluDivider { Layout.fillWidth: true }

                // 成员列表
                GridLayout {
                    columns: 2
                    rowSpacing: 30
                    columnSpacing: 30
                    Layout.fillWidth: true

                    // 只需要在这里改名字即可
                    MemberItem {
                            name: "shop1111"; role: "后端架构/数据库设计"
                            avatar_source: "qrc:/qt/qml/FlightClient/figures/ava3.jpg"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }

                        MemberItem {
                            name: "Eisem"; role: "前端开发/UI设计"
                            avatar_source: "qrc:/qt/qml/FlightClient/figures/ava4.jpg"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }

                        MemberItem {
                            name: "001-Elsa"; role: "后端架构/数据库设计"
                            avatar_source: "qrc:/qt/qml/FlightClient/figures/ava1.png"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }

                        MemberItem {
                            name: "zlhahaha"; role: "前端开发/UI设计"
                            avatar_source: "qrc:/qt/qml/FlightClient/figures/ava2.png"
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }
                }
            }
        }

        // ============================
        // 3. 技术栈卡片
        // ============================
        FluFrame {
            Layout.fillWidth: true
            padding: 20
            radius: 8

            ColumnLayout {
                spacing: 15
                width: parent.width

                FluText { text: "技术栈与致谢"; font.pixelSize: 18; font.bold: true }
                FluDivider { Layout.fillWidth: true }

                FluText {
                    text: "本项目基于以下开源技术构建："
                    color: "gray"
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    // 技术标签
                    TechBadge { text: "Qt 6.5" }
                    TechBadge { text: "C++ 17" }
                    TechBadge { text: "QML" }
                    TechBadge { text: "MySQL" }
                    TechBadge { text: "FluentUI"; color: "#0078D4"; textColor: "white" } // 高亮 FluentUI
                }

                FluText {
                    text: "特别感谢软件工程课程导师的指导。"
                    font.pixelSize: 12
                    color: "gray"
                    Layout.topMargin: 10
                }
            }
        }

        // ============================
        // 4. 底部版权
        // ============================
        Item { Layout.preferredHeight: 20 } // 占位

        FluText {
            text: "© 2025 FlightClient Team. All rights reserved."
            color: "gray"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 20
        }
    }

    // === 内部自定义小组件 (减少重复代码) ===

    component MemberItem : RowLayout {
        property string name
        property string role
        property string avatar_source
        spacing: 10

        Avatar {
            size: 50
            source: avatar_source
        }
        Column {
            FluText { text: name; font.bold: true; font.pixelSize: 18}
            FluText { text: role; color: "gray"; font.pixelSize: 12 }
        }
        Item { Layout.fillWidth: true }
    }

    component TechBadge : Rectangle {
        property string text
        property color textColor: FluTheme.fontPrimaryColor
        width: label.implicitWidth + 20
        height: 26
        radius: 4
        color: FluTheme.dark ? Qt.rgba(1,1,1,0.1) : "#F0F0F0"

        Text {
            id: label
            text: parent.text
            anchors.centerIn: parent
            color: parent.textColor
            font.pixelSize: 12
        }
    }
}
