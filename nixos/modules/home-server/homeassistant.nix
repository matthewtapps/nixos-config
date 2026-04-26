{
  config,
  pkgs,
  lib,
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

  systemd.services.home-assistant.serviceConfig.ExecStartPre =
    let
      script = pkgs.writeShellScript "setup-ha-secrets" ''
        mkdir -p /var/lib/hass
        cat > /var/lib/hass/secrets.yaml <<EOF
        google_project_id: $(cat ${config.sops.secrets.google_project_id.path})
        google_client_email: $(cat ${config.sops.secrets.google_client_email.path})
        google_private_key: |
        $(cat ${config.sops.secrets.google_private_key.path} | sed 's/^/  /')
        EOF
        chown hass:hass /var/lib/hass/secrets.yaml
        chmod 600 /var/lib/hass/secrets.yaml
      '';
    in
    [ "+${script}" ];

  services.home-assistant = {
    enable = true;

    customComponents = [
      (pkgs.callPackage ../../packages/hass-template-climate.nix { })
    ];

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
          scan_interval = 5;
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

      climate = [
        {
          platform = "climate_template";
          name = "Living Room AC";
          unique_id = "living_room_ac";
          min_temp = 17;
          max_temp = 31;
          temp_step = 1;
          precision = 1;
          modes = [
            "off"
            "heat_cool"
            "cool"
            "heat"
            "dry"
            "fan_only"
          ];
          fan_modes = [
            "auto"
            "low"
            "medium"
            "high"
            "max"
            "econo"
            "turbo"
          ];
          swing_modes = [
            "auto"
            "highest"
            "high"
            "middle"
            "low"
            "lowest"
            "off"
          ];

          current_temperature_template = "{{ states('sensor.ac_room_temperature') | float(0) }}";
          current_humidity_template = "{{ states('sensor.ac_room_humidity') | float(0) }}";
          target_temperature_template = "{{ states('sensor.ac_current_temperature') | float(24) }}";

          hvac_mode_template = ''
            {% set ac = state_attr('sensor.ac_status', 'ac') %}
            {% if ac is none or not ac.power %}off
            {% else %}
              {% set m = ac.mode | int(-1) %}
              {% if m == 0 %}heat_cool
              {% elif m == 1 %}cool
              {% elif m == 2 %}dry
              {% elif m == 3 %}fan_only
              {% elif m == 4 %}heat
              {% else %}off{% endif %}
            {% endif %}
          '';

          fan_mode_template = "{{ states('sensor.ac_current_fan') }}";

          set_temperature = [
            {
              service = "rest_command.ac_control";
              data.payload = ''{"temperature": {{ temperature | int }}}'';
            }
          ];

          set_hvac_mode = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% if hvac_mode == 'off' %}
                  {"power": false}
                {% else %}
                  {% set mode_map = {'heat_cool': 0, 'cool': 1, 'dry': 2, 'fan_only': 3, 'heat': 4} %}
                  {"power": true, "mode": {{ mode_map[hvac_mode] }}}
                {% endif %}
              '';
            }
          ];

          set_fan_mode = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% set fan_map = {'auto': 0, 'low': 1, 'medium': 2, 'high': 3, 'max': 4, 'econo': 6, 'turbo': 8} %}
                {"fan": {{ fan_map[fan_mode] }}}
              '';
            }
          ];

          set_swing_mode = [
            {
              service = "rest_command.ac_control";
              data.payload = ''
                {% set swing_map = {'auto': 0, 'highest': 1, 'high': 2, 'middle': 3, 'low': 4, 'lowest': 5, 'off': 6} %}
                {"swing_v": {{ swing_map[swing_mode] }}}
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
          - type: thermostat
            entity: climate.living_room_ac
            name: AC

          - type: entities
            title: Room Conditions
            entities:
              - entity: sensor.ac_room_temperature
                name: Temperature
              - entity: sensor.ac_room_humidity
                name: Humidity

          - type: entities
            title: Reported AC State
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
