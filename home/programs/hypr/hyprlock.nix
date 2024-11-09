_:
{
  programs.hyprlock = {
    enable = true;
    extraConfig = ''
$hypr = ~/.config/hypr
$mon1 = DP-3

# GENERAL
general {
  no_fade_in = false
  grace = 0
  disable_loading_bar = false
  hide_cursor = true
  ignore_empty_input = true
  text_trim = true
}

#BACKGROUND
background {
    monitor = 
    path = $hypr/bg3.jpg
    blur_passes = 2
    contrast = 0.8916
    brightness = 0.7172
    vibrancy = 0.1696
    vibrancy_darkness = 0
}

# TIME HR
label {
    monitor = $mon1
    text = cmd[update:1000] echo -e "$(date +"%H")"
    color = rgba(255, 255, 255, 1)
    shadow_pass = 2
    shadow_size = 3
    shadow_color = rgb(0,0,0)
    shadow_boost = 1.2
    font_size = 150
    font_family = CommitMono Nerd Font
    position = 0, -250
    halign = center
    valign = top
}

# TIME
label {
    monitor = $mon1
    text = cmd[update:1000] echo -e "$(date +"%M")"
#    color = 0xff$color0
    color = rgba(255, 255, 255, 1)
    font_size = 150
#    font_family = CommitMono Nerd Font ExtraBold
    font_family = AlfaSlabOne
    position = 0, -420
    halign = center
    valign = top
}

# DATE
label {
    monitor = $mon1
    text = cmd[update:1000] echo -e "$(date +"%d %b %A")"
    color = rgba(255, 255, 255, 1)
    font_size = 14
    font_family = CommitMono Nerd Font
    position = 0, -130
    halign = center
    valign = center
}

# # LOCATION & WEATHER 
# label {
#     monitor =
#     text = cmd[update:1000] echo "$(bash ~/.config/hypr/bin/location.sh) $(bash ~/.config/hypr/bin/weather.sh)"
#     color = rgba(255, 255, 255, 1)
#     font_size = 10
#     font_family = CommitMono Nerd Font
#     position = 0, 465
#     halign = center
#     valign = center
# }


# Music
image {
    monitor = $mon1
    path = 
    size = 60 # lesser side if not 1:1 ratio
    rounding = 5 # negative values mean circle
    border_size = 0
    rotate = 0 # degrees, counter-clockwise
    reload_time = 2
    reload_cmd = ~/.config/hypr/bin/playerctlock.sh --arturl
    position = -150, -300
    halign = center
    valign = center
    opacity=0.5
}

# PLAYER TITTLE
label {
    monitor = $mon1
#    text = cmd[update:1000] echo "$(playerctl metadata --format "{{ xesam:title }}" 2>/dev/null | cut -c1-25)"
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/playerctlock.sh --title)"
    color = rgba(255, 255, 255, 0.8)
    font_size = 12
    font_family = CommitMono Nerd Font ExtraBold
    position = 880, -290
    halign = left
    valign = center
}

# PLAYER Length
label {
    monitor = $mon1
#    text= cmd[update:1000] echo "$(( $(playerctl metadata --format "{{ mpris:length }}" 2>/dev/null) / 60000000 ))m"
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/playerctlock.sh --length) "
    color = rgba(255, 255, 255, 1)
    font_size = 11
    font_family = CommitMono Nerd Font 
    position = -730, -310
    halign = right
    valign = center
}

# PLAYER STATUS
label {
    monitor = $mon1
#    text= cmd[update:1000] echo "$(( $(playerctl metadata --format "{{ mpris:length }}" 2>/dev/null) / 60000000 ))m"
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/playerctlock.sh --status)"
    color = rgba(255, 255, 255, 1)
    font_size = 14
    font_family = CommitMono Nerd Font 
    position = -740, -290
    halign = right
    valign = center
}
# PLAYER SOURCE
label {
    monitor = $mon1
#    text= cmd[update:1000] echo "$(playerctl metadata --format "{{ mpris:trackid }}" 2>/dev/null | grep -Eo "chromium|firefox|spotify")"
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/playerctlock.sh --source)"
    color = rgba(255, 255, 255, 0.6)
    font_size = 10
    font_family = CommitMono Nerd Font 
    position = -740, -330
    halign = right
    valign = center
}

# PLAYER ALBUM
label {
    monitor = $mon1
#    text= cmd[update:1000] echo "$(~/.config/hypr/bin/album.sh)"
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/playerctlock.sh --album)"
    color = rgba(255, 255, 255, 1)
    font_size = 10 
    font_family = CommitMono Nerd Font
    position = 880, -330
    halign = left
    valign = center
}
# PLAYER Artist
label {
    monitor = $mon1
#    text = cmd[update:1000] echo "$(playerctl metadata --format "{{ xesam:artist }}" 2>/dev/null | cut -c1-30)"
    text = cmd[update:1000] echo "$(~/.config/hypr/bin/playerctlock.sh --artist)"
    color = rgba(255, 255, 255, 0.8)
    font_size = 10
    font_family = CommitMono Nerd Font ExtraBold
    position = 880, -310
    halign = left
    valign = center
}

# INPUT FIELD
input-field {
    monitor = $mon1
    size = 250, 60
    outline_thickness = 0
    outer_color = rgba(0, 0, 0, 1)
    dots_size = 0.1 # Scale of input-field height, 0.2 - 0.8
    dots_spacing = 1 # Scale of dots' absolute size, 0.0 - 1.0
    dots_center = true
    inner_color = rgba(0, 0, 0, 1)
    font_color = rgba(200, 200, 200, 1)
    fade_on_empty = false
    font_family = CommitMono Nerd Font
    placeholder_text = <span foreground="##A7C080">  $USER</span>
    hide_input = false
    position = 0, -470
    halign = center
    valign = center
    zindex = 10
}
  '';
  };
}
