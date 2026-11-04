import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "I18n.js" as I18n

BarWidget {
  id: root

  moduleName: "ubruckhaus.maprisma"

  readonly property string togglePath: Qt.resolvedUrl("maprisma-toggle").toString().replace(/^file:\/\//, "")
  readonly property string language: I18n.language(Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG"))
  function t(key) { return I18n.text(language, key) }
  readonly property bool installOpen: installPanel.open

  Process {
    id: probe
    command: [root.togglePath, "--probe"]
    onExited: function(code) {
      if (code === 0) Quickshell.execDetached([root.togglePath])
      else installPanel.open = true
    }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\u{F06A9}"
    tooltipText: "Maprisma"

    onPressed: function(mouseButton) {
      if (!root.bar) return
      if (root.installOpen) { installPanel.open = false; return }
      if (!probe.running) probe.running = true
    }
  }

  KeyboardPanel {
    id: installPanel
    bar: root.bar
    anchorItem: button
    owner: root
    focusTarget: keys
    contentWidth: installPanel.fittedContentWidth(Style.space(380))
    contentHeight: installPanel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keys
      anchors.fill: parent
      onCloseRequested: installPanel.open = false

      Column {
        id: content
        width: parent.width
        spacing: Style.space(12)

        Text {
          width: parent.width
          text: root.t("title")
          textFormat: Text.PlainText
          color: Commons.Color.popups.text
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }
        Text {
          width: parent.width
          text: root.t("body")
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          color: Commons.Color.popups.text
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
        }
        Row {
          spacing: Style.space(8)
          Button {
            focusable: true
            bordered: true
            text: root.t("cancel")
            onClicked: installPanel.open = false
          }
          Button {
            focusable: true
            bordered: true
            text: root.t("install")
            onClicked: {
              installPanel.open = false
              Quickshell.execDetached([root.togglePath, "--install"])
            }
          }
        }
      }
    }
  }
}
