import QtQuick
import QtQuick.Shapes
import FluentUI

Item {
    id: root

    // ==========================================
    // 参数配置
    // ==========================================
    property url source: "qrc:/qt/qml/content/image_5b9956.png"
    property int avatarSize: 100

    // 距离配置
    property int distInner: 110
    property int distOuter: 220

    property int vOffset: 12
    property int ringWidth: 10
    property int gap: 6
    property int ballSize: 24

    // 布局尺寸：紧贴圆环
    width: avatarSize + (gap * 2) + (ringWidth * 2)
    height: width

    // 允许溢出
    clip: false

    readonly property color c_red: "#EA4335"
    readonly property color c_blue: "#4285F4"
    readonly property color c_green: "#34A853"
    readonly property color c_yellow: "#FBBC05"

    readonly property real centerXY: root.width / 2
    readonly property real ringRadius: (root.avatarSize / 2) + root.gap + (root.ballSize / 2)

    // ==========================================
    // 1. 头像
    // ==========================================
    Avatar {
        id: mainAvatar
        source: root.source
        size: root.avatarSize
        anchors.centerIn: parent
        z: 10
    }

    // ==========================================
    // 2. 动画容器 (Wrapper)
    // ==========================================
    Item {
        id: animWrapper
        anchors.fill: parent
        transformOrigin: Item.Center
        z: 5

        // --- 小球层 ---
        Item {
            id: pivotContainer
            anchors.fill: parent

            component Dot : Rectangle {
                width: root.ballSize
                height: root.ballSize
                radius: width / 2
                x: root.centerXY - width/2
                y: root.centerXY - height/2
                scale: 0.5
                antialiasing: true
            }

            Dot { id: ballRed;    color: c_red }
            Dot { id: ballBlue;   color: c_blue }
            Dot { id: ballGreen;  color: c_green }
            Dot { id: ballYellow; color: c_yellow }
        }

        // --- 色环层 ---
        Item {
            id: finalRing
            anchors.fill: parent
            opacity: 0 // 初始隐藏

            Shape {
                id: ringShape
                anchors.fill: parent

                // [优化 1] 关闭 layer 渲染。
                // 之前的 layer.samples: 8 会导致每一帧都重绘高清纹理，造成严重的性能卡顿。
                // 现代 QtQuick Shape 自带抗锯齿，通常不需要开启 layer。
                layer.enabled: true
                layer.samples: 8
                layer.smooth: true
                antialiasing: true

                readonly property real r: (root.avatarSize / 2) + root.gap + (root.ringWidth / 2)

                ShapePath {
                    strokeColor: c_blue; strokeWidth: root.ringWidth; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                    PathAngleArc { centerX: root.centerXY; centerY: root.centerXY; radiusX: ringShape.r; radiusY: ringShape.r; startAngle: 270; sweepAngle: 90 }
                }
                ShapePath {
                    strokeColor: c_red; strokeWidth: root.ringWidth; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                    PathAngleArc { centerX: root.centerXY; centerY: root.centerXY; radiusX: ringShape.r; radiusY: ringShape.r; startAngle: 180; sweepAngle: 90 }
                }
                ShapePath {
                    strokeColor: c_yellow; strokeWidth: root.ringWidth; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                    PathAngleArc { centerX: root.centerXY; centerY: root.centerXY; radiusX: ringShape.r; radiusY: ringShape.r; startAngle: 90; sweepAngle: 90 }
                }
                ShapePath {
                    strokeColor: c_green; strokeWidth: root.ringWidth; fillColor: "transparent"; capStyle: ShapePath.FlatCap
                    PathAngleArc { centerX: root.centerXY; centerY: root.centerXY; radiusX: ringShape.r; radiusY: ringShape.r; startAngle: 0; sweepAngle: 90 }
                }
            }
        }
    }

    // ==========================================
    // 3. 动画序列
    // ==========================================
    SequentialAnimation {
        id: mainAnim
        running: false

        // 0. 起步前稍微等一下 (Pre-delay)
        PauseAnimation { duration: 400 }

        // --- 阶段 1: 炸开 (Burst) ---
        ParallelAnimation {
            // 左侧
            NumberAnimation { target: ballYellow; property: "x"; to: (root.centerXY - root.ballSize/2) - root.distOuter; duration: 750; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
            NumberAnimation { target: ballRed;    property: "x"; to: (root.centerXY - root.ballSize/2) - root.distInner; duration: 750; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
            // 右侧
            NumberAnimation { target: ballBlue;   property: "x"; to: (root.centerXY - root.ballSize/2) + root.distInner; duration: 750; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
            NumberAnimation { target: ballGreen;  property: "x"; to: (root.centerXY - root.ballSize/2) + root.distOuter; duration: 750; easing.type: Easing.OutBack; easing.overshoot: 1.6 }

            // 微动
            NumberAnimation { targets: [ballRed, ballBlue];           property: "y"; to: (root.centerXY - root.ballSize/2) - root.vOffset; duration: 750; easing.type: Easing.OutQuad }
            NumberAnimation { targets: [ballYellow, ballGreen];       property: "y"; to: (root.centerXY - root.ballSize/2) + root.vOffset; duration: 750; easing.type: Easing.OutQuad }

            // 放大
            NumberAnimation { targets: [ballRed, ballBlue, ballYellow, ballGreen]; property: "scale"; to: 1.6; duration: 650; easing.type: Easing.OutBack }
        }

        // 保持停顿
        PauseAnimation { duration: 120 }

        // --- 阶段 2: 聚拢 (Converge) ---
        ParallelAnimation {
            NumberAnimation { targets: [ballRed, ballBlue, ballYellow, ballGreen]; property: "scale"; to: 1.0; duration: 450; easing.type: Easing.InOutQuart }

            NumberAnimation { target: ballRed;    property: "x"; to: (root.centerXY - root.ballSize/2) - root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }
            NumberAnimation { target: ballRed;    property: "y"; to: (root.centerXY - root.ballSize/2) - root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }

            NumberAnimation { target: ballYellow; property: "x"; to: (root.centerXY - root.ballSize/2) - root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }
            NumberAnimation { target: ballYellow; property: "y"; to: (root.centerXY - root.ballSize/2) + root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }

            NumberAnimation { target: ballBlue;   property: "x"; to: (root.centerXY - root.ballSize/2) + root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }
            NumberAnimation { target: ballBlue;   property: "y"; to: (root.centerXY - root.ballSize/2) - root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }

            NumberAnimation { target: ballGreen;  property: "x"; to: (root.centerXY - root.ballSize/2) + root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }
            NumberAnimation { target: ballGreen;  property: "y"; to: (root.centerXY - root.ballSize/2) + root.ringRadius * 0.707; duration: 450; easing.type: Easing.InOutQuart }
        }

        // --- 阶段 3: 整体旋转与融合 ---
        ParallelAnimation {
            // 透明度切换
            SequentialAnimation {
                NumberAnimation { target: pivotContainer; property: "opacity"; to: 0; duration: 100 }
            }
            SequentialAnimation {
                NumberAnimation { target: finalRing; property: "opacity"; to: 1; duration: 100 }
            }

            // 旋转 Wrapper
            SequentialAnimation {
                NumberAnimation {
                    target: animWrapper
                    property: "rotation"
                    to: 45
                    duration: 250
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: animWrapper
                    property: "rotation"
                    to: 0
                    duration: 600

                    // [优化 2] 解决了“重影/模糊”感
                    // 之前的 OutElastic 会导致剧烈的来回抖动（高频），人眼看起来像重影。
                    // 改为 OutBack 只有一次优雅的回弹，清晰有力。
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
            }
        }
    }

    Component.onCompleted: {
        mainAnim.start()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            pivotContainer.opacity = 1
            finalRing.opacity = 0
            animWrapper.rotation = 0
            mainAnim.restart()
        }
    }
}
