import QtQuick
import Quickshell.Io

// CPU%, Memory%, Temperature — mirrors waybar cpu/memory/temperature modules.
// NOTE: hwmon path /sys/class/hwmon/hwmon3/temp1_input is host-specific.
//       If temp reads 0, check your hwmon path with:
//         ls /sys/class/hwmon/hwmon*/temp*_input
Item {
    id: root
    height: parent.height
    width: statsRow.implicitWidth

    property int cpuUsage: 0
    property int memUsage: 0
    property int tempC: 0

    // ── CPU (delta-based /proc/stat reader) ──────────────────────────────
    Process {
        running: true
        command: [
            "bash", "-c",
            `prev_idle=0; prev_total=0
            while true; do
                read -r _ user nice system idle iowait irq softirq steal < /proc/stat
                idle_t=$((idle + iowait))
                total=$((user+nice+system+idle+iowait+irq+softirq+steal))
                if [ "$prev_total" -gt 0 ]; then
                    dt=$((total - prev_total))
                    di=$((idle_t - prev_idle))
                    [ "$dt" -gt 0 ] && echo $(( (dt - di) * 100 / dt ))
                fi
                prev_total=$total; prev_idle=$idle_t
                sleep 2
            done`
        ]
        stdout: SplitParser {
            onRead: data => { root.cpuUsage = parseInt(data.trim()) || 0 }
        }
    }

    // ── Memory (/proc/meminfo) ────────────────────────────────────────────
    Process {
        running: true
        command: [
            "bash", "-c",
            `while true; do
                awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%d\n",(t-a)*100/t}' /proc/meminfo
                sleep 2
            done`
        ]
        stdout: SplitParser {
            onRead: data => { root.memUsage = parseInt(data.trim()) || 0 }
        }
    }

    // ── Temperature (hwmon) ───────────────────────────────────────────────
    Process {
        running: true
        command: [
            "bash", "-c",
            `while true; do
                t=$(cat /sys/class/hwmon/hwmon3/temp1_input 2>/dev/null || echo 0)
                echo $((t / 1000))
                sleep 2
            done`
        ]
        stdout: SplitParser {
            onRead: data => { root.tempC = parseInt(data.trim()) || 0 }
        }
    }

    // ── Display ───────────────────────────────────────────────────────────
    Row {
        id: statsRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        // CPU
        Text {
            text: root.cpuUsage + "%   "
            color: "#D3C6AA"
            font.family: "GeistMono Nerd Font"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            height: root.height

            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["wezterm", "start", "--class", "wezterm-btop", "btop"])
            }
        }

        // Memory
        Text {
            text: root.memUsage + "%   "
            color: "#D3C6AA"
            font.family: "GeistMono Nerd Font"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            height: root.height

            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["wezterm", "start", "--class", "wezterm-btop", "btop"])
            }
        }

        // Temperature
        Text {
            readonly property string icon: {
                if (root.tempC >= 80) return "󰈸"
                if (root.tempC >= 60) return ""
                return ""
            }
            text: root.tempC + "°C " + icon
            color: root.tempC >= 80 ? "#E67E80" : "#D3C6AA"
            font.family: "GeistMono Nerd Font"
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            height: root.height

            MouseArea {
                anchors.fill: parent
                onClicked: Quickshell.execDetached(["wezterm", "start", "--class", "wezterm-btop", "btop"])
            }
        }
    }
}
