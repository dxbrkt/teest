import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "components"
import "panels"

// главный экран — три колонки поверх фростед-гласса
Item {
    id: root

    Component.onCompleted: {
        Backend.loadConfig()
    }

    // тёмный слой поверх NSVisualEffectView
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.05, 0.05, 0.07, 0.80)
    }

    // верхняя полоска — просто выглядит красиво
    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 2
        color: Qt.rgba(1, 0.42, 0.21, 0.55)
    }

    // заголовочная панель — тут можно таскать окно и есть шестерня
    Rectangle {
        id: titleBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 40
        color: "transparent"

        // разделитель снизу
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.06)
        }

        // название по центру
        Text {
            anchors.centerIn: parent
            text: "TF2 Skin Generator"
            color: Qt.rgba(1, 1, 1, 0.72)
            font.pixelSize: 13
            font.weight: 600
            font.letterSpacing: 0.2
        }

        // кнопка шестерня — справа
        AbstractButton {
            id: gearBtn
            anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
            width: 30; height: 30

            background: Rectangle {
                radius: 7
                color: gearBtn.pressed  ? Qt.rgba(1,1,1,0.16)
                     : gearBtn.hovered  ? Qt.rgba(1,1,1,0.09)
                     : "transparent"
                Behavior on color { ColorAnimation { duration: 80 } }
            }

            contentItem: Text {
                anchors.centerIn: parent
                text: "⚙"
                color: Qt.rgba(1, 1, 1, 0.48)
                font.pixelSize: 15
            }

            onClicked: settingsOverlay.visible = !settingsOverlay.visible
        }

        // зона перетаскивания окна (трафик-лайтсы слева, шестерня справа)
        MouseArea {
            anchors { fill: parent; leftMargin: 80; rightMargin: 50 }
            property point _start

            onPressed: function(e) { _start = Qt.point(e.x, e.y) }
            onPositionChanged: function(e) {
                if (pressed) {
                    appWindow.x += e.x - _start.x
                    appWindow.y += e.y - _start.y
                }
            }
        }
    }

    // три основные колонки
    RowLayout {
        anchors {
            top: titleBar.bottom
            left: parent.left; right: parent.right; bottom: parent.bottom
            margins: 16
            topMargin: 12
        }
        spacing: 14

        // колонка 1 — выбор оружия / шапки
        Item {
            Layout.preferredWidth: 270
            Layout.fillHeight: true

            GlassCard { anchors.fill: parent; radius: 18; glassOpacity: 0.06 }

            WeaponPanel {
                id: weaponPanel
                anchors { fill: parent; margins: 16 }
                onModeChanged: function(m) {
                    previewPanel.mode = m
                    settingsPanel.mode = m
                }
                onHatSelected: function(mdl) { settingsPanel.hatMdlPath = mdl }
            }
        }

        // колонка 2 — превью текстуры + 3D
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GlassCard { anchors.fill: parent; radius: 18; glassOpacity: 0.05 }

            PreviewPanel {
                id: previewPanel
                anchors { fill: parent; margins: 16 }
                onImageDropped: function(p) { settingsPanel.imagePath = p }
            }
        }

        // колонка 3 — настройки сборки + кнопка build
        Item {
            Layout.preferredWidth: 275
            Layout.fillHeight: true

            GlassCard { anchors.fill: parent; radius: 18; glassOpacity: 0.06 }

            SettingsPanel {
                id: settingsPanel
                anchors { fill: parent; margins: 16 }
            }
        }
    }

    // оверлей настроек — открывается по шестерне
    Item {
        id: settingsOverlay
        anchors.fill: parent
        visible: false

        // затемнение сзади
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            MouseArea {
                anchors.fill: parent
                onClicked: settingsOverlay.visible = false
            }
        }

        // карточка настроек
        Item {
            anchors.centerIn: parent
            width: 440
            height: settingsForm.implicitHeight + 48

            GlassCard { anchors.fill: parent; radius: 20; glassOpacity: 0.11 }

            ColumnLayout {
                id: settingsForm
                anchors { fill: parent; margins: 24 }
                spacing: 14

                // заголовок + кнопка закрытия
                RowLayout {
                    Text {
                        text: "SETTINGS"
                        color: Qt.rgba(1,1,1,0.35)
                        font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                        Layout.fillWidth: true
                    }
                    AbstractButton {
                        implicitWidth: 24; implicitHeight: 24
                        onClicked: settingsOverlay.visible = false
                        contentItem: Text {
                            anchors.centerIn: parent
                            text: "✕"; color: Qt.rgba(1,1,1,0.45); font.pixelSize: 14
                        }
                    }
                }

                GlassSeparator { Layout.fillWidth: true }

                Text {
                    text: "TF2 GAME FOLDER"
                    color: Qt.rgba(1,1,1,0.40)
                    font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                }
                GlassTextField {
                    id: tf2Input
                    Layout.fillWidth: true
                    placeholderText: "/path/to/steamapps/common/Team Fortress 2"
                    Component.onCompleted: {
                        Backend.configLoaded.connect(function(cfg) {
                            tf2Input.text = cfg["tf2_game_folder"] || ""
                        })
                    }
                }

                Text {
                    text: "EXPORT FOLDER"
                    color: Qt.rgba(1,1,1,0.40)
                    font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                }
                GlassTextField {
                    id: exportInput
                    Layout.fillWidth: true
                    text: "export"
                    Component.onCompleted: {
                        Backend.configLoaded.connect(function(cfg) {
                            exportInput.text = cfg["export_folder"] || "export"
                        })
                    }
                }

                Text {
                    text: "LANGUAGE"
                    color: Qt.rgba(1,1,1,0.40)
                    font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                }
                GlassComboBox {
                    id: langCombo
                    Layout.fillWidth: true
                    model: ["English", "Русский"]
                    Component.onCompleted: {
                        Backend.configLoaded.connect(function(cfg) {
                            langCombo.currentIndex = (cfg["language"] === "ru") ? 1 : 0
                        })
                    }
                }

                GlassSeparator { Layout.fillWidth: true }

                // кнопка сохранения
                GlassButton {
                    Layout.fillWidth: true
                    text: "Save Settings"
                    isPrimary: true
                    implicitHeight: 40
                    onClicked: {
                        Backend.saveConfig({
                            "tf2_game_folder": tf2Input.text,
                            "export_folder":   exportInput.text,
                            "language":        langCombo.currentIndex === 1 ? "ru" : "en"
                        })
                        settingsOverlay.visible = false
                    }
                }
            }
        }
    }
}
