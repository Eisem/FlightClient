import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI

Popup {
    id: payPopup

    // === 公开属性，供外部调用时设置 ===
    property string outId: ""
    property string inId: ""
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
                    FluIcon { iconSource: FluentIcons.Message; color: "#09BB07" } // 模拟微信图标颜色
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
        console.log("开始支付流程, OutId:", outId, "InId:", inId)
        var uid = parseInt(appWindow.currentUid)
        // 1. 金额拆分逻辑
        var totalVal = parseFloat(amount);
        var priceOut = 0.0;
        var priceIn = 0.0;

        // ============================================================
        // 使用非空字符串判断是否存在返程
        // ============================================================
        if (inId !== "") {
            // 往返策略
            priceOut = 1.0;
            priceIn = totalVal - 1.0;
            if (priceIn < 0) { priceOut = totalVal / 2.0; priceIn = totalVal / 2.0; }
        } else {
            // 单程策略
            priceOut = totalVal;
            priceIn = 0.0;
        }

        function payRequest(oid, payAmount, callback) {
            var xhr = new XMLHttpRequest()
            var url = backendBaseUrl + "/api/payment"

            xhr.open("POST", url, true)
            xhr.setRequestHeader("Content-Type", "application/json")

            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE) {
                    if (xhr.status === 200) {
                        try {
                            var response = JSON.parse(xhr.responseText)
                            if (response.status === "success") {
                                callback(true)
                            } else {
                                showError(response.message || ("订单 " + oid + " 支付失败"))
                                callback(false)
                            }
                        } catch (e) {
                            showError("响应解析失败")
                            callback(false)
                        }
                    } else {
                        showError("网络错误: " + xhr.status)
                        callback(false)
                    }
                }
            }

            // ============================================================
            // 构建参数：全部统一为 String 传给后端 (后端 Controller 需要支持或转换)
            // ============================================================
            var data = {
                "user_id": uid,
                "order_id": oid,
                "amount": parseFloat(payAmount) // 金额建议保持数值类型，或者也转字符串 payAmount.toString()，看你后端需求
            }

            xhr.send(JSON.stringify(data))
        }

        // 2. 执行链式支付
        payRequest(outId, priceOut, function(success1) {
            if (!success1) return;
            if (inId !== "") {
                console.log("正在支付返程...")
                payRequest(inId, priceIn, function(success2) {
                    if (success2) handleFinalSuccess()
                })
            } else {
                handleFinalSuccess()
            }
        })
    }

    // 支付全部完成后的收尾逻辑
    function handleFinalSuccess() {
        showSuccess("支付成功！")
        payPopup.close()
        // 触发成功信号，让外部页面刷新列表
        paymentSuccess()
    }

    // 供外部调用的简便函数
    function showPay(oid, iId, price) {
        // 强制转为字符串，确保类型安全
        outId = oid.toString()
        // 如果 iId 没传或者为空，就设为 ""
        inId = (iId === undefined || iId === null) ? "" : iId.toString()
        amount = price.toString()
        open()
    }
}
