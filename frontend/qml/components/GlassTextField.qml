import QtQuick
import QtQuick.Controls.Basic

// текстовое поле — простое и чистое
TextField {
    id: root

    implicitHeight: 36
    leftPadding: 12
    rightPadding: 12

    color: Qt.rgba(1, 1, 1, 0.88)
    placeholderTextColor: Qt.rgba(1, 1, 1, 0.28)
    selectionColor: Qt.rgba(1, 0.42, 0.21, 0.45)
    selectedTextColor: "white"
    font.pixelSize: 13

    background: Rectangle {
        radius: 9
        color: root.activeFocus ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: root.activeFocus ? Qt.rgba(1, 0.42, 0.21, 0.55) : Qt.rgba(1, 1, 1, 0.12)
        Behavior on border.color { ColorAnimation { duration: 100 } }
    }
}
