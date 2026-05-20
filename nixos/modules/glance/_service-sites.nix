# Glance dashboard service health check endpoints.
# Port numbers are injected from constants.ports to avoid drift.

{ constants }:

let
  inherit (constants) urls;
in
[
  {
    title = "Glance";
    url = urls.glance;
    icon = "mdi:view-dashboard-outline";
  }
  {
    title = "Scrutiny";
    url = urls.scrutiny;
    icon = "mdi:harddisk";
  }
  {
    title = "Syncthing";
    url = "http://${constants.localhost}:8384";
    icon = "si:syncthing";
  }
]
