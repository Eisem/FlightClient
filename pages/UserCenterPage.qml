import QtQuick
import QtQuick.Controls
import QtQuick.Window
import FluentUI
import FlightClient
import QtQuick.Layouts
import QtQuick.Effects

FluPage {
    id: usercenterpage

    signal loginSuccessSignal()
    signal clickRegisterButton()
    signal loginBackClicked()

    // 用于显示错误信息的变量
    property string errorMessage: ""


    Image{
        id: bgSource
        source: "qrc:/qt/qml/FlightClient/figures/123.jpg"
        // anchors.fill: parent

        // 处理边缘效应，边缘发亮透明
        anchors.centerIn: parent
        width: parent.width + 100
        height: parent.height + 100

        fillMode: Image.PreserveAspectCrop // 等比裁剪填满屏幕
        visible: false  // // 隐藏原始图，只显示特效后的图
    }

    // 特效层 (模糊 + 遮罩)
    MultiEffect {
        source: bgSource
        anchors.fill: bgSource

        // 开启模糊
        blurEnabled: true
        blurMax: 64      // 模糊的最大范围
        blur: 1.0       // 当前模糊强度 (0.0 - 1.0)，1.0 最模糊

        // 调节饱和度 (可选，稍微降低一点饱和度会让文字更清楚)
        saturation: 0.5
    }

    // 黑色遮罩层
    // 加上一层淡淡的黑色，防止背景太亮导致白色文字看不清
    Rectangle {
        anchors.fill: bgSource
        color: "black"
        opacity: 0 // 调节这里改变背景暗度
    }

    // 防止超出屏幕的部分挡住其他窗口
    clip: true

    FluIconButton{
        iconSource: FluentIcons.ChromeBack
        iconSize: 15
        text:"返回主页" // 鼠标悬停时显示

        // 定位到左上角
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.leftMargin: 8

        onClicked: {
            usercenterpage.loginBackClicked()
        }
    }




}
