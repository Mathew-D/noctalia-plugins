import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root

  property var pluginApi: null
  property bool expanded: false
  property bool showCompleted: pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted
  property ListModel filteredTodosModel: ListModel {}

  showBackground: (pluginApi && pluginApi.pluginSettings ? (pluginApi.pluginSettings.showBackground !== undefined ? pluginApi.pluginSettings.showBackground : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground) : pluginApi?.manifest?.metadata?.defaultSettings?.showBackground)

  readonly property color todoBg: showBackground ? Qt.rgba(0, 0, 0, 0.2) : Color.transparent
  readonly property color itemBg: showBackground ? Color.mSurface : Color.transparent
  readonly property color completedItemBg: showBackground ? Color.mSurfaceVariant : Color.transparent

  // Scaled dimensions
  readonly property int scaledMarginM: Math.round(Style.marginM * widgetScale)
  readonly property int scaledMarginS: Math.round(Style.marginS * widgetScale)
  readonly property int scaledMarginL: Math.round(Style.marginL * widgetScale)
  readonly property int scaledBaseWidgetSize: Math.round(Style.baseWidgetSize * widgetScale)
  readonly property int scaledFontSizeL: Math.round(Style.fontSizeL * widgetScale)
  readonly property int scaledFontSizeM: Math.round(Style.fontSizeM * widgetScale)
  readonly property int scaledFontSizeS: Math.round(Style.fontSizeS * widgetScale)
  readonly property int scaledRadiusM: Math.round(Style.radiusM * widgetScale)
  readonly property int scaledRadiusS: Math.round(Style.radiusS * widgetScale)

  implicitWidth: Math.round(300 * widgetScale)
  implicitHeight: {
    var headerHeight = scaledBaseWidgetSize + scaledMarginL * 2;
    if (!expanded)
      return headerHeight;

    var todosCount = root.filteredTodosModel.count;
    var contentHeight = (todosCount === 0) ? scaledBaseWidgetSize : (scaledBaseWidgetSize * todosCount + scaledMarginS * (todosCount - 1));

    var totalHeight = contentHeight + scaledMarginM * 2 + headerHeight;
    return Math.min(totalHeight, headerHeight + Math.round(400 * widgetScale)); // Max 400px of content (scaled)
  }

  function getCurrentTodos() {
    return pluginApi?.pluginSettings?.todos || [];
  }

  function getCurrentShowCompleted() {
    return pluginApi?.pluginSettings?.showCompleted !== undefined ? pluginApi.pluginSettings.showCompleted : pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
  }

  function updateFilteredTodos() {
    if (!pluginApi)
      return;

    filteredTodosModel.clear();

    var pluginTodos = getCurrentTodos();
    var currentShowCompleted = getCurrentShowCompleted();
    var filtered = pluginTodos;

    if (!currentShowCompleted) {
      filtered = pluginTodos.filter(function (todo) {
        return !todo.completed;
      });
    }

    for (var i = 0; i < filtered.length; i++) {
      filteredTodosModel.append({
                                  id: filtered[i].id,
                                  text: filtered[i].text,
                                  completed: filtered[i].completed
                                });
    }
  }

  Timer {
    id: updateTimer
    interval: 200
    running: !!pluginApi
    repeat: true
    onTriggered: {
      updateFilteredTodos();
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      root.showCompleted = getCurrentShowCompleted();
      updateFilteredTodos();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      updateFilteredTodos();
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      root.expanded = !root.expanded;
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: scaledMarginM
    spacing: scaledMarginS

    RowLayout {
      spacing: scaledMarginS
      Layout.fillWidth: true

      NIcon {
        icon: "checklist"
        pointSize: scaledFontSizeL
      }

      NText {
        text: pluginApi?.tr("desktop_widget.header_title")
        font.pointSize: scaledFontSizeL
        font.weight: Font.Medium
      }

      Item {
        Layout.fillWidth: true
      }

      NText {
        text: {
          var todos = pluginApi?.pluginSettings?.todos || [];
          var activeTodos = todos.filter(function (todo) {
            return !todo.completed;
          }).length;

          var text = pluginApi?.tr("desktop_widget.items_count");
          return text.replace("{active}", activeTodos).replace("{total}", todos.length);
        }
        color: Color.mOnSurfaceVariant
        font.pointSize: scaledFontSizeS
      }

      NIcon {
        icon: root.expanded ? "chevron-up" : "chevron-down"
        pointSize: scaledFontSizeM
        color: Color.mOnSurfaceVariant
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: expanded ? (root.implicitHeight - (scaledBaseWidgetSize + scaledMarginL * 2)) : 0
      visible: expanded

      NBox {
        anchors.fill: parent
        color: root.todoBg
        radius: scaledRadiusM

        ListView {
          id: todoListView
          anchors.fill: parent
          anchors.margins: scaledMarginS
          model: root.filteredTodosModel
          spacing: scaledMarginS
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick

          height: Math.min(contentHeight, Math.round(400 * widgetScale) - 2 * scaledMarginS)

          delegate: Rectangle {
            width: ListView.view.width
            height: scaledBaseWidgetSize
            color: model.completed ? root.completedItemBg : root.itemBg
            radius: scaledRadiusS

            RowLayout {
              anchors.fill: parent
              anchors.margins: scaledMarginS
              spacing: scaledMarginS

              NIcon {
                icon: model.completed ? "square-check" : "square"
                color: model.completed ? Color.mPrimary : Color.mOnSurfaceVariant
                pointSize: scaledFontSizeS
              }

              NText {
                text: model.text
                color: model.completed ? Color.mOnSurfaceVariant : Color.mOnSurface
                font.strikeout: model.completed
                elide: Text.ElideRight
                Layout.fillWidth: true
                font.pointSize: scaledFontSizeS
              }
            }
          }
        }

        Item {
          anchors.fill: parent
          anchors.margins: scaledMarginS
          visible: root.filteredTodosModel.count === 0

          NText {
            anchors.centerIn: parent
            text: pluginApi?.tr("desktop_widget.empty_state")
            color: Color.mOnSurfaceVariant
            font.pointSize: scaledFontSizeM
            font.weight: Font.Normal
          }
        }
      }
    }
  }
}
