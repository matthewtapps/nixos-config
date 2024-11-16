_: {
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      ################
      ### MONITORS ###
      ################

      $mon1=desc:Samsung Electric Company SAMSUNG 0x01000E00

      monitor=$mon1,2560x1440@59.95Hz,0x0,2

      ###################
      ### MY PROGRAMS ###
      ###################

      # See https://wiki.hyprland.org/Configuring/Keywords/

      # Set programs that you use
      $terminal = kitty
      $fileManager = thunar
      $menu = rofi -show drun

      #################
      ### AUTOSTART ###
      #################

      # Autostart necessary processes (like notifications daemons, status bars, etc.)
      # Or execute your favorite apps at launch like this:

      exec-once = hyprpaper & ags
      exec-once = wl-paste -p -t text --watch clipman store -P --histpath="~/.local/share/clipman-primary.json"

      #############################
      ### ENVIRONMENT VARIABLES ###
      #############################

      # See https://wiki.hyprland.org/Configuring/Environment-variables/
      env = GTK_THEME,Everforest-Dark-BL-LB
      env = QT_QPA_PLATFORM,wayland;xcb
      env = GDK_BACKEND,wayland,ags,x11,*
      env = ELECTRON_OZONE_PLATFORM_HINT,auto
      env = XDG_CURRENT_DESKTOP,Hyprland
      env = XDG_SESSION_TYPE,wayland
      env = XDG_SESSION_DESKTOP,Hyprland
      env = LIBVA_DRIVER_NAME,nvidia
      env = GBM_BACKEND,nvidia-drm
      env = __GLX_VENDOR_LIBRARY_NAME,nvidia
      env = NVD_BACKEND,direct
      env = HYPRCURSOR_THEME,Simp1e Cursors
      env = HYPRCURSOR_SIZE,16
      env = XCURSOR_SIZE,16

      #####################
      ### LOOK AND FEEL ###
      #####################

      # Refer to https://wiki.hyprland.org/Configuring/Variables/

      # https://wiki.hyprland.org/Configuring/Variables/#general
      general { 
          gaps_in = 10
          gaps_out = 20

          border_size = 1

          # https://wiki.hyprland.org/Configuring/Variables/#variable-types for info about colors
          col.active_border = rgb(a9b665)
          col.inactive_border = rgb(665c54)

          # Set to true enable resizing windows by clicking and dragging on borders and gaps
          resize_on_border = false 

          # Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
          allow_tearing = false

          layout = dwindle
      }

      # https://wiki.hyprland.org/Configuring/Variables/#decoration
      decoration {
          rounding = 10

          # Change transparency of focused and unfocused windows
          active_opacity = 1.0
          inactive_opacity = 0.96
      }

      # See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
      dwindle {
          pseudotile = true # Master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
          preserve_split = true # You probably want this
      }

      # https://wiki.hyprland.org/Configuring/Variables/#misc
      misc {
          force_default_wallpaper = 0 # Set to 0 or 1 to disable the anime mascot wallpapers
          disable_hyprland_logo = true # If true disables the random hyprland logo / anime girl background. :(
          disable_splash_rendering = true
          focus_on_activate = true
          middle_click_paste = false
      }

      cursor {
              no_hardware_cursors = true
          }

      #############
      ### INPUT ###
      #############

      # https://wiki.hyprland.org/Configuring/Variables/#input
      input {
          kb_layout = us
          kb_variant =
          kb_model =
          kb_options =
          kb_rules =

          follow_mouse = 1

          sensitivity = -0.5 # -1.0 - 1.0, 0 means no modification.

          touchpad {
              natural_scroll = false
          }
          accel_profile = flat
      }

      ####################
      ### KEYBINDINGSS ###
      ####################

      # See https://wiki.hyprland.org/Configuring/Keywords/
      $mainMod = LALT # Sets "Windows" key as main modifier

      # Example binds, see https://wiki.hyprland.org/Configuring/Binds/ for more
      bind = $mainMod, RETURN, exec, $terminal
      bind = $mainMod, Q, killactive,
      bind = $mainMod, M, exit,
      bind = $mainMod, E, exec, $fileManager
      bind = $mainMod SHIFT, SPACE, togglefloating,
      bind = $mainMod, SPACE, exec, $menu
      bind = $mainMod, P, pseudo, # dwindle
      bind = $mainMod, V, togglesplit, # dwindle
      bind = SUPER, L, exec, hyprlock
      bind = SUPER SHIFT, S, exec, hyprshot -m region
      bind = $mainMod SHIFT, R, exec, pkill ags && hyprctl dispatch exec ags
      bind = $mainMod, X, fullscreen

      # Sound
      bindle= , xf86audioraisevolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +1%
      bindle= , xf86audiolowervolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -1%
      bindle= , xf86audiomute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindle= , xf86audioplay, exec, playerctl play-pause
      bindle= , XF86audionext, exec, playerctl next
      bindle= , xf86audioprevious, exec, playerctl previous

      # Move focus with mainMod + arrow keys
      bind = $mainMod, left, movefocus, l
      bind = $mainMod, right, movefocus, r
      bind = $mainMod, up, movefocus, u
      bind = $mainMod, down, movefocus, d

      bind = $mainMod, h, movefocus, l
      bind = $mainMod, l, movefocus, r
      bind = $mainMod, k, movefocus, u
      bind = $mainMod, j, movefocus, d

      bind = $mainMod SHIFT, h, movewindow, l
      bind = $mainMod SHIFT, l, movewindow, r
      bind = $mainMod SHIFT, k, movewindow, u
      bind = $mainMod SHIFT, j, movewindow, d

      bind = $mainMod, a, movecurrentworkspacetomonitor, +1
      bind = $mainMod, f, movecurrentworkspacetomonitor, -1

      # Switch workspaces with mainMod + [0-9]
      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9

      # Move active window to a workspace with mainMod + SHIFT + [0-9]
      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10

      # Example special workspace (scratchpad)
      bind = $mainMod, S, togglespecialworkspace, magic
      bind = $mainMod SHIFT, S, movetoworkspace, special:magic

      # Scroll through existing workspaces with mainMod + scroll
      bind = $mainMod, mouse_down, workspace, e+1
      bind = $mainMod, mouse_up, workspace, e-1

      # Move/resize windows with mainMod + LMB/RMB and dragging
      bindm = $mainMod, mouse:272, movewindow
      bindm = $mainMod, mouse:273, resizewindow

      ##############################
      ### WINDOWS AND WORKSPACES ###
      ##############################

      # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
      # See https://wiki.hyprland.org/Configuring/Workspace-Rules/ for workspace rules

      workspace=1, monitor:$mon1, default:true
      workspace=2, monitor:$mon1,
      workspace=3, monitor:$mon1,
      workspace=4, monitor:$mon1,
      workspace=5, monitor:$mon2, default:true, on-created-empty: chrome
      workspace=6, monitor:$mon2,
      workspace=7, monitor:$mon2,
      workspace=8, monitor:$mon1,
      workspace=9, monitor:$mon1, on-created-empty: kitty spotify_player

      # Example windowrule v1
      windowrule = float,title:^(Volume Control)$

      #Thunar
      windowrule = float,title:Thunar
      windowrule = size 1100 700,title:Thunar
      windowrule = move 100%-w-100 100%-w-100,title:Thunar

      #Overskride
      windowrule = float,title:overskride
      windowrule = size 1000 1200,title:overskride
      windowrule = move 4% 10%,title:overskride


      # Example windowrule v2
      # windowrulev2 = float,class:^(kitty)$,title:^(kitty)$

      windowrulev2 = suppressevent maximize, class:.* # You'll probably like this.

      render {
        explicit_sync = 2
        explicit_sync_kms = 0
      }

      opengl {
        nvidia_anti_flicker = 0
        force_introspection = 2
      }

      misc {
        vfr = 0
      }

      debug {
        damage_tracking = 0
      }
    '';
  };
}
