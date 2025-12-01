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
    property string userTrueName: ""     // 真实姓名
    property string userIdCard: ""       // 身份证号
    property bool isVerified: false      // 是否已实名认证的状态位

    property string userGender: "男"
    property string userEmail: "cemachu87@gmail.com\nyangkunwei2024@outlook.com"
    property string userPhone: "18122903031"
    property string avatarSource: "qrc:/qt/qml/FlightClient/figures/123.jpg" // 替换为你的默认头像路径

    // --- 新增：用于控制弹窗逻辑的临时变量 ---
    property string currentEditType: ""

 // -------------------------------------------------
     // 0. 辅助工具函数：身份证号脱敏
     // -------------------------------------------------
     function getMaskedIdCard(idStr) {
         if (!idStr || idStr.length < 10) return idStr
         // 保留前3位，后4位，中间用 * 替换
         return idStr.substring(0, 3) + "***********" + idStr.substring(idStr.length - 4)
     }
    // -------------------------------------------------
    // 新增：页面加载完成后，自动拉取数据
    // -------------------------------------------------
    Component.onCompleted: {
        // 检查是否有 UID (假设登录后 appWindow.currentUid 已被赋值)
        if (appWindow.currentUid) {
            fetchUserInfo()
        } else {
            console.log("警告：未找到 UID，无法拉取用户信息")
        }
    }
    // -------------------------------------------------
    // 2. 提交实名认证信息 (专用函数)
    // -------------------------------------------------
    function submitVerify(tName, tId) {
        if (tName === "" || tId === "") {
            showError("姓名和身份证号不能为空")
            return
        }

        // 简单的前端身份证校验(可选)
        if (tId.length !== 18) {
            showError("请输入18位有效的身份证号")
            return
        }

        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/user/verify" // 你的实名认证接口
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var response = JSON.parse(xhr.responseText)
                if(response.status === "success") {
                    showSuccess("认证成功")
                    // 更新本地状态，界面会自动刷新
                    usercenterpage.userTrueName = tName
                    usercenterpage.userIdCard = tId
                    usercenterpage.isVerified = true
                } else {
                    showError(response.message || "认证失败")
                }
            }
        }

        var data = {
            "uid": appWindow.currentUid,
            "truename": tName,
            "id_card": tId
        }
        xhr.send(JSON.stringify(data))
    }

    // -------------------------------------------------
    // 新增：从后端获取用户信息的函数
    // -------------------------------------------------
    function fetchUserInfo() {
        console.log("开始获取用户信息...")

        var xhr = new XMLHttpRequest()
        // =====================================
        // TODO: 修改为你的获取信息接口 (GET 或 POST 均可，这里以 POST 为例)
        // =====================================
        var url = backendBaseUrl + "/api/user/info"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        // =====================================
                        // TODO: 这里必须根据后端实际返回的 JSON 字段进行对接
                        // 假设后端返回结构:
                        // {
                        //   "status": "success",
                        //   "data": {
                        //      "nickname": "Cema",
                        //      "truename": "YZL",
                        //      "gender": "男",
                        //      "email": "...",
                        //      "telephone": "...",
                        //      "avatar": "..."
                        //   }
                        // }
                        // =====================================
                        if (response.status === "success" && response.data) {
                            var d = response.data

                            // 更新界面绑定的属性
                            // 加上 || "" 是为了防止后端返回 null 导致界面显示 "undefined"
                            if(d.nickname) usercenterpage.userName = d.nickname
                            if(d.truename) usercenterpage.userTrueName = d.truename
                            if(d.gender)   usercenterpage.userGender = d.gender
                            if(d.email)    usercenterpage.userEmail = d.email
                            if(d.phone)    usercenterpage.userPhone = d.phone

                            // 如果后端有返回头像链接，也可以更新头像
                            // if(d.avatar) usercenterpage.avatarSource = d.avatar

                            console.log("用户信息加载成功")
                        } else {
                            console.log("获取信息失败: " + (response.message || "未知错误"))
                        }
                    } catch (e) {
                        console.log("JSON解析失败:", e)
                    }
                } else {
                    console.log("网络请求失败: " + xhr.status)
                }
            }
        }

        // 发送 UID 给后端查询
        var data = {
            "uid": appWindow.currentUid
        }
        xhr.send(JSON.stringify(data))
    }
    // -------------------------------------------------
    // 核心逻辑：发送更新请求到后端
    // -------------------------------------------------
    function updateUserInfo(fieldType, newValue) {
        console.log("准备更新字段: " + fieldType + " 为: " + newValue)

        // 1. 基础校验
        if(newValue === "") {
            showError("输入内容不能为空")
            return
        }

        // 2. 创建 XHR 对象
        var xhr = new XMLHttpRequest()
        // =====================================
        // TODO: 请根据你的后端实际路由修改此处
        // =====================================
        var url = backendBaseUrl + "/api/user/update"
        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        // 3. 监听状态变化
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)

                        // =====================================
                        // TODO: 根据后端返回结构修改判断逻辑
                        // =====================================
                        if(response.status === "success") {
                            // --- 后端更新成功，现在更新前端界面显示 ---
                            if (fieldType === "nickname") usercenterpage.userName = newValue
                            else if (fieldType === "telephone") usercenterpage.userPhone = newValue
                            else if (fieldType === "email") usercenterpage.userEmail = newValue

                            showSuccess("修改成功")
                        } else {
                            showError(response.message || "修改失败")
                        }
                    } catch(e) {
                        console.log("JSON解析失败:", e)
                        showError("服务器数据异常")
                    }
                } else {
                    showError("网络请求失败: " + xhr.status)
                }
            }
        }

        // 4. 发送 JSON 数据
        // 这里假设后端需要: uid(谁改的), field(改哪个字段), value(新值)
        var data = {
            "uid": appWindow.currentUid, // 务必确保登录时已保存了 currentUid
            "field": fieldType,          // 例如 "name", "phone"
            "value": newValue
        }
        xhr.send(JSON.stringify(data))
    }

    // 防止超出屏幕的部分挡住其他窗口
    clip: false
    FluContentDialog {
        id: editDialog
        title: "修改信息"
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        negativeText: "取消"
        positiveText: "保存"

        // 【关键点1】新增一个临时属性，用来暂存输入框的内容
        property string tempInputText: ""

        // 【关键点2】必须使用 Component 包裹，并给内部 Item 设置明确的高度
        contentDelegate: Component {
            Item {
                // 宽度跟随父容器（弹窗内容区），高度给一个定值，不然会看不见
                implicitWidth: parent.width
                implicitHeight: 30

                FluTextBox {
                    id: textBox
                    anchors.left:parent.left
                    anchors.right:parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height:30
                    anchors.centerIn: parent
                    placeholderText: "请输入..."

                    // 【关键点3】将输入框的 text 绑定到 dialog 的临时属性上
                    // 当弹窗打开时，它会显示 tempInputText 的值
                    // 当用户输入时，它会更新 tempInputText
                    text: editDialog.tempInputText
                    onTextChanged: editDialog.tempInputText = text

                    // 组件加载完成后自动聚焦
                    Component.onCompleted: {
                        forceActiveFocus()
                    }
                }
            }
        }

        // 点击“保存”按钮后的逻辑
        onPositiveClicked: {
            // 直接读取绑定的临时变量，非常稳定
            var val = editDialog.tempInputText
            updateUserInfo(usercenterpage.currentEditType, val)
        }
    }

    // (B) 新增：实名认证专用弹窗 (包含两个输入框)
    FluContentDialog {
        id: verifyDialog
        title: "实名认证"
        message: "请填写真实的身份信息，认证后不可修改"
        buttonFlags: FluContentDialogType.NegativeButton | FluContentDialogType.PositiveButton
        negativeText: "取消"
        positiveText: "提交认证"

        property string inputName: ""
        property string inputId: ""

        contentDelegate: Component {
            ColumnLayout {
                implicitWidth: parent.width
                spacing: 15

                FluTextBox {
                    id: nameBox
                    anchors.left:parent.left
                    anchors.right:parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height:30
                    Layout.fillWidth: true
                    placeholderText: "请输入真实姓名"
                    onTextChanged: verifyDialog.inputName = text
                }
                FluTextBox {
                    id: idBox
                    anchors.left:parent.left
                    anchors.right:parent.right
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height:30
                    Layout.fillWidth: true
                    placeholderText: "请输入身份证号"
                    onTextChanged: verifyDialog.inputId = text
                }
            }
        }

        onPositiveClicked: {
            submitVerify(verifyDialog.inputName, verifyDialog.inputId)
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
            BurstAvatar {
                id: avatar1

                // 1. 设置大小 (对应原本的 size: 110)
                avatarSize: 110

                // 2. 传入图片路径 (实现可修改、可复用)
                // 这里绑定的是你 UserCenterPage.qml 顶部的 property string avatarSource
                source: usercenterpage.avatarSource

                // 3. 布局属性
                anchors.horizontalCenter: parent.horizontalCenter

                // (可选) 如果想调整小球弹出的距离，可以修改这里
                // burstDistance: 100
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

                    // 昵称
                    InfoRow {
                        icon: FluentIcons.Contact
                        title: "昵称"
                        value: usercenterpage.userName
                        showBottomLine: true
                        onClicked: {
                            usercenterpage.currentEditType = "nickname"
                            editDialog.title = "修改昵称"
                            editDialog.open()
                        }
                    }

                    InfoRow {
                        icon: FluentIcons.IDBadge
                        title: "姓名"
                        value: usercenterpage.userTrueName
                        showBottomLine: true
                        onClicked: {
                            showInfo("姓名通常在实名认证后不可修改")
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
                            usercenterpage.currentEditType = "telephone"
                            editDialog.title = "修改手机号"
                            editDialog.open()
                        }
                    }
                }

            }

            FluText {
                text: "实名认证"
                font: FluTextStyle.Subtitle
                Layout.fillWidth: true
                Layout.topMargin: 10
            }

            Rectangle {
                Layout.fillWidth: true
                // 高度根据内容自动适应
                height: realNameCol.height + 20
                radius: 8
                color: FluTheme.dark ? Qt.rgba(255,255,255,0.05) : "white"
                border.color: FluTheme.dividerColor
                border.width: 1

                ColumnLayout {
                    id: realNameCol
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 0

                    // === 情况A：已认证 ===
                    // 使用 visible 属性来控制显示，而不是用 Loader，这样写起来更简单
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: usercenterpage.isVerified // 只有已认证时才显示
                        spacing: 0

                        InfoRow {
                            icon: FluentIcons.IDBadge
                            title: "真实姓名"
                            value: usercenterpage.userTrueName
                            showBottomLine: true
                            // 已认证通常不可修改，所以这里不加 onClicked 或者弹提示
                            onClicked: showInfo("已完成实名认证，不可修改")
                        }

                        InfoRow {
                            icon: FluentIcons.Certificate
                            title: "身份证号"
                            // 调用脱敏函数
                            value: getMaskedIdCard(usercenterpage.userIdCard)
                            showBottomLine: false
                            onClicked: showInfo("已完成实名认证，不可修改")
                        }
                    }

                    // === 情况B：未认证 ===
                    InfoRow {
                        visible: !usercenterpage.isVerified // 只有未认证时才显示
                        icon: FluentIcons.Shield
                        title: "实名验证"
                        value: "前往认证" // 引导文字
                        showBottomLine: false

                        // 点击弹出认证框
                        onClicked: {
                            verifyDialog.inputName = ""
                            verifyDialog.inputId = ""
                            verifyDialog.open()
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
