import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null
  spacing: Style.marginM

  property var cfg: pluginApi?.pluginSettings || ({})
  property var defaults: pluginApi?.manifest?.metadata?.defaultSettings || ({})

  property int valueIntervalSeconds: cfg.intervalSeconds ?? defaults.intervalSeconds ?? 2
  property int valueTopProcesses:    cfg.topProcesses    ?? defaults.topProcesses    ?? 25
  property int valueHistorySamples:  cfg.historySamples  ?? defaults.historySamples  ?? 120
  property int valueThresholdGoodW:  cfg.thresholdGoodW  ?? defaults.thresholdGoodW  ?? 8
  property int valueThresholdWarnW:  cfg.thresholdWarnW  ?? defaults.thresholdWarnW  ?? 15
  property string valueColorGood:    cfg.colorGood       ?? defaults.colorGood       ?? "#A7C080"
  property string valueColorWarning: cfg.colorWarning    ?? defaults.colorWarning    ?? "#DBBC7F"
  property string valueColorCritical:cfg.colorCritical   ?? defaults.colorCritical   ?? "#E67E80"
  property string valueBarShows:     cfg.barShows        ?? defaults.barShows        ?? "power_w"
  property bool valueShowSparkline:  cfg.showSparkline   ?? defaults.showSparkline   ?? true
  property string valueDefaultSort:  cfg.defaultSort     ?? defaults.defaultSort     ?? "power_w"

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("PowerMonitor", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.pluginSettings.intervalSeconds = root.valueIntervalSeconds;
    pluginApi.pluginSettings.topProcesses    = root.valueTopProcesses;
    pluginApi.pluginSettings.historySamples  = root.valueHistorySamples;
    pluginApi.pluginSettings.thresholdGoodW  = root.valueThresholdGoodW;
    pluginApi.pluginSettings.thresholdWarnW  = root.valueThresholdWarnW;
    pluginApi.pluginSettings.colorGood       = root.valueColorGood;
    pluginApi.pluginSettings.colorWarning    = root.valueColorWarning;
    pluginApi.pluginSettings.colorCritical   = root.valueColorCritical;
    pluginApi.pluginSettings.barShows        = root.valueBarShows;
    pluginApi.pluginSettings.showSparkline   = root.valueShowSparkline;
    pluginApi.pluginSettings.defaultSort     = root.valueDefaultSort;
    pluginApi.saveSettings();
    Logger.d("PowerMonitor", "Settings saved");
  }

  NHeader {
    label: pluginApi?.tr("settings.section.sampling.label") || "Sampling"
    description: pluginApi?.tr("settings.section.sampling.desc")
  }

  NSpinBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.intervalSeconds.label") || "Sample interval (s)"
    description: pluginApi?.tr("settings.intervalSeconds.desc")
    minimum: 1
    maximum: 60
    value: root.valueIntervalSeconds
    onValueChanged: root.valueIntervalSeconds = value
  }

  NSpinBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.topProcesses.label") || "Top processes shown"
    description: pluginApi?.tr("settings.topProcesses.desc")
    minimum: 5
    maximum: 100
    value: root.valueTopProcesses
    onValueChanged: root.valueTopProcesses = value
  }

  NSpinBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.historySamples.label") || "Sparkline history (samples)"
    description: pluginApi?.tr("settings.historySamples.desc")
    minimum: 30
    maximum: 600
    value: root.valueHistorySamples
    onValueChanged: root.valueHistorySamples = value
  }

  NDivider { Layout.fillWidth: true }

  NHeader {
    label: pluginApi?.tr("settings.section.thresholds.label") || "Thresholds"
    description: pluginApi?.tr("settings.section.thresholds.desc")
  }

  NSpinBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.thresholdGoodW.label") || "Good ≤ (W)"
    description: pluginApi?.tr("settings.thresholdGoodW.desc")
    minimum: 1
    maximum: 100
    value: root.valueThresholdGoodW
    onValueChanged: root.valueThresholdGoodW = value
  }

  NSpinBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.thresholdWarnW.label") || "Warn ≤ (W)"
    description: pluginApi?.tr("settings.thresholdWarnW.desc")
    minimum: 1
    maximum: 100
    value: root.valueThresholdWarnW
    onValueChanged: root.valueThresholdWarnW = value
  }

  NDivider { Layout.fillWidth: true }

  NHeader {
    label: pluginApi?.tr("settings.section.colors.label") || "Colors"
    description: pluginApi?.tr("settings.section.colors.desc")
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    NLabel {
      label: pluginApi?.tr("settings.colorGood.label") || "Good"
      description: pluginApi?.tr("settings.colorGood.desc")
      Layout.fillWidth: true
    }
    NColorPicker {
      selectedColor: root.valueColorGood
      onColorSelected: key => root.valueColorGood = key
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    NLabel {
      label: pluginApi?.tr("settings.colorWarning.label") || "Warning"
      description: pluginApi?.tr("settings.colorWarning.desc")
      Layout.fillWidth: true
    }
    NColorPicker {
      selectedColor: root.valueColorWarning
      onColorSelected: key => root.valueColorWarning = key
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: Style.marginM
    NLabel {
      label: pluginApi?.tr("settings.colorCritical.label") || "Critical"
      description: pluginApi?.tr("settings.colorCritical.desc")
      Layout.fillWidth: true
    }
    NColorPicker {
      selectedColor: root.valueColorCritical
      onColorSelected: key => root.valueColorCritical = key
    }
  }

  NDivider { Layout.fillWidth: true }

  NHeader {
    label: pluginApi?.tr("settings.section.display.label") || "Display"
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.barShows.label") || "Bar widget shows"
    description: pluginApi?.tr("settings.barShows.desc")
    model: [
      { key: "power_w",     name: pluginApi?.tr("settings.barShows.power")   || "Discharge (W)" },
      { key: "battery_pct", name: pluginApi?.tr("settings.barShows.battery") || "Battery (%)" },
      { key: "both",        name: pluginApi?.tr("settings.barShows.both")    || "Both" }
    ]
    currentKey: root.valueBarShows
    onSelected: key => root.valueBarShows = key
  }

  NCheckbox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.showSparkline.label") || "Show sparkline in bar"
    description: pluginApi?.tr("settings.showSparkline.desc")
    checked: root.valueShowSparkline
    onToggled: checked => root.valueShowSparkline = checked
  }

  NComboBox {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.defaultSort.label") || "Default sort column"
    description: pluginApi?.tr("settings.defaultSort.desc")
    model: [
      { key: "power_w",      name: pluginApi?.tr("panel.col.power") || "W" },
      { key: "cpu_pct",      name: "CPU" },
      { key: "rss_mb",       name: pluginApi?.tr("panel.col.rss")   || "RSS" },
      { key: "vol_per_sec",  name: pluginApi?.tr("panel.col.wakes") || "wakes/s" },
      { key: "io",           name: pluginApi?.tr("panel.col.io")    || "I/O" }
    ]
    currentKey: root.valueDefaultSort
    onSelected: key => root.valueDefaultSort = key
  }
}
