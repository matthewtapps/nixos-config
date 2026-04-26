{
  buildHomeAssistantComponent,
  fetchFromGitHub,
  lib,
}:

buildHomeAssistantComponent rec {
  owner = "jcwillox";
  domain = "climate_template";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "jcwillox";
    repo = "hass-template-climate";
    rev = "v${version}";
    hash = "sha256-hWYYY0kt/RfdCyNR3skiYOyyQ7KF35Xbh8NczIDzr58=";
  };

  meta = {
    description = "Template-based climate entity for Home Assistant";
    homepage = "https://github.com/jcwillox/hass-template-climate";
    license = lib.licenses.mit;
  };
}
