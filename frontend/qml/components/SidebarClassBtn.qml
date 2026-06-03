import QtQuick
import QtQuick.Controls.Basic

// кнопка класса в сайдбаре — аватарка с двумя буквами
AbstractButton {
    id: root

    property string classLabel: "SC"   // две буквы
    property string classColor: "#FF6B35"
    property bool isActive: false

    implicitWidth: 44
    implicitHeight: 44

    background: Rectangle {
        radius: 12
        color: root.isActive
            ? Qt.rgba(1, 0.42, 0.21, 0.20)
            : root.hovered ? Qt.rgba(1,1,1,0.08) : "transparent"
        border.width: root.isActive ? 1 : 0
        border.color: Qt.rgba(1, 0.42, 0.21, 0.50)
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    contentItem: Rectangle {
        width: 32
        height: 32
        radius: 9
        anchors.centerIn: parent
        // берём цвет класса и делаем его тёмным фоном
        color: Qt.rgba(0.15, 0.15, 0.18, 0.85)
        border.width: 1
        border.color: Qt.color(root.classColor).a > 0
            ? Qt.rgba(
                Qt.color(root.classColor).r * 0.7,
                Qt.color(root.classColor).g * 0.7,
                Qt.color(root.classColor).b * 0.7,
                0.50)
            : Qt.rgba(1,1,1,0.15)

        Text {
            anchors.centerIn: parent
            text: root.classLabel
            color: root.classColor
            font.pixelSize: 11
            font.weight: 700
        }
    }

    ToolTip {
        visible: root.hovered
        delay: 600
        text: root.text

        background: Rectangle {
            radius: 6
            color: Qt.rgba(0.10, 0.10, 0.13, 0.95)
            border.width: 1
            border.color: Qt.rgba(1,1,1,0.12)
        }
        contentItem: Text {
            // тут parent это ToolTip, у него есть .text
            text: root.text
            color: Qt.rgba(1,1,1,0.85)
            font.pixelSize: 12
        }
    }

    scale: pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
}
