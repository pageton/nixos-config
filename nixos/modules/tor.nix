# Tor service configuration for privacy and anonymity.
{
  lib,
  hostname,
  ...
}: {
  services.tor = lib.mkIf (hostname != "server") {
    enable = lib.mkDefault true;
    torsocks.enable = true;
    client.enable = true;
  };
}
