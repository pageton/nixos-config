let
  mkSite =
    {
      title,
      url,
      icon,
    }:
    {
      inherit title url icon;
    };
in
map mkSite [
  {
    title = "Glance";
    url = "http://localhost:8082";
    icon = "mdi:view-dashboard-outline";
  }
  {
    title = "Netdata";
    url = "http://localhost:19999";
    icon = "si:netdata";
  }
  {
    title = "Bitwarden";
    url = "https://vault.sadiq.lol";
    icon = "si:bitwarden";
  }
  {
    title = "Scrutiny";
    url = "http://localhost:8080";
    icon = "mdi:harddisk";
  }
  {
    title = "Syncthing";
    url = "http://localhost:8384";
    icon = "si:syncthing";
  }
]
