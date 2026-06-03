import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

// карточка одного оружия — кликабельная
AbstractButton {
    id: root

    property string weaponName: ""
    property string weaponKey: ""
    property bool isSelected: false

    implicitHeight: 58
    implicitWidth: 200

    background: Rectangle {
        radius: 12
        color: root.isSelected
            ? Qt.rgba(1, 0.42, 0.21, 0.12)
            : root.hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.04)
        border.width: 1
        border.color: root.isSelected
            ? Qt.rgba(1, 0.42, 0.21, 0.45)
            : root.hovered ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        // верхний хайлайт
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
            height: 1
            radius: parent.radius - 1
            color: Qt.rgba(1, 1, 1, root.isSelected ? 0.20 : 0.08)
        }
    }

    contentItem: RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 10

        // оранжевая точка когда выбрано
        Rectangle {
            width: 6; height: 6
            radius: 3
            color: root.isSelected ? "#FF6B35" : Qt.rgba(1,1,1,0.18)
            Behavior on color { ColorAnimation { duration: 100 } }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.weaponName
                color: root.isSelected ? Qt.rgba(1,1,1,0.95) : Qt.rgba(1,1,1,0.70)
                font.pixelSize: 13
                font.weight: root.isSelected ? 500 : 400
                elide: Text.ElideRight
            }

            Text {
                text: root.weaponKey
                color: root.isSelected ? Qt.rgba(1,0.42,0.21,0.70) : Qt.rgba(1,1,1,0.28)
                font.pixelSize: 11
            }
        }
    }

    scale: pressed ? 0.97 : 1.0
    Behavior on scale { NumberAnimation { duration: 70 } }
}
