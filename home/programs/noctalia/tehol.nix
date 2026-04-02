import ./default.nix {
  spectrumFrameRate = 15;
  enableDgpuMonitoring = false;
  idleConfig = {
    enabled = true;
    # Built-in timeouts disabled — handled by customCommands with battery/AC detection
    screenOffTimeout = 0;
    lockTimeout = 0;
    customCommands = builtins.toJSON [
      {
        name = "Battery: screen off + lock at 5 min";
        timeout = 300;
        command = "cat /sys/class/power_supply/BAT*/status 2>/dev/null | grep -q Discharging && hyprctl dispatch dpms off && noctalia-shell ipc call lockScreen lock";
        resumeCommand = "hyprctl dispatch dpms on";
      }
      {
        name = "AC: screen off + lock at 10 min";
        timeout = 600;
        command = "cat /sys/class/power_supply/BAT*/status 2>/dev/null | grep -q Discharging || (hyprctl dispatch dpms off && noctalia-shell ipc call lockScreen lock)";
        resumeCommand = "hyprctl dispatch dpms on";
      }
    ];
  };
}
