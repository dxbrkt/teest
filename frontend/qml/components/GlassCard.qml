import QtQuick

// стандартная карточка со стеклянным эффектом — используется везде
Rectangle {
    id: root

    property real glassOpacity: 0.055
    property bool hoverable: false
    property bool isSelected: false

    radius: 14
    color: isSelected
        ? Qt.rgba(1, 0.42, 0.21, 0.12)
        : Qt.rgba(1, 1, 1, glassOpacity)

    border.width: 1
    border.color: isSelected
        ? Qt.rgba(1, 0.42, 0.21, 0.45)
        : Qt.rgba(1, 1, 1, 0.10)

    // верхняя светлая полоска — добавляет глубины
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: 1; rightMargin: 1 }
        height: 1
        radius: parent.radius - 1
        color: Qt.rgba(1, 1, 1, isSelected ? 0.25 : 0.14)
    }

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }
}
