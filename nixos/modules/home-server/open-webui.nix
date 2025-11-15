{ config, pkgs, ... }:
{
  services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 8080;
    environment = {
      # Point to Ollama on Karsa
      OLLAMA_BASE_URL = "http://karsa.local:11434";
      # Optional: Add Claude API support
      OPENAI_API_BASE_URLS = "https://api.anthropic.com/v1";
    };
  };
}
