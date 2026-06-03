import QtQuick
import QtQuick.Controls.Basic

// таб-кнопка для переключения между оружием и шапками
AbstractButton {
    id: root
    property bool isActive: false

    implicitHeight: 32

    background: Rectangle {
        color: "transparent"

        // нижняя линия — только когда активна
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 2
            radius: 1
            color: root.isActive ? "#FF6B35" : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    contentItem: Text {
        text: root.text
        color: root.isActive ? "#FF6B35" : Qt.rgba(1,1,1,0.38)
        font.pixelSize: 11
        font.weight: root.isActive ? 600 : 400
        font.letterSpacing: 1.5
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
