import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import QtWebEngine
import "../components"

// центральная панель — дроп текстуры сверху, 3D снизу
Item {
    id: root

    property string imagePath: ""
    property string mode: ""
    readonly property int _port: Backend.port

    signal imageDropped(string path)

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // заголовок + чип режима
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "PREVIEW"
                color: Qt.rgba(1,1,1,0.30)
                font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
            }

            // чип с текущим режимом — оранжевый
            Rectangle {
                visible: root.mode !== ""
                radius: 10
                color: Qt.rgba(1, 0.42, 0.21, 0.16)
                border.width: 1
                border.color: Qt.rgba(1, 0.42, 0.21, 0.38)
                width: chipText.implicitWidth + 18
                height: 20
                Behavior on width { NumberAnimation { duration: 150 } }

                Text {
                    id: chipText
                    anchors.centerIn: parent
                    text: root.mode
                    color: "#FF6B35"
                    font.pixelSize: 11
                    font.weight: 500
                }
            }

            Item { Layout.fillWidth: true }

            // кнопка очистки — рядом с заголовком
            GlassButton {
                visible: root.imagePath !== ""
                text: "✕ Clear"
                implicitWidth: 70
                implicitHeight: 24
                radius: 7
                onClicked: { root.imagePath = ""; root.imageDropped("") }
            }
        }

        // ── дроп-зона текстуры (~45% высоты) ─────────────────────────────── #
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.44

            GlassCard {
                anchors.fill: parent
                radius: 14
            }

            DropArea {
                id: dropArea
                anchors.fill: parent
                onDropped: function(drop) {
                    if (drop.hasUrls) {
                        var p = drop.urls[0].toString()
                        // срезаем file:// префикс
                        if (p.startsWith("file://")) p = p.substring(7)
                        root.imagePath = p
                        root.imageDropped(p)
                    }
                }
            }

            Item {
                anchors { fill: parent; margins: 14 }

                // превью загруженной текстуры
                Image {
                    anchors.fill: parent
                    source: root.imagePath !== "" ? "file://" + root.imagePath : ""
                    visible: root.imagePath !== ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    asynchronous: true
                }

                // плейсхолдер когда ничего не загружено
                ColumnLayout {
                    anchors.centerIn: parent
                    visible: root.imagePath === ""
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "🖼"
                        font.pixelSize: 40
                        color: Qt.rgba(1,1,1,0.09)
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Drop texture here"
                        color: Qt.rgba(1,1,1,0.25)
                        font.pixelSize: 14
                        font.weight: 500
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "PNG  ·  TGA  ·  JPG  ·  VTF"
                        color: Qt.rgba(1,1,1,0.14)
                        font.pixelSize: 11
                        font.letterSpacing: 0.5
                    }
                }

                // оранжевая рамка при наведении файла
                Rectangle {
                    anchors.fill: parent
                    radius: 10
                    color: Qt.rgba(1, 0.42, 0.21, 0.07)
                    border.color: "#FF6B35"
                    border.width: 2
                    visible: dropArea.containsDrag
                    Behavior on opacity { NumberAnimation { duration: 80 } }
                }
            }
        }

        // ── 3D превью через Three.js / WebEngineView ──────────────────────── #
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GlassCard {
                anchors.fill: parent
                radius: 14
                glassOpacity: 0.04
            }

            // плейсхолдер пока оружие не выбрано
            ColumnLayout {
                anchors.centerIn: parent
                visible: root.mode === ""
                spacing: 8

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "3D"
                    font.pixelSize: 38
                    font.weight: 100
                    color: Qt.rgba(1,1,1,0.06)
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "3D Preview"
                    color: Qt.rgba(1,1,1,0.16)
                    font.pixelSize: 13
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Select a weapon to load model"
                    color: Qt.rgba(1,1,1,0.09)
                    font.pixelSize: 11
                }
            }

            // Three.js вьювер — грузится лениво когда выбрано оружие
            // загружаем viewer3d.html с бэкенда, передаём mode как query-параметр
            Loader {
                id: viewer3d
                anchors { fill: parent; margins: 2 }
                active: root.mode !== "" && root._port > 0

                sourceComponent: Component {
                    WebEngineView {
                        // каждый раз при смене mode перегружаем страницу
                        url: "http://127.0.0.1:" + root._port
                            + "/static/viewer3d.html?mode=" + encodeURIComponent(root.mode)
                        backgroundColor: "transparent"

                        // отключаем контекстное меню — тут оно не нужно
                        onContextMenuRequested: function(req) { req.accepted = true }
                    }
                }

                // при смене режима — перезагрузить если уже активен
                Connections {
                    target: root
                    function onModeChanged() {
                        if (viewer3d.active && viewer3d.item) {
                            viewer3d.item.url = "http://127.0.0.1:" + root._port
                                + "/static/viewer3d.html?mode=" + encodeURIComponent(root.mode)
                        }
                    }
                }
            }
        }
    }
}
