_: {
  services.sopswarden = {
    enable = true;
    secrets = {
      google-assistant-project-id = "Google Assistant Project ID";
      google-assistant-client-email = "Google Assistant Client Email";
      google-assistant-private-key = "Google Assistant Private Key";
    };
  };
}
