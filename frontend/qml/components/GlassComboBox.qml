import QtQuick
import QtQuick.Controls.Basic

// дропдаун — стилизован под тему
ComboBox {
    id: root

    implicitHeight: 36

    contentItem: Text {
        leftPadding: 12
        text: root.displayText
        color: Qt.rgba(1, 1, 1, 0.88)
        font.pixelSize: 13
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        radius: 9
        color: root.popup.visible ? Qt.rgba(1,1,1,0.10) : Qt.rgba(1,1,1,0.06)
        border.width: 1
        border.color: root.popup.visible ? Qt.rgba(1,0.42,0.21,0.55) : Qt.rgba(1,1,1,0.12)
        Behavior on border.color { ColorAnimation { duration: 100 } }
    }

    indicator: Text {
        x: root.width - width - 12
        y: (root.height - height) / 2
        text: "⌄"
        color: Qt.rgba(1,1,1,0.45)
        font.pixelSize: 12
        // тут пришлось убрать анимацию поворота — вызывало глюки в некоторых версиях Qt
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        padding: 0

        background: Rectangle {
            radius: 10
            color: Qt.rgba(0.10, 0.10, 0.13, 0.97)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
        }
    }

    delegate: ItemDelegate {
        width: root.width
        height: 34

        contentItem: Text {
            leftPadding: 12
            text: modelData
            color: highlighted ? "#FF6B35" : Qt.rgba(1,1,1,0.80)
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }

        highlighted: root.highlightedIndex === index

        background: Rectangle {
            color: highlighted ? Qt.rgba(1,0.42,0.21,0.10) : "transparent"
        }
    }
}
