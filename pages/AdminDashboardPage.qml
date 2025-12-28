import QtQuick
import QtQuick.Controls
import FluentUI
import QtQuick.Layouts

FluPage {
    id: admin_dashboard
    // 定义信号，用于处理退出登录等操作
    signal clickLogoutButton()

    // 顶部自定义栏
    Rectangle {
        id: admin_header
        height: 45
        color: "#FFFFFF"
        z: 999

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        // 底部灰线
        Rectangle {
            height: 1
            color: "#e0e0e0"
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
        }

        // 顶部栏内容布局
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 15

            // Logo 和 标题
            Image {
                source: "qrc:/qt/qml/FlightClient/figures/logo1.png" // 保持 Logo 一致
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "航班管理系统 - 管理员后台" // 修改标题表明身份
                font.pixelSize: 16
                font.bold: true
                color: "#333333"
            }

            // 右侧占位符，把内容推到右边
            Item { Layout.fillWidth: true }

            // 管理员头像/图标 (可以使用不同的默认头像区分)
            Item{
                width: 32
                height: 32
                Avatar {
                    anchors.centerIn: parent
                    size: 32
                    // 假设有一个管理员默认头像，或者沿用之前的
                    source: "qrc:/qt/qml/FlightClient/figures/123.jpg"
                }
            }

            Text {
                text: "管理员"
                font.bold: true
                font.pixelSize: 15
                color: "black"
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // 侧边导航栏
    FluNavigationView {
        id: nav_view
        cellWidth: 200
        hideNavAppBar: true // 隐藏自带的顶部栏，使用上面自定义的
        cellHeight: 55

        // 锚定在自定义栏下面
        anchors.top: admin_header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        items: FluObject{

            // 功能 1：修改航班
            FluPaneItem {
                title: "修改航班"
                icon: FluentIcons.Edit
                url: "qrc:/qt/qml/FlightClient/pages/ModifyFlight.qml"
                onTap: {
                    nav_view.push(url)
                }
            }

            // 功能 2：添加航班
            FluPaneItem {
                title: "添加航班"
                icon: FluentIcons.Add
                url: "qrc:/qt/qml/FlightClient/pages/AddFlight.qml"
                onTap: {
                    nav_view.push(url)
                }
            }

        }

        // 底部菜单项（退出登录）
        footerItems: FluObject {
            FluPaneItem {
                title: "退出管理"
                icon: FluentIcons.SignOut
                onTap: {
                    // 这里的逻辑与 Dashboard 类似，重置 Loader 到登录页
                    pageLoader.source = "pages/DashboardPage.qml"
                }
            }
        }

        // 页面加载完成后，默认选中第一项（修改航班）
        Component.onCompleted: {
            nav_view.setCurrentIndex(0)
        }
    }
}
