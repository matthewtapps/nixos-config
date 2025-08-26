{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.home-assistant-ac;
  
  # Convert YAML config to Nix format for Home Assistant
  haConfig = {
    homeassistant = {
      name = "Home";
      latitude = -37.8136;  # Melbourne
      longitude = 144.9631;
      elevation = 31;
      unit_system = "metric";
      time_zone = "Australia/Melbourne";
      temperature_unit = "C";
    };

    # Enable default integrations
    default_config = {};
    
    # HTTP configuration
    http = {
      use_x_forwarded_for = true;
      trusted_proxies = [ "127.0.0.1" "::1" ];
    };

    # Logger
    logger.default = "info";
    
    # Recorder - limit database size for testing
    recorder.purge_keep_days = 7;

    # ESP32 AC Controller sensors
    sensor = [
      {
        platform = "rest";
        name = "Room Temperature";
        resource = "http://${cfg.esp32Address}/api/status";
        value_template = "{{ value_json.sensor.temperature }}";
        unit_of_measurement = "°C";
        device_class = "temperature";
        scan_interval = 30;
      }
      {
        platform = "rest";
        name = "Room Humidity";
        resource = "http://${cfg.esp32Address}/api/status";
        value_template = "{{ value_json.sensor.humidity }}";
        unit_of_measurement = "%";
        device_class = "humidity";
        scan_interval = 30;
      }
    ];

    # REST commands for AC control
    rest_command.set_ac_state = {
      url = "http://${cfg.esp32Address}/control";
      method = "GET";
      content_type = "application/x-www-form-urlencoded";
      payload = "power={{ power }}&temp={{ temp }}&mode={{ mode }}&fan={{ fan }}&swing_v={{ swing_v }}&swing_h={{ swing_h }}&clean={{ clean }}";
    };

    # Climate entity
    climate = [
      {
        platform = "generic_thermostat";
        name = "Living Room AC";
        unique_id = "esp32_ac_controller";
        heater = "input_boolean.ac_dummy_heater";
        target_sensor = "sensor.room_temperature";
        min_temp = 17;
        max_temp = 31;
        ac_mode = true;
        cold_tolerance = 0.5;
        hot_tolerance = 0.5;
        min_cycle_duration.minutes = 5;
        keep_alive.minutes = 3;
        initial_hvac_mode = "off";
      }
    ];

    # Helper entities
    input_boolean.ac_dummy_heater = {
      name = "AC Dummy Heater";
      initial = false;
    };

    input_select = {
      ac_mode = {
        name = "AC Mode";
        options = [ "off" "auto" "cool" "heat" "dry" "fan_only" ];
        initial = "off";
        icon = "mdi:air-conditioner";
      };
      ac_fan_speed = {
        name = "AC Fan Speed";
        options = [ "auto" "low" "medium" "high" "turbo" "eco" ];
        initial = "auto";
        icon = "mdi:fan";
      };
      ac_swing_vertical = {
        name = "AC Vertical Swing";
        options = [ "auto" "highest" "high" "middle" "low" "lowest" "off" ];
        initial = "auto";
        icon = "mdi:arrow-up-down";
      };
      ac_swing_horizontal = {
        name = "AC Horizontal Swing";
        options = [ "auto" "wide" "middle" "off" ];
        initial = "auto";
        icon = "mdi:arrow-left-right";
      };
    };

    input_number.ac_target_temperature = {
      name = "AC Target Temperature";
      min = 17;
      max = 31;
      step = 1;
      initial = 24;
      unit_of_measurement = "°C";
      icon = "mdi:thermometer";
    };

    # Automations
    automation = [
      {
        id = "ac_control_sync";
        alias = "AC Control Sync";
        description = "Synchronize all AC controls to ESP32";
        trigger = [
          {
            platform = "state";
            entity_id = [
              "input_select.ac_mode"
              "input_select.ac_fan_speed"
              "input_number.ac_target_temperature"
              "input_select.ac_swing_vertical"
              "input_select.ac_swing_horizontal"
            ];
          }
        ];
        action = [
          {
            service = "rest_command.set_ac_state";
            data = {
              power = "{% if states('input_select.ac_mode') == 'off' %}false{% else %}true{% endif %}";
              temp = "{{ states('input_number.ac_target_temperature') | int }}";
              mode = ''
                {% set mode_map = {
                  'auto': 0,
                  'cool': 1,
                  'dry': 2,
                  'fan_only': 3,
                  'heat': 4,
                  'off': 0
                } %}
                {{ mode_map[states('input_select.ac_mode')] }}'';
              fan = ''
                {% set fan_map = {
                  'auto': 0,
                  'low': 1,
                  'medium': 2,
                  'high': 3,
                  'turbo': 8,
                  'eco': 6
                } %}
                {{ fan_map[states('input_select.ac_fan_speed')] }}'';
              swing_v = ''
                {% set swing_map = {
                  'auto': 0,
                  'highest': 1,
                  'high': 2,
                  'middle': 3,
                  'low': 4,
                  'lowest': 5,
                  'off': 6
                } %}
                {{ swing_map[states('input_select.ac_swing_vertical')] }}'';
              swing_h = ''
                {% set swing_map = {
                  'auto': 0,
                  'wide': 3,
                  'middle': 4,
                  'off': 8
                } %}
                {{ swing_map[states('input_select.ac_swing_horizontal')] }}'';
              clean = "false";
            };
          }
        ];
      }
      {
        id = "smart_heating";
        alias = "Smart Heating";
        trigger = [{
          platform = "numeric_state";
          entity_id = "sensor.room_temperature";
          below = "input_number.ac_target_temperature";
          for = "00:02:00";
        }];
        condition = [{
          condition = "state";
          entity_id = "input_select.ac_mode";
          state = "heat";
        }];
        action = [{
          service = "input_select.select_option";
          data = {
            entity_id = "input_select.ac_fan_speed";
            option = "medium";
          };
        }];
      }
      {
        id = "smart_cooling";
        alias = "Smart Cooling";
        trigger = [{
          platform = "numeric_state";
          entity_id = "sensor.room_temperature";
          above = "input_number.ac_target_temperature";
          for = "00:02:00";
        }];
        condition = [{
          condition = "state";
          entity_id = "input_select.ac_mode";
          state = "cool";
        }];
        action = [{
          service = "input_select.select_option";
          data = {
            entity_id = "input_select.ac_fan_speed";
            option = "high";
          };
        }];
      }
      {
        id = "night_energy_saver";
        alias = "Night Energy Saver";
        trigger = [{
          platform = "time";
          at = "22:00:00";
        }];
        action = [
          {
            service = "input_number.set_value";
            data = {
              entity_id = "input_number.ac_target_temperature";
              value = ''
                {% if states('input_select.ac_mode') == 'cool' %}
                  26
                {% elif states('input_select.ac_mode') == 'heat' %}
                  20
                {% else %}
                  {{ states('input_number.ac_target_temperature') }}
                {% endif %}'';
            };
          }
          {
            service = "input_select.select_option";
            data = {
              entity_id = "input_select.ac_fan_speed";
              option = "low";
            };
          }
        ];
      }
      {
        id = "auto_dehumidify";
        alias = "Auto Dehumidify";
        trigger = [{
          platform = "numeric_state";
          entity_id = "sensor.room_humidity";
          above = 70;
        }];
        action = [{
          service = "input_select.select_option";
          data = {
            entity_id = "input_select.ac_mode";
            option = "dry";
          };
        }];
      }
    ];

    # Scripts for common operations
    script = {
      ac_quick_cool = {
        alias = "Quick Cool";
        icon = "mdi:snowflake";
        sequence = [
          {
            service = "input_select.select_option";
            data = {
              entity_id = "input_select.ac_mode";
              option = "cool";
            };
          }
          {
            service = "input_number.set_value";
            data = {
              entity_id = "input_number.ac_target_temperature";
              value = 20;
            };
          }
          {
            service = "input_select.select_option";
            data = {
              entity_id = "input_select.ac_fan_speed";
              option = "turbo";
            };
          }
        ];
      };
      ac_quick_heat = {
        alias = "Quick Heat";
        icon = "mdi:fire";
        sequence = [
          {
            service = "input_select.select_option";
            data = {
              entity_id = "input_select.ac_mode";
              option = "heat";
            };
          }
          {
            service = "input_number.set_value";
            data = {
              entity_id = "input_number.ac_target_temperature";
              value = 26;
            };
          }
          {
            service = "input_select.select_option";
            data = {
              entity_id = "input_select.ac_fan_speed";
              option = "turbo";
            };
          }
        ];
      };
      ac_eco_mode = {
        alias = "Eco Mode";
        icon = "mdi:leaf";
        sequence = [
          {
            service = "input_select.select_option";
            data = {
              entity_id = "input_select.ac_fan_speed";
              option = "eco";
            };
          }
          {
            service = "input_number.set_value";
            data = {
              entity_id = "input_number.ac_target_temperature";
              value = ''
                {% if states('input_select.ac_mode') == 'cool' %}
                  25
                {% elif states('input_select.ac_mode') == 'heat' %}
                  21
                {% else %}
                  23
                {% endif %}'';
            };
          }
        ];
      };
    };
  };
  
in {
  options = {
    services.home-assistant-ac = {
      enable = mkEnableOption "Home Assistant with ESP32 AC Controller";
      
      esp32Address = mkOption {
        type = types.str;
        default = "192.168.0.206";
        description = "IP address of your ESP32 device";
      };
      
      port = mkOption {
        type = types.port;
        default = 8123;
        description = "Port for Home Assistant web interface";
      };
      
      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open firewall for Home Assistant";
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Home Assistant service with our configuration
    services.home-assistant = {
      enable = true;
      
      # Apply our configuration
      config = haConfig;
      
      # Make component packages available
      extraPackages = python3Packages: with python3Packages; [
        # Required for REST sensors
        requests
        aiohttp
        
        # For various integrations
        jinja2
        voluptuous
        pyyaml
      ];
      
      # Open ports for the web interface
      openFirewall = cfg.openFirewall;
    };

    # Open firewall ports
    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    # Add convenience aliases
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "ha-logs" ''
        journalctl -u home-assistant -f
      '')
      (writeShellScriptBin "ha-restart" ''
        systemctl restart home-assistant
      '')
      (writeShellScriptBin "ha-status" ''
        systemctl status home-assistant
      '')
    ];
  };
}
