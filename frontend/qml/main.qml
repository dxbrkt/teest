import QtQuick

// точка входа — просто окно с AppWindow внутри
Window {
    id: appWindow
    width: 1400
    height: 820
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: "TF2 Skin Generator"
    color: "transparent"

    AppWindow { anchors.fill: parent }
}
