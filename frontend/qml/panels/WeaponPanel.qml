import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../components"

// панель выбора оружия и шапок — левая колонка
Item {
    id: root

    // состояние
    property var    _classes:     []
    property int    _classIdx:    0
    property int    _typeIdx:     0
    property int    _weaponIdx:   0
    property int    _tab:         0   // 0=weapons, 1=hats
    property var    _hats:        []
    property bool   _hatsLoaded:  false
    property string _tf2Root:     ""
    property bool   critHitOn:    false
    property bool   sprayOn:      false

    signal modeChanged(string mode)
    signal hatSelected(string mdlPath)

    Component.onCompleted: {
        Backend.weaponsLoaded.connect(_onWeapons)
        Backend.hatsLoaded.connect(_onHats)
        Backend.configLoaded.connect(function(cfg) {
            _tf2Root = cfg["tf2_game_folder"] || ""
        })
        Backend.loadWeapons()
    }

    function _onWeapons(classes) {
        _classes   = classes
        _classIdx  = 0
        _typeIdx   = 0
        _weaponIdx = 0
        // принудительно обновляем комбобоксы
        classCombo.currentIndex  = 0
        typeCombo.currentIndex   = 0
        _emit()
    }

    function _onHats(data) {
        _hats       = data
        _hatsLoaded = true
    }

    function _cls()     { return _classes.length > _classIdx ? _classes[_classIdx] : null }
    function _types()   { var c = _cls(); return c ? (c["types"] || []) : [] }
    function _type()    { var t = _types(); return t.length > _typeIdx ? t[_typeIdx] : null }
    function _weapons() { var t = _type(); return t ? (t["weapons"] || []) : [] }

    function _emit() {
        if (_tab === 1) return
        if (sprayOn)    { modeChanged("spray");   return }
        if (critHitOn)  { modeChanged("critHIT"); return }

        var cls  = _cls()
        var type = _type()
        if (!cls || !type) { modeChanged(""); return }
        if (type["key"] === "Custom") { modeChanged("custom"); return }

        var ws = _weapons()
        if (ws.length === 0) { modeChanged(""); return }
        var wi   = Math.min(_weaponIdx, ws.length - 1)
        modeChanged(cls["name"].toLowerCase() + "_" + ws[wi]["key"])
    }

    // ── Layout ────────────────────────────────────────────────────────────── #
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // таббар
        RowLayout {
            spacing: 0
            Layout.fillWidth: true

            TabButton {
                text: "WEAPONS"
                isActive: _tab === 0
                Layout.fillWidth: true
                onClicked: { _tab = 0; _emit() }
            }
            TabButton {
                text: "HATS"
                isActive: _tab === 1
                Layout.fillWidth: true
                onClicked: {
                    _tab = 1
                    if (!_hatsLoaded && _tf2Root !== "")
                        Backend.loadHats(_tf2Root)
                    modeChanged("hat")
                }
            }
        }

        GlassSeparator { Layout.fillWidth: true; Layout.bottomMargin: 12 }

        // ── Страница оружий ────────────────────────────────────────────────── #
        Item {
            visible: _tab === 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                // лейбл
                Text {
                    text: "SELECTION"
                    color: Qt.rgba(1,1,1,0.30)
                    font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                }

                // выбор класса
                GlassComboBox {
                    id: classCombo
                    Layout.fillWidth: true
                    model: _classes.map(function(c) { return c["icon"] + "  " + c["name"] })
                    onCurrentIndexChanged: {
                        _classIdx  = currentIndex
                        _typeIdx   = 0
                        _weaponIdx = 0
                        typeCombo.currentIndex = 0
                        _emit()
                    }
                }

                // выбор типа оружия
                GlassComboBox {
                    id: typeCombo
                    Layout.fillWidth: true
                    model: _types().map(function(t) { return t["name"] })
                    onCurrentIndexChanged: {
                        _typeIdx   = currentIndex
                        _weaponIdx = 0
                        _emit()
                    }
                }

                // список оружий карточками
                Text {
                    text: "WEAPON"
                    color: Qt.rgba(1,1,1,0.30)
                    font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                    visible: _weapons().length > 0
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: _weapons()
                            delegate: WeaponCard {
                                width: parent.width
                                required property var modelData
                                required property int index
                                weaponName: modelData["name"] || ""
                                weaponKey:  modelData["key"]  || ""
                                isSelected: index === _weaponIdx && !critHitOn && !sprayOn
                                onClicked: {
                                    _weaponIdx = index
                                    critHitOn  = false
                                    sprayOn    = false
                                    _emit()
                                }
                            }
                        }
                    }
                }

                GlassSeparator { Layout.fillWidth: true }

                // спецрежимы — CritHIT и Spray
                Text {
                    text: "SPECIAL MODES"
                    color: Qt.rgba(1,1,1,0.30)
                    font.pixelSize: 10; font.letterSpacing: 2; font.weight: 600
                }

                // CritHIT тогл
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 10
                    color: critHitOn ? Qt.rgba(1,0.42,0.21,0.14) : Qt.rgba(1,1,1,0.04)
                    border.width: 1
                    border.color: critHitOn ? Qt.rgba(1,0.42,0.21,0.45) : Qt.rgba(1,1,1,0.08)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 7

                        // иконка — жёстко фиксируем размер через Item-обёртку
                        Item {
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Layout.alignment: Qt.AlignVCenter
                            Image {
                                anchors.fill: parent
                                source: "qrc:/TF2SG/src/CritIcon.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                        }

                        Text {
                            text: "CritHIT"
                            color: critHitOn ? "#FF6B35" : Qt.rgba(1,1,1,0.60)
                            font.pixelSize: 13
                            font.weight: critHitOn ? 600 : 400
                            Layout.fillWidth: true
                        }

                        // тогл-переключатель
                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 16
                            radius: 8
                            color: critHitOn ? Qt.rgba(1,0.42,0.21,0.80) : Qt.rgba(1,1,1,0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                x: critHitOn ? parent.width - width - 2 : 2
                                y: 2; width: 12; height: 12; radius: 6
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            critHitOn = !critHitOn
                            if (critHitOn) sprayOn = false
                            _emit()
                        }
                    }
                }

                // Spray тогл
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 10
                    color: sprayOn ? Qt.rgba(1,0.42,0.21,0.14) : Qt.rgba(1,1,1,0.04)
                    border.width: 1
                    border.color: sprayOn ? Qt.rgba(1,0.42,0.21,0.45) : Qt.rgba(1,1,1,0.08)
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        Text {
                            text: "🎨  Spray"
                            color: sprayOn ? "#FF6B35" : Qt.rgba(1,1,1,0.60)
                            font.pixelSize: 13
                            font.weight: sprayOn ? 600 : 400
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            width: 28; height: 16; radius: 8
                            color: sprayOn ? Qt.rgba(1,0.42,0.21,0.80) : Qt.rgba(1,1,1,0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Rectangle {
                                x: sprayOn ? parent.width - width - 2 : 2
                                y: 2; width: 12; height: 12; radius: 6
                                color: "white"
                                Behavior on x { NumberAnimation { duration: 150 } }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            sprayOn = !sprayOn
                            if (sprayOn) critHitOn = false
                            _emit()
                        }
                    }
                }
            }
        }

        // ── Страница шапок ─────────────────────────────────────────────────── #
        Item {
            visible: _tab === 1
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                GlassTextField {
                    id: hatSearch
                    Layout.fillWidth: true
                    placeholderText: "Search hats..."
                }

                // подсказка если TF2 не задан
                Text {
                    visible: _tf2Root === ""
                    text: "Set TF2 folder in ⚙ Settings"
                    color: Qt.rgba(1,1,1,0.30)
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                // список шапок
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth

                    Column {
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: _hats.filter(function(h) {
                                var q = hatSearch.text.toLowerCase()
                                return q === "" || h["name"].toLowerCase().indexOf(q) >= 0
                            })

                            delegate: WeaponCard {
                                width: parent.width
                                required property var modelData
                                weaponName: modelData["name"] || ""
                                weaponKey:  ""
                                isSelected: modelData["mdl_path"] === weaponPanel._selectedHat
                                onClicked: {
                                    weaponPanel._selectedHat = modelData["mdl_path"]
                                    hatSelected(modelData["mdl_path"])
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    // храним выбранную шапку тут
    property string _selectedHat: ""
}
