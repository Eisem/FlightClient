import QtQuick
import QtQuick.Controls
import FluentUI
import QtQuick.Layouts

FluPage {
    id: dashboard
    // FluPage 默认填满父容器
    signal clickLoginButton()
    signal clickUserCenterButton()
    // 顶部栏
    Rectangle {
        id: custom_header  // 必须要有 ID，下面要用
        height: 45         // 固定高度
        color: "#FFFFFF"   // 白色背景
        z: 999

        // 锚定在窗口最顶部
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

            // --- 把头像和标题搬到这里来 ---
            Image {
                // 你的头像路径
                source: "qrc:/qt/qml/FlightClient/figures/logo.png"
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "🐉哥航班查询"
                font.pixelSize: 16
                font.bold: true
                color: "#333333"
            }

            // 右侧占位或按钮
            Item { Layout.fillWidth: true }

            Item{
                width: 32
                height:32
                Avatar {
                    anchors.centerIn: parent // 居中显示
                    size: 32                 // 设置大小
                    source: "qrc:/qt/qml/FlightClient/figures/123.jpg" // 设置图片源
                }

                FluButton{
                    anchors.fill: parent
                    opacity: 0
                    z:10
                    onClicked: {
                        dashboard.clickUserCenterButton()
                    }
                }
            }

            FluTextButton {
                text: "个人中心"
                textColor: "black"
                font.bold: true
                font.pixelSize: 15
                onClicked: {
                    dashboard.clickUserCenterButton()
                }
            }
        }
    }

    // 使用 NavigationView 实现侧边菜单
    FluNavigationView {
        id: nav_view
        cellWidth: 200
        hideNavAppBar: true // 隐藏顶部栏

        cellHeight: 55

        // 顶部 Logo 或标题区
        logo: "qrc:/qt/qml/FlightClient/figures/logo.png"
        title: "航班管理系统"

        // 锚定在自定义栏下面
        anchors.top: custom_header.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // 定义左侧菜单项
        items: FluObject{
            // 菜单项 1：航班查询
            FluPaneItem {
                title: "航班查询"
                icon: FluentIcons.Airplane // 使用内置图标
                url: "qrc:/qt/qml/FlightClient/pages/FlightSearch.qml"   // 点击后加载同目录下的这个文件
                onTap: {
                    // 可以在这里处理点击逻辑，或者依靠 url 自动跳转
                    nav_view.push(url)
                }
            }

            // 菜单项 2：我的订单
            FluPaneItem {
                title: "我的订单"
                icon: FluentIcons.ShoppingCart
                url: "qrc:/qt/qml/FlightClient/pages/Orders.qml"
                onTap: {
                    nav_view.push(url)
                }
            }


            FluPaneItem {
                title: "智能客服"
                icon: FluentIcons.ChatBubbles
                url: "qrc:/qt/qml/FlightClient/pages/AiChatPage.qml"
                onTap: {
                    nav_view.push(url)
                }
            }


        }

        // 底部菜单项（通常放设置或退出登录）
        footerItems: FluObject {
            FluPaneItem {
                title: "管理员入口"
                icon: FluentIcons.Connect
                onTap:{
                    pageLoader.source = "pages/AdminDashboardPage.qml"
                }
            }

            FluPaneItem {
                title: "关于我们"
                icon: FluentIcons.Connect
                url: "qrc:/qt/qml/FlightClient/pages/About.qml"
                onTap: {
                    nav_view.push(url)
                }
            }

            FluPaneItem {
                title: "退出登录"
                icon: FluentIcons.SignOut
                onTap: {
                    // 调用 Main.qml 里的 logout 函数（如果定义了的话）
                    // 或者直接重置 Loader
                    // 这里假设 Main.qml 有一个 logout() 函数
                    appWindow.currentUid = ""
                    appWindow.userTrueName = ""
                    appWindow.userIdCard = ""
                    pageLoader.source = "pages/LoginPage.qml"
                }
            }
        }

        // 页面加载完成后，默认选中第一项
        Component.onCompleted: {
            nav_view.setCurrentIndex(0)
            // nav_view.push("FlightSearch.qml")
        }
    }
}
