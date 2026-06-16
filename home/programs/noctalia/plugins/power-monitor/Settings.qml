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
  property int valueThresholdGoodW:  cfg.thresholdGoodW  ?? defaults.thresholdGoodW  ?? 8
  property int valueThresholdWarnW:  cfg.thresholdWarnW  ?? defaults.thresholdWarnW  ?? 15
  property string valueColorGood:    cfg.colorGood       ?? defaults.colorGood       ?? "#A7C080"
  property string valueColorWarning: cfg.colorWarning    ?? defaults.colorWarning    ?? "#DBBC7F"
  property string valueColorCritical:cfg.colorCritical   ?? defaults.colorCritical   ?? "#E67E80"

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("PowerMonitor", "Cannot save settings: pluginApi is null");
      return;
    }
    pluginApi.pluginSettings.intervalSeconds = root.valueIntervalSeconds;
    pluginApi.pluginSettings.thresholdGoodW  = root.valueThresholdGoodW;
    pluginApi.pluginSettings.thresholdWarnW  = root.valueThresholdWarnW;
    pluginApi.pluginSettings.colorGood       = root.valueColorGood;
    pluginApi.pluginSettings.colorWarning    = root.valueColorWarning;
    pluginApi.pluginSettings.colorCritical   = root.valueColorCritical;
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
}
