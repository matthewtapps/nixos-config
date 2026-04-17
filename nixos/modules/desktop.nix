{ ... }: {
  # Desktops should never hibernate. Setting AllowHibernation=no in sleep.conf
  # is the correct mechanism - logind checks this before honoring any hibernate
  # request, including those from D-Bus (which is how Noctalia calls it).
  systemd.sleep.settings.Sleep = {
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };
}
