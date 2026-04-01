import ./default.nix {
  spectrumFrameRate = 144;
  enableDgpuMonitoring = true;
  idleConfig = {
    enabled = true;
    screenOffTimeout = 600;
    lockTimeout = 600;
  };
}
