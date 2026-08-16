{
  buildHomeAssistantComponent,
  fetchFromGitHub,
  lib,
}:

buildHomeAssistantComponent rec {
  owner = "jcwillox";
  domain = "climate_template";
  version = "1.4.0";

  src = fetchFromGitHub {
    owner = "jcwillox";
    repo = "hass-template-climate";
    rev = "v${version}";
    hash = "sha256-InS4GUkQ6qoSdSkxz/V1LpMSNh0fsOefOFXCBOs6pXk=";
  };

  meta = {
    description = "Template-based climate entity for Home Assistant";
    homepage = "https://github.com/jcwillox/hass-template-climate";
    license = lib.licenses.mit;
  };
}
