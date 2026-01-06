import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import qs.Widgets

// World Clock Bar Widget Component
Rectangle {
  id: root

  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property bool isVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"

  // Configuration
  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  // Get timezones from settings
  readonly property var timezones: cfg.timezones || defaults.timezones || []
  readonly property int rotationInterval: cfg.rotationInterval ?? defaults.rotationInterval ?? 5000
  readonly property string timeFormat: cfg.timeFormat || defaults.timeFormat || "HH:mm"

  // Filter enabled timezones
  readonly property var enabledTimezones: {
    let enabled = [];
    for (let i = 0; i < timezones.length; i++) {
      if (timezones[i].enabled) {
        enabled.push(timezones[i]);
      }
    }
    return enabled;
  }

  property int currentIndex: 0
  property string currentTime: ""
  property string currentCity: ""

  implicitWidth: Math.max(60, isVertical ? (Style.capsuleHeight || 32) : contentWidth)
  implicitHeight: Math.max(32, isVertical ? contentHeight : (Style.capsuleHeight || 32))
  radius: Style.radiusM || 8
  color: Style.capsuleColor || "#1E1E1E"
  border.color: Style.capsuleBorderColor || "#2E2E2E"
  border.width: Style.capsuleBorderWidth || 1

  readonly property real contentWidth: {
    if (isVertical) return Style.capsuleHeight || 32;
    var iconWidth = Style.toOdd ? Style.toOdd(Style.capsuleHeight * 0.6) : 20;
    var textWidth = timeText ? (timeText.implicitWidth + cityText.implicitWidth + (Style.marginS || 4) * 2) : 100;
    return iconWidth + textWidth + (Style.marginM || 8) + 20;
  }

  readonly property real contentHeight: {
    if (!isVertical) return Style.capsuleHeight || 32;
    var iconHeight = Style.toOdd ? Style.toOdd(Style.capsuleHeight * 0.6) : 20;
    return iconHeight + (Style.marginS || 4) * 2;
  }

  // Rotation timer
  Timer {
    id: rotationTimer
    interval: root.rotationInterval
    running: enabledTimezones.length > 1
    repeat: true
    onTriggered: {
      root.currentIndex = (root.currentIndex + 1) % enabledTimezones.length;
      updateTime();
    }
  }

  // Update time timer
  Timer {
    id: updateTimer
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: updateTime()
  }

  property var timeProcesses: ({})

  function updateTime() {
    if (enabledTimezones.length === 0) {
      currentCity = I18n.tr("world-clock.no-timezone");
      currentTime = "--:--";
      return;
    }

    let tz = enabledTimezones[currentIndex];
    currentCity = tz.name;

    // Get time using date command with TZ environment variable
    getTimeInTimezone(tz.timezone);
  }

  function getTimeInTimezone(timezone) {
    // Create format string based on user preference
    let format = timeFormat;
    if (format === "HH:mm") format = "+%H:%M";
    else if (format === "HH:mm:ss") format = "+%H:%M:%S";
    else if (format === "h:mm A") format = "+%I:%M %p";
    else if (format === "h:mm:ss A") format = "+%I:%M:%S %p";
    else format = "+%H:%M";

    let processId = "time_" + timezone.replace(/\//g, "_");
    
    if (!timeProcesses[processId]) {
      timeProcesses[processId] = timeProcessComponent.createObject(root, {
        processId: processId,
        timezone: timezone,
        dateFormat: format
      });
    } else {
      timeProcesses[processId].dateFormat = format;
      timeProcesses[processId].running = true;
    }
  }

  Component {
    id: timeProcessComponent
    Process {
      property string processId: ""
      property string timezone: ""
      property string dateFormat: "+%H:%M"
      
      running: false
      command: ["sh", "-c", "TZ=" + timezone + " date '" + dateFormat + "'"]
      stdout: StdioCollector {}
      
      Component.onCompleted: {
        running = true;
      }
      
      onExited: (exitCode) => {
        if (exitCode === 0) {
          root.currentTime = stdout.text.trim();
        }
      }
    }
  }

  readonly property string displayText: {
    if (enabledTimezones.length === 0) return I18n.tr("world-clock.no-timezone");
    return `${currentCity} ${currentTime}`;
  }

  readonly property string tooltipText: {
    if (enabledTimezones.length === 0) return pluginApi?.tr("world-clock.configure") || "Configure timezones";
    return `${currentCity}\n${currentTime}\n${pluginApi?.tr("world-clock.tooltip.click") || "Click to configure"}`;
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: isVertical ? 0 : (Style.marginM || 8)
    anchors.rightMargin: isVertical ? 0 : 20
    anchors.topMargin: isVertical ? (Style.marginS || 4) : 0
    anchors.bottomMargin: isVertical ? (Style.marginS || 4) : 0
    spacing: Style.marginS || 4
    visible: !isVertical

    NIcon {
      icon: "history"
      color: Color.mPrimary || "#2196F3"
      pointSize: Style.toOdd ? Style.toOdd(Style.capsuleHeight * 0.5) : 16
      Layout.alignment: Qt.AlignVCenter
    }

    NText {
      id: cityText
      text: root.currentCity
      color: Color.mOnSurface || "#FFFFFF"
      pointSize: Style.barFontSize || 11
      applyUiScale: false
      Layout.alignment: Qt.AlignVCenter
    }

    NText {
      id: timeText
      text: root.currentTime
      color: Color.mPrimary || "#2196F3"
      pointSize: Style.barFontSize || 11
      font.weight: Font.Bold
      applyUiScale: false
      Layout.alignment: Qt.AlignVCenter
    }
  }

  // Vertical layout
  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginS || 4
    spacing: Style.marginXS || 2
    visible: isVertical

    NIcon {
      icon: "history"
      color: Color.mPrimary || "#2196F3"
      pointSize: Style.toOdd ? Style.toOdd(Style.capsuleHeight * 0.45) : 14
      Layout.alignment: Qt.AlignHCenter
    }

    NText {
      text: root.currentTime.substring(0, 5)
      color: Color.mOnSurface || "#FFFFFF"
      pointSize: (Style.barFontSize || 11) * 0.7
      applyUiScale: false
      Layout.alignment: Qt.AlignHCenter
      visible: enabledTimezones.length > 0
    }
  }

  // Mouse interaction
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton

    onClicked: {
      if (pluginApi) {
        pluginApi.openPanel(screen);
      }
    }

    onEntered: {
      if (tooltipText) {
        TooltipService.show(root, tooltipText, BarService.getTooltipDirection());
      }
    }
    
    onExited: {
      TooltipService.hide();
    }
  }

  Component.onCompleted: {
    updateTime();
  }
}
