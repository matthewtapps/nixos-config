{ pkgs, ... }:

{
  xdg.configFile."MangoHud/MangoHud.conf".text = ''
    # GPU and CPU monitoring
    gpu_stats
    gpu_temp
    gpu_power
    gpu_load_change
    cpu_stats
    cpu_temp
    cpu_power
    cpu_load_change

    # Performance metrics
    fps
    frametime
    frame_timing=1

    # Display settings
    position=top-left
    font_size=16
    background_alpha=0.4
    round_corners=8

    # Toggle with Shift+F12 (can be changed)
    toggle_hud=Shift_L+F12

    # Log performance data (optional)
    # output_folder=/home/matt/mangohud-logs
    # log_duration=30
  '';

  # Optional: Add some monitoring tools to home packages
  home.packages = with pkgs; [
    goverlay # GUI for configuring MangoHud
    mangohud
  ];
}
