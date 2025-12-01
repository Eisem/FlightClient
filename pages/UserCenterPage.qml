import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI
import FlightClient
import QtQuick.Layouts
import QtQuick.Effects
import FluentUI.Controls
import Qt5Compat.GraphicalEffects

FluPage {
    id: usercenterpage

    signal loginSuccessSignal()
    signal clickRegisterButton()
    signal loginBackClicked()
    signal changeAvatarClicked() // 新增：点击修改头像信号

    // 用于显示错误信息的变量
    property string errorMessage: ""

    // 模拟的用户数据（实际开发中应绑定到C++模型或全局单例）
    property string userName: "Cema Chu"
    property string userBirthday: "1996年5月21日"
    property string userGender: "男"
    property string userEmail: "cemachu87@gmail.com\nyangkunwei2024@outlook.com"
    property string userPhone: "181 2290 3031"
    property string avatarSource: "qrc:/qt/qml/FlightClient/figures/123.jpg" // 替换为你的默认头像路径

    // --- 新增：用于控制弹窗逻辑的临时变量 ---
    property string currentEditType: ""

    // 防止超出屏幕的部分挡住其他窗口
    clip: false
    FluContentDialog {
            id: editDialog
            title: "修改信息"
            message: "请输入新的内容"
            buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
            negativeText: "取消"
            positiveText: "保存"

            // 弹窗里的内容区域
            contentDelegate: Item {
                implicitWidth: parent.width
                implicitHeight: 60
                FluTextBox {
                    id: inputField
                    anchors.centerIn: parent
                    width: parent.width
                    placeholderText: "请输入..."
                    // 当弹窗打开时，自动填入旧数据
                    Component.onCompleted: {
                        inputField.text = getInitialText()
                        inputField.forceActiveFocus()
                    }
                }

                // 辅助函数：根据 currentEditType 获取当前值
                function getInitialText() {
                    if (currentEditType === "name") return usercenterpage.userName
                    if (currentEditType === "phone") return usercenterpage.userPhone
                    if (currentEditType === "email") return usercenterpage.userEmail
                    return ""
                }
            }

            // 点击“保存”按钮后的逻辑
            onPositiveClicked: {
                // 获取输入框的内容 (这里通过查找子对象的方式，或者你可以把 Input 定义在外面绑定)
                // 为了简单演示，假设我们能获取到 inputField 的 text，或者绑定一个 property
                // 在实际项目中，建议在 contentDelegate 外部定义一个 property string tempInput 来双向绑定

                // 这里仅做演示逻辑分支：
                var newVal = "新输入的值" // 实际开发需绑定 Text 输入

                if (currentEditType === "name") {
                    console.log("正在保存名字...")
                    // usercenterpage.userName = newVal
                } else if (currentEditType === "phone") {
                    console.log("正在保存电话...")
                }

                showSuccess("保存成功 (模拟)")
            }
        }

        // -------------------------------------------------
        // 新增：针对日期的特殊弹窗 (示例)
        // -------------------------------------------------
        FluContentDialog {
            id: dateDialog
            title: "选择生日"
            message: "请选择您的出生日期"
            negativeText: "取消"
            positiveText: "确定"
            contentDelegate: FluCalendarPicker {
                // 这里放置日历组件
            }
            onPositiveClicked: {
                console.log("生日已修改")
            }
        }

    // 返回按钮 (保留你原有的代码)
    FluIconButton {
        iconSource: FluentIcons.ChromeBack
        iconSize: 15
        text: "返回主页"
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.leftMargin: 8
        z: 10 // 确保按钮在最上层

        onClicked: {
            usercenterpage.loginBackClicked()
        }
    }

    // 主滚动区域
    Flickable {
        id: scroller
        anchors.fill: parent
        anchors.topMargin: 50 // 给返回按钮留出空间
        contentHeight: contentCol.height + 40
        contentWidth: parent.width

        ColumnLayout {
            id: contentCol
            width: Math.min(parent.width - 40, 600) // 限制最大宽度，保持美观
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            // -------------------------------------------------
            // 1. 顶部头像区域
            // -------------------------------------------------
            Avatar {
                id: avatar1
                size: 110
                source: usercenterpage.avatarSource
                anchors.horizontalCenter: parent.horizontalCenter
            }
            RoundButton{
                id:rbutton
                radius: width/2
                anchors.right: avatar1.right
                anchors.bottom: avatar1.bottom
                background: FluIcon{
                    iconSource: FluentIcons.Edit
                    color: rgba(1,1,1)

                }
                onClicked: {
                    console.log("tap tap")
                }
            }




            // -------------------------------------------------
            // 2. 基本信息卡片
            // -------------------------------------------------
            FluText {
                text: "基本信息"
                font: FluTextStyle.Subtitle
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: basicInfoCol.height + 20
                radius: 8
                color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "white"
                border.color: FluTheme.dividerColor
                border.width: 1

                ColumnLayout {
                    id: basicInfoCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 0

                    // 姓名
                    InfoRow {
                        icon: FluentIcons.Contact
                        title: "姓名"
                        value: usercenterpage.userName
                        showBottomLine: true
                        onClicked: {
                            usercenterpage.currentEditType = "name"
                            editDialog.title = "修改姓名"
                            editDialog.open()
                        }

                    }

                    // 生日
                    InfoRow {
                        icon: FluentIcons.Calendar
                        title: "生日"
                        value: usercenterpage.userBirthday
                        showBottomLine: true
                        onClicked: {
                            dateDialog.open()
                        }
                    }

                    // 性别
                    InfoRow {
                        icon: FluentIcons.People
                        title: "性别"
                        value: usercenterpage.userGender
                        showBottomLine: false
                        onClicked: {
                            showInfo("性别通常在实名认证后不可修改")
                        }
                    }
                }
            }

            // -------------------------------------------------
            // 3. 联系信息卡片
            // -------------------------------------------------
            FluText {
                text: "联系信息"
                font: FluTextStyle.Subtitle
                Layout.fillWidth: true
                Layout.topMargin: 10
            }

            Rectangle {
                Layout.fillWidth: true
                height: contactInfoCol.height + 20
                radius: 8
                color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "white"
                border.color: FluTheme.dividerColor
                border.width: 1

                ColumnLayout {
                    id: contactInfoCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 0

                    // 电子邮件
                    InfoRow {
                        icon: FluentIcons.Mail
                        title: "电子邮件"
                        value: usercenterpage.userEmail
                        showBottomLine: true
                        onClicked: {
                            usercenterpage.currentEditType = "email"
                            editDialog.title = "绑定新邮箱"
                            editDialog.open()
                        }
                    }

                    // 电话
                    InfoRow {
                        icon: FluentIcons.Phone
                        title: "电话"
                        value: usercenterpage.userPhone
                        showBottomLine: false
                        onClicked: {
                            usercenterpage.currentEditType = "phone"
                            editDialog.title = "修改手机号"
                            editDialog.open()
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------
    // 内部组件：信息行 (InfoRow)
    // -------------------------------------------------
    component InfoRow : Item {
        id:currentrow
        property int icon
        property string title
        property string value
        property bool showBottomLine: true

        Layout.fillWidth: true
        height: Math.max(60, contentRow.height + 20)

        signal clicked()

        RowLayout {
            id: contentRow
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 20

            // 左侧图标
            FluIcon {
                iconSource: icon
                iconSize: 20
                iconColor: FluTheme.fontSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }

            // 中间文本内容
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                FluText {
                    text: title
                    font: FluTextStyle.Caption
                    color: FluTheme.fontSecondaryColor
                }

                FluText {
                    text: value
                    font: FluTextStyle.Body
                    wrapMode: Text.Wrap
                    Layout.fillWidth: true
                }
            }

            // 右侧箭头（可选，暗示可点击编辑）
            FluIcon {
                iconSource: FluentIcons.ChevronRight
                iconSize: 12
                iconColor: FluTheme.dividerColor
                visible: true
            }
        }

        // 底部每个项目的分割线
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 50 // 图标之后开始画线
            height: 1
            color: FluTheme.dividerColor
            visible: showBottomLine
        }

        // 点击交互区域
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                // 这里可以添加点击某一行的逻辑，比如弹出修改框
                console.log("Clicked row: " + title)
                currentrow.clicked()
            }
            // 简单的按压效果
            onPressed: parent.opacity = 0.7
            onReleased: parent.opacity = 1.0
        }
    }
}
