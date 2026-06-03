import QtQuick
import QtQuick.Controls.Basic

// кнопка — есть два варианта: обычная и primary (оранжевая)
AbstractButton {
    id: root

    property bool isPrimary: false
    property real radius: 10

    implicitWidth: 120
    implicitHeight: 36

    background: Rectangle {
        radius: root.radius
        color: {
            if (root.isPrimary) {
                if (root.pressed) return Qt.rgba(1, 0.42, 0.21, 0.95)
                if (root.hovered) return Qt.rgba(1, 0.42, 0.21, 0.85)
                return Qt.rgba(1, 0.42, 0.21, 0.75)
            }
            if (root.pressed) return Qt.rgba(1,1,1,0.14)
            if (root.hovered) return Qt.rgba(1,1,1,0.10)
            return Qt.rgba(1,1,1,0.06)
        }
        border.width: 1
        border.color: root.isPrimary
            ? Qt.rgba(1, 0.55, 0.30, 0.60)
            : Qt.rgba(1, 1, 1, root.hovered ? 0.18 : 0.10)

        Behavior on color { ColorAnimation { duration: 90 } }

        // нижняя тень для primary кнопки — смотрится солидно
        Rectangle {
            visible: root.isPrimary && !root.pressed
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
            width: parent.width * 0.7
            height: 8
            radius: 4
            color: Qt.rgba(1, 0.42, 0.21, 0.30)
            layer.enabled: true
            layer.effect: null
            y: 2
        }
    }

    contentItem: Text {
        text: root.text
        color: root.isPrimary ? "white" : Qt.rgba(1, 1, 1, root.enabled ? 0.85 : 0.35)
        font.pixelSize: 13
        font.weight: root.isPrimary ? 600 : 400
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    scale: pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
}
