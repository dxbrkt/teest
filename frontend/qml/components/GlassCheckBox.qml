import QtQuick
import QtQuick.Controls.Basic

// чекбокс — маленький и аккуратный
CheckBox {
    id: root

    indicator: Rectangle {
        implicitWidth: 18
        implicitHeight: 18
        radius: 5
        border.width: 1
        border.color: root.checked ? Qt.rgba(1,0.42,0.21,0.70) : Qt.rgba(1,1,1,0.25)
        color: root.checked ? Qt.rgba(1,0.42,0.21,0.20) : "transparent"
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Text {
            anchors.centerIn: parent
            visible: root.checked
            text: "✓"
            color: "#FF6B35"
            font.pixelSize: 11
            font.weight: 700
        }
    }

    contentItem: Text {
        leftPadding: root.indicator.width + 8
        text: root.text
        color: root.checked ? Qt.rgba(1,1,1,0.90) : Qt.rgba(1,1,1,0.60)
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
        Behavior on color { ColorAnimation { duration: 100 } }
    }
}
