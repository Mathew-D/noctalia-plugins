import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  readonly property var geometryPlaceholder: panelContainer
  property real contentPreferredWidth: (pluginApi?.pluginSettings?.panelWidth ?? 600) * Style.uiScaleRatio
  property real contentPreferredHeight: (pluginApi?.pluginSettings?.panelHeight ?? 400) * Style.uiScaleRatio
  readonly property bool allowAttach: true
  anchors.fill: parent

  // Local state for the text content
  property string textContent: pluginApi?.pluginSettings?.scratchpadContent ?? ""
  property int fontSize: pluginApi?.pluginSettings?.fontSize ?? 14
  property int savedCursorPosition: pluginApi?.pluginSettings?.cursorPosition ?? 0
  property real savedScrollX: pluginApi?.pluginSettings?.scrollPositionX ?? 0
  property real savedScrollY: pluginApi?.pluginSettings?.scrollPositionY ?? 0
  property bool restoringState: false

  // Auto-save timer
  Timer {
    id: saveTimer
    interval: 500
    repeat: false
    onTriggered: {
      if (pluginApi && !restoringState) {
        pluginApi.pluginSettings.scratchpadContent = root.textContent;
        pluginApi.pluginSettings.cursorPosition = textArea.cursorPosition;
        pluginApi.pluginSettings.scrollPositionX = scrollView.ScrollBar.horizontal.position;
        pluginApi.pluginSettings.scrollPositionY = scrollView.ScrollBar.vertical.position;
        pluginApi.saveSettings();
      }
    }
  }

  onTextContentChanged: {
    if (!restoringState) {
      saveTimer.restart();
    }
  }

  Component.onCompleted: {
    restoringState = true;
    
    if (pluginApi) {
      textContent = pluginApi.pluginSettings.scratchpadContent || "";
      savedCursorPosition = pluginApi.pluginSettings.cursorPosition ?? 0;
      savedScrollX = pluginApi.pluginSettings.scrollPositionX ?? 0;
      savedScrollY = pluginApi.pluginSettings.scrollPositionY ?? 0;
    }
    
    Qt.callLater(() => {
      textArea.forceActiveFocus();
      textArea.cursorPosition = savedCursorPosition;
      scrollView.ScrollBar.horizontal.position = savedScrollX;
      scrollView.ScrollBar.vertical.position = savedScrollY;
      restoringState = false;
    });
  }

  Component.onDestruction: {
    // Save everything when the panel is closed
    if (pluginApi) {
      pluginApi.pluginSettings.scratchpadContent = root.textContent;
      pluginApi.pluginSettings.cursorPosition = textArea.cursorPosition;
      pluginApi.pluginSettings.scrollPositionX = scrollView.ScrollBar.horizontal.position;
      pluginApi.pluginSettings.scrollPositionY = scrollView.ScrollBar.vertical.position;
      pluginApi.saveSettings();
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      textContent = pluginApi.pluginSettings.scratchpadContent || "";
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"
    radius: Style.radiusL

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Style.marginL
      spacing: Style.marginM

      // Header
      RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NIcon {
          icon: "file-text"
          pointSize: Style.fontSizeL
        }

        NText {
          text: pluginApi?.tr("panel.header.title") || "Scratchpad"
          pointSize: Style.fontSizeL
          font.weight: Font.Bold
          Layout.fillWidth: true
        }

        NIconButton {
          icon: "x"
          onClicked: {
            if (pluginApi) {
              pluginApi.closePanel(root.screen)
            }
          }
        }
      }

      // Main text area
      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusM
        border.color: Color.mOutline
        border.width: 1

        ScrollView {
          id: scrollView
          anchors.fill: parent
          anchors.margins: Style.marginM

          ScrollBar.horizontal.onPositionChanged: {
            if (!restoringState) saveTimer.restart();
          }
          ScrollBar.vertical.onPositionChanged: {
            if (!restoringState) saveTimer.restart();
          }

          TextArea {
            id: textArea
            text: root.textContent
            placeholderText: pluginApi?.tr("panel.placeholder") || "Start typing your notes here..."
            wrapMode: TextArea.Wrap
            selectByMouse: true
            color: Color.mOnSurface
            font.pixelSize: root.fontSize
            background: Item {}
            focus: true

            onTextChanged: {
              if (text !== root.textContent) {
                root.textContent = text;
              }
            }

            onCursorPositionChanged: {
              if (!restoringState) saveTimer.restart();
            }
          }
        }
      }

      // Character count
      NText {
        text: {
          var chars = textArea.text.length;
          var words = textArea.text.trim().split(/\s+/).filter(w => w.length > 0).length;
          var charText = pluginApi?.tr("panel.stats.characters") || "characters";
          var wordText = pluginApi?.tr("panel.stats.words") || "words";
          return chars + " " + charText + " · " + words + " " + wordText;
        }
        pointSize: Style.fontSizeS
        color: Color.mOnSurfaceVariant
        Layout.alignment: Qt.AlignRight
      }
    }
  }
}
