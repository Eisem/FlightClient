import QtQuick
import FluentUI
import Qt5Compat.GraphicalEffects
Item {
    id: control
    property int size: 60
    property string source: ""

    width: size
    height: size

    // 圆形剪裁
    layer.enabled: true
    layer.smooth: true
    layer.effect: OpacityMask {
        maskSource: Rectangle {
            width: control.width
            height: control.height
            radius: width / 2
        }
    }

    FluImage {
        id: img
        anchors.fill: parent
        source: control.source
        fillMode: Image.PreserveAspectCrop
    }


}
