import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI

Popup {
    id: payPopup

    // === 公开属性，供外部调用时设置 ===
    property string orderId: ""

    property string amount: "0"

    // 定义一个信号，支付成功后触发，通知父页面刷新
    signal paymentSuccess()

    // 弹窗设置
    modal: true
    focus: true

    // ============================================================
    // 【修改点 1】明确设置弹窗的物理尺寸
    // ============================================================
    width: 350
    height: 400

    // ============================================================
    // 【修改点 2】使用数学公式强制居中 (比 anchors 更稳健)
    // ============================================================
    // 1. 挂载到全局覆盖层，确保 parent 是整个窗口
    parent: Overlay.overlay

    // 2. 手动计算居中坐标：(父宽 - 我宽) / 2
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    // 居中显示 (前提是父组件要有尺寸，通常挂载在 Page 中即可)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 背景透明，因为我们用 FluFrame 做圆角背景
    background: Item {}

    // === 核心内容 ===
    FluFrame {
        id: bgFrame
        width: 350
        height: 400
        radius: 10
        color: FluTheme.dark ? Qt.rgba(45/255, 45/255, 45/255, 1) : "#FFFFFF"

        // 增加阴影
        FluShadow { anchors.fill: parent; radius: 10; elevation: 10 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20

            // 1. 标题区
            RowLayout {
                Layout.fillWidth: true
                FluText {
                    text: "收银台"
                    font.pixelSize: 20
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                FluIconButton {
                    iconSource: FluentIcons.Cancel
                    iconSize: 14
                    onClicked: payPopup.close()
                }
            }

            FluDivider { Layout.fillWidth: true }

            // 2. 金额显示
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 5
                FluText {
                    text: "支付金额"
                    color: "gray"
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "¥ " + payPopup.amount
                    color: "#FF4D4F" // 价格红
                    font.pixelSize: 36
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            // 3. 支付方式选择
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 15

                FluText { text: "选择支付方式"; font.bold: true }

                ButtonGroup { id: payGroup }

                RowLayout {
                    spacing: 10
                    FluRadioButton {
                        checked: true
                        text: "微信支付"
                        ButtonGroup.group: payGroup
                    }
                    FluIcon { iconSource: FluentIcons.Chat; color: "#09BB07" } // 模拟微信图标颜色
                }

                RowLayout {
                    spacing: 10
                    FluRadioButton {
                        text: "支付宝"
                        ButtonGroup.group: payGroup
                    }
                    FluIcon { iconSource: FluentIcons.PaymentCard; color: "#1677FF" } // 模拟支付宝蓝
                }
            }

            Item { Layout.fillHeight: true } // 占位，把按钮顶到底部

            // 4. 底部按钮
            FluFilledButton {
                text: "立即支付 ¥" + payPopup.amount
                Layout.fillWidth: true
                height: 45
                font.bold: true
                normalColor: "#FF4D4F" // 红色按钮更显眼
                hoverColor: "#FF7875"

                onClicked: {
                    handlePay()
                }
            }
        }
    }

    // === 支付逻辑 ===
    function handlePay() {
        console.log("开始支付订单:", orderId)

        var xhr = new XMLHttpRequest()
        var url = backendBaseUrl + "/api/pay"

        xhr.open("POST", url, true)
        xhr.setRequestHeader("Content-Type", "application/json")

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText)
                        if (response.status === "success") {
                            showSuccess("支付成功！")
                            payPopup.close()
                            // 触发成功信号，让外部页面去刷新列表
                            payPopup.paymentSuccess()
                        } else {
                            showError(response.message || "支付失败")
                        }
                    } catch (e) {
                        showError("支付响应解析失败")
                    }
                } else {
                    showError("网络错误: " + xhr.status)
                }
            }
        }

        var data = {
            "order_id": orderId,
            "uid": appWindow.currentUid,
            "payment_method": "wechat" // 这里可以根据 payGroup.checkedButton 动态获取
        }
        xhr.send(JSON.stringify(data))
    }

    // 供外部调用的简便函数
    function showPay(oid, price) {
        orderId = oid
        amount = price
        open()
    }
}
