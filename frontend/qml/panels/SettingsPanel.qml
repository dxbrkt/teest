import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../components"

// панель настроек и сборки — правая колонка
Item {
    id: root

    // входные данные от других панелей
    property string mode: ""
    property string imagePath: ""
    property string hatMdlPath: ""

    // настройки сборки
    property int    resolution: 512
    property string format: "DXT1"
    property string filename: "myskin"
    property bool   flagClamps: false
    property bool   flagClampt: false
    property bool   flagNoMipmaps: false
    property bool   flagNoLod: false

    // состояние билда
    property bool   isBuilding: false
    property int    buildProgress: 0
    property string buildMessage: ""
    property string buildResult: ""
    property bool   buildSuccess: false

    // конфиг из настроек
    property string tf2Root: ""
    property string exportFolder: "export"
    property string language: "en"

    Component.onCompleted: {
        Backend.configLoaded.connect(_onConfig)
        Backend.buildStarted.connect(_onBuildStarted)
        Backend.jobProgress.connect(_onProgress)
        Backend.buildFinished.connect(_onFinished)
    }

    function _onConfig(cfg) {
        tf2Root      = cfg["tf2_game_folder"] || ""
        exportFolder = cfg["export_folder"]   || "export"
        language     = cfg["language"]         || "en"
        filename     = cfg["last_filename"]    || "myskin"
    }

    function _onBuildStarted(jobId) {
        isBuilding    = true
        buildProgress = 0
        buildMessage  = "Starting…"
        buildResult   = ""
    }

    function _onProgress(pct, msg) {
        buildProgress = pct
        buildMessage  = msg
    }

    function _onFinished(success, result) {
        isBuilding    = false
        buildSuccess  = success
        buildResult   = result
        buildProgress = success ? 100 : buildProgress
        buildMessage  = success ? "✓ Done" : "✗ " + result
    }

    function _startBuild() {
        if (mode === "") return
        if (imagePath === "" && mode !== "custom" && mode !== "hat") return

        var size = [resolution, resolution]
        // спрей всегда 256×256 — это работает, не трогаем
        if (mode === "spray") size = [256, 256]

        Backend.startBuild({
            "mode":          mode,
            "image_path":    imagePath !== "" ? imagePath : null,
            "hat_mdl_path":  hatMdlPath !== "" ? hatMdlPath : null,
            "filename":      filename,
            "size":          size,
            "format":        format,
            "flags": [].concat(
                flagClamps    ? ["clamps"]    : [],
                flagClampt    ? ["clampt"]    : [],
                flagNoMipmaps ? ["nomipmaps"] : [],
                flagNoLod     ? ["nolod"]     : []
            ),
            "tf2_root":      tf2Root,
            "export_folder": exportFolder,
            "language":      language,
        })
    }

    // ── Layout ────────────────────────────────────────────────────────────── #
    ScrollView {
        anchors.fill: parent
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 12

            // заголовок колонки
            Text {
                text: "BUILD SETTINGS"
                color: Qt.rgba(1,1,1,0.35)
                font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
            }

            // ── Разрешение — три pill кнопки ───────────────────────────────── #
            GlassCard {
                Layout.fillWidth: true
                implicitHeight: resCardCol.implicitHeight + 28

                ColumnLayout {
                    id: resCardCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    Text { text: "RESOLUTION"; color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600 }

                    RowLayout {
                        spacing: 6

                        Repeater {
                            model: [256, 512, 1024]
                            delegate: AbstractButton {
                                id: resBtn
                                required property int modelData
                                implicitWidth: (parent.width - 12) / 3
                                implicitHeight: 34
                                Layout.fillWidth: true

                                background: Rectangle {
                                    radius: 8
                                    color: resolution === modelData
                                        ? Qt.rgba(1,0.42,0.21,0.22)
                                        : hovered ? Qt.rgba(1,1,1,0.08) : Qt.rgba(1,1,1,0.06)
                                    border.width: 1
                                    border.color: resolution === modelData
                                        ? Qt.rgba(1,0.42,0.21,0.60)
                                        : Qt.rgba(1,1,1,0.12)
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }

                                contentItem: Text {
                                    text: modelData
                                    color: resolution === modelData ? "#FF6B35" : Qt.rgba(1,1,1,0.65)
                                    font.pixelSize: 12
                                    font.weight: resolution === modelData ? 600 : 400
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: resolution = modelData
                            }
                        }
                    }
                }
            }

            // ── Формат ────────────────────────────────────────────────────── #
            GlassCard {
                Layout.fillWidth: true
                implicitHeight: fmtCardCol.implicitHeight + 28

                ColumnLayout {
                    id: fmtCardCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 10

                    Text { text: "FORMAT"; color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600 }
                    GlassComboBox {
                        Layout.fillWidth: true
                        model: ["DXT1", "DXT5", "BGR888", "BGRA8888", "RGBA8888"]
                        onCurrentTextChanged: format = currentText
                    }
                }
            }

            // ── Имя файла ─────────────────────────────────────────────────── #
            GlassCard {
                Layout.fillWidth: true
                implicitHeight: fnCardCol.implicitHeight + 28

                ColumnLayout {
                    id: fnCardCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    Text { text: "OUTPUT FILENAME"; color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600 }
                    GlassTextField {
                        Layout.fillWidth: true
                        text: filename
                        placeholderText: "e.g. my_skin_mod"
                        onTextChanged: filename = text
                    }
                    // подсказка с финальным именем файла
                    Text {
                        text: filename !== "" ? filename + ".vpk" : ""
                        color: Qt.rgba(1,0.42,0.21,0.60)
                        font.pixelSize: 11
                        visible: filename !== ""
                    }
                }
            }

            // ── VTF флаги — 4 чекбокса в 2 колонки ────────────────────────── #
            GlassCard {
                Layout.fillWidth: true
                implicitHeight: flagsCardCol.implicitHeight + 28

                ColumnLayout {
                    id: flagsCardCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    Text { text: "VTF FLAGS"; color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600 }

                    // два ряда по два чекбокса
                    RowLayout {
                        spacing: 8
                        GlassCheckBox { text: "clamps";    checked: flagClamps;    onCheckedChanged: flagClamps    = checked; Layout.fillWidth: true }
                        GlassCheckBox { text: "clampt";    checked: flagClampt;    onCheckedChanged: flagClampt    = checked; Layout.fillWidth: true }
                    }
                    RowLayout {
                        spacing: 8
                        GlassCheckBox { text: "nomipmaps"; checked: flagNoMipmaps; onCheckedChanged: flagNoMipmaps = checked; Layout.fillWidth: true }
                        GlassCheckBox { text: "nolod";     checked: flagNoLod;     onCheckedChanged: flagNoLod     = checked; Layout.fillWidth: true }
                    }
                }
            }

            // ── Прогресс билда — показываем только когда идёт или завершён ── #
            GlassCard {
                Layout.fillWidth: true
                implicitHeight: progressCardCol.implicitHeight + 28
                visible: isBuilding || buildResult !== ""

                ColumnLayout {
                    id: progressCardCol
                    anchors { fill: parent; margins: 14 }
                    spacing: 8

                    Text { text: "BUILD"; color: Qt.rgba(1,1,1,0.40); font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600 }

                    // прогресс-бар
                    Rectangle {
                        Layout.fillWidth: true
                        height: 6; radius: 3
                        color: Qt.rgba(1,1,1,0.08)

                        Rectangle {
                            width: parent.width * (buildProgress / 100)
                            height: parent.height; radius: parent.radius
                            // зелёный когда успех, оранжевый во время работы
                            color: buildSuccess && !isBuilding ? "#34C759" : "#FF6B35"
                            Behavior on width { NumberAnimation { duration: 200 } }
                        }
                    }

                    // статус-сообщение
                    Text {
                        Layout.fillWidth: true
                        text: buildMessage
                        color: {
                            if (!isBuilding && buildResult !== "")
                                return buildSuccess ? "#34C759" : "#FF453A"
                            return Qt.rgba(1,1,1,0.60)
                        }
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            // ── Главная кнопка Build VPK ───────────────────────────────────── #
            GlassButton {
                Layout.fillWidth: true
                implicitHeight: 48
                text: isBuilding ? ("Building…  " + buildProgress + "%") : "▶  BUILD VPK"
                isPrimary: true
                enabled: !isBuilding && mode !== "" &&
                         (imagePath !== "" || mode === "custom" || mode === "hat")
                radius: 12
                onClicked: _startBuild()

                opacity: enabled ? 1.0 : 0.45
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }

            // кнопка отмены — только во время билда
            GlassButton {
                Layout.fillWidth: true
                implicitHeight: 36
                text: "✕  Cancel"
                visible: isBuilding
                radius: 10
                onClicked: Backend.cancelBuild()
            }

            Item { Layout.fillHeight: true }
        }
    }
}
