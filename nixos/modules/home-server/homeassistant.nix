{
  config,
  pkgs,
  ...
}:

{
  sops.secrets = {
    google_project_id = {
      sopsFile = ../../../secrets/kruppe.yaml;
    };
    google_client_email = {
      sopsFile = ../../../secrets/kruppe.yaml;
    };
    google_private_key = {
      sopsFile = ../../../secrets/kruppe.yaml;
    };
  };

  systemd.services.home-assistant.preStart =
    let
      secretsFile = pkgs.writeShellScript "generate-ha-secrets" ''
        cat > /var/lib/home-assistant/secrets.yaml <<EOF
        google_project_id: $(cat ${config.sops.secrets.google_project_id.path})
        google_client_email: $(cat ${config.sops.secrets.google_client_email.path})
        google_private_key: |
          $(cat ${config.sops.secrets.google_private_key.path} | sed 's/^/  /')
        EOF
        chown hass:hass /var/lib/home-assistant/secrets.yaml
        chmod 600 /var/lib/home-assistant/secrets.yaml
      '';
    in
    "${secretsFile}";

  services.home-assistant = {
    enable = true;

    config = {
      homeassistant = {
        name = "Home";
        latitude = -37.8136;
        longitude = 144.9631;
        elevation = 31;
        unit_system = "metric";
        time_zone = "Australia/Melbourne";
        temperature_unit = "C";
        external_url = "https://mattys.cloud";
      };

      google_assistant = {
        project_id = "!secret google_project_id";
        service_account = {
          client_email = "!secret google_client_email";
          private_key = "!secret google_private_key";
        };
        report_state = true;
        exposed_domains = [
          "climate"
          "fan"
          "light"
          "switch"
        ];
      };

      default_config = { };

      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
          "::1"
        ];
        server_host = "127.0.0.1";
        server_port = 8123;
      };

      logger = {
        default = "info";
        logs."homeassistant.components.rest" = "debug";
      };

      recorder.purge_keep_days = 7;

      sensor = [
        {
          platform = "rest";
          name = "AC Status";
          resource = "http://192.168.0.206/api/status";
          json_attributes = [
            "sensor"
            "ac"
          ];
          value_template = "{{ value_json.sensor.temperature }}";
          unit_of_measurement = "°C";
          scan_interval = 15;
          timeout = 10;
          verify_ssl = false;
          force_update = true;
        }
      ];

      template = [
        {
          sensor = [
            {
              name = "AC Room Temperature";
              state = "{{ state_attr('sensor.ac_status', 'sensor')['temperature'] if state_attr('sensor.ac_status', 'sensor') else 0 }}";
              unit_of_measurement = "°C";
              device_class = "temperature";
              state_class = "measurement";
            }
            {
              name = "AC Room Humidity";
              state = "{{ state_attr('sensor.ac_status', 'sensor')['humidity'] if state_attr('sensor.ac_status', 'sensor') else 0 }}";
              unit_of_measurement = "%";
              device_class = "humidity";
              state_class = "measurement";
            }
            {
              name = "AC Current Temperature";
              state = "{{ state_attr('sensor.ac_status', 'ac')['temperature'] if state_attr('sensor.ac_status', 'ac') else 24 }}";
              unit_of_measurement = "°C";
            }
            {
              name = "AC Current Mode";
              state = ''
                {% set ac = state_attr('sensor.ac_status', 'ac') %}
                {% if ac %}
                  {% set mode = ac['mode'] | int(-1) %}
                  {% if mode == 0 %}auto
                  {% elif mode == 1 %}cool
                  {% elif mode == 2 %}dry
                  {% elif mode == 3 %}fan_only
                  {% elif mode == 4 %}heat
                  {% else %}unknown{% endif %}
                {% else %}unknown{% endif %}
              '';
            }
            {
              name = "AC Current Fan";
              state = ''
                {% set ac = state_attr('sensor.ac_status', 'ac') %}
                {% if ac %}
                  {% set fan = ac['fan'] | int(-1) %}
                  {% if fan == 0 %}auto
                  {% elif fan == 1 %}low
                  {% elif fan == 2 %}medium
                  {% elif fan == 3 %}high
                  {% elif fan == 4 %}max
                  {% elif fan == 6 %}econo
                  {% elif fan == 8 %}turbo
                  {% else %}unknown{% endif %}
                {% else %}unknown{% endif %}
              '';
            }
          ];
          binary_sensor = [
            {
              name = "AC Power";
              state = "{{ state_attr('sensor.ac_status', 'ac')['power'] if state_attr('sensor.ac_status', 'ac') else false }}";
              device_class = "power";
            }
          ];
        }
      ];

      rest_command.ac_control = {
        url = "http://192.168.0.206/api/control";
        method = "POST";
        content_type = "application/json";
        payload = ''{{ payload }}'';
      };

      input_boolean.ac_power = {
        name = "AC Power";
        initial = false;
        icon = "mdi:power";
      };

      input_number.ac_temperature = {
        name = "Target Temperature";
        min = 17;
        max = 31;
        step = 1;
        mode = "box";
        initial = 24;
        unit_of_measurement = "°C";
        icon = "mdi:thermometer";
      };

      input_select = {
        ac_mode = {
          name = "Mode";
          options = [
            "auto"
            "cool"
            "dry"
            "fan_only"
            "heat"
          ];
          initial = "auto";
          icon = "mdi:air-conditioner";
        };
        ac_fan = {
          name = "Fan Speed";
          options = [
            "auto"
            "low"
            "medium"
            "high"
            "max"
            "econo"
            "turbo"
          ];
          initial = "auto";
          icon = "mdi:fan";
        };
        ac_swing_vertical = {
          name = "Vertical Swing";
          options = [
            "auto"
            "highest"
            "high"
            "middle"
            "low"
            "lowest"
            "off"
          ];
          initial = "auto";
          icon = "mdi:arrow-up-down";
        };
        ac_swing_horizontal = {
          name = "Horizontal Swing";
          options = [
            "auto"
            "left_max"
            "left"
            "left_right"
            "middle"
            "right_left"
            "right"
            "right_max"
            "off"
          ];
          initial = "auto";
          icon = "mdi:arrow-left-right";
        };
      };

      automation = [
        {
          id = "ac_power_changed";
          alias = "AC Power Changed";
          trigger = [
            {
              platform = "state";
              entity_id = "input_boolean.ac_power";
            }
          ];
          action = [
            {
              service = "rest_command.ac_control";
              data.payload = ''{"power": {{ "true" if trigger.to_state.state == "on" else "false" }}}'';
            }
          ];
        }
        {
          id = "ac_temperature_changed";
          alias = "AC Temperature Changed";
          trigger = [
            {
              platform = "state";
              entity_id = "input_number.ac_temperature";
            }
          ];
          action = [
            {
              service = "rest_command.ac_control";
              data.payload = ''{"temperature": {{ trigger.to_state.state | int }}}'';
            }
          ];
        }
        {
          id = "ac_mode_changed";
          alias = "AC Mode Changed";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.ac_mode";
            }
          ];
          action = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% set mode_map = {'auto': 0, 'cool': 1, 'dry': 2, 'fan_only': 3, 'heat': 4} %}
                {"mode": {{ mode_map[trigger.to_state.state] }}}
              '';
            }
          ];
        }
        {
          id = "ac_fan_changed";
          alias = "AC Fan Changed";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.ac_fan";
            }
          ];
          action = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% set fan_map = {'auto': 0, 'low': 1, 'medium': 2, 'high': 3, 'max': 4, 'econo': 6, 'turbo': 8} %}
                {"fan": {{ fan_map[trigger.to_state.state] }}}
              '';
            }
          ];
        }
        {
          id = "ac_swing_v_changed";
          alias = "AC Vertical Swing Changed";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.ac_swing_vertical";
            }
          ];
          action = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% set swing_map = {'auto': 0, 'highest': 1, 'high': 2, 'middle': 3, 'low': 4, 'lowest': 5, 'off': 6} %}
                {"swing_v": {{ swing_map[trigger.to_state.state] }}}
              '';
            }
          ];
        }
        {
          id = "ac_swing_h_changed";
          alias = "AC Horizontal Swing Changed";
          trigger = [
            {
              platform = "state";
              entity_id = "input_select.ac_swing_horizontal";
            }
          ];
          action = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% set swing_map = {'auto': 0, 'left_max': 1, 'left': 2, 'left_right': 3, 'middle': 4, 'right_left': 5, 'right': 6, 'right_max': 7, 'off': 8} %}
                {"swing_h": {{ swing_map[trigger.to_state.state] }}}
              '';
            }
          ];
        }
      ];

      lovelace = {
        mode = "yaml";
        resources = [ ];
        dashboards.ac-control = {
          mode = "yaml";
          title = "AC Control";
          icon = "mdi:air-conditioner";
          show_in_sidebar = true;
          filename = "ac_dashboard.yaml";
        };
      };
    };

    extraPackages =
      python3Packages: with python3Packages; [
        requests
        aiohttp
        jinja2
        voluptuous
        pyyaml
      ];

    openFirewall = false;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/home-assistant 0755 hass hass -"
    "f /var/lib/home-assistant/ac_dashboard.yaml 0644 hass hass -"
  ];

  environment.etc."home-assistant/ac_dashboard.yaml".text = ''
    title: AC Control
    views:
      - title: Control
        cards:
          - type: entities
            title: Room Conditions (Read-Only)
            entities:
              - entity: sensor.ac_room_temperature
                name: Temperature
              - entity: sensor.ac_room_humidity
                name: Humidity
          
          - type: entities
            title: AC Controls (Change These)
            entities:
              - entity: input_boolean.ac_power
                name: Power
              - entity: input_number.ac_temperature
                name: Target Temperature
              - entity: input_select.ac_mode
                name: Mode
              - entity: input_select.ac_fan
                name: Fan Speed
              - entity: input_select.ac_swing_vertical
                name: Vertical Swing
              - entity: input_select.ac_swing_horizontal
                name: Horizontal Swing
          
          - type: entities
            title: Current AC State (Read-Only)
            entities:
              - entity: binary_sensor.ac_power
                name: Power State
              - entity: sensor.ac_current_temperature
                name: Target Temp
              - entity: sensor.ac_current_mode
                name: Mode
              - entity: sensor.ac_current_fan
                name: Fan
  '';

  environment.systemPackages = with pkgs; [
    (writeShellScriptBin "ha-logs" "journalctl -u home-assistant -f")
    (writeShellScriptBin "ha-restart" "systemctl restart home-assistant")
    (writeShellScriptBin "ha-status" "systemctl status home-assistant")
  ];
}
