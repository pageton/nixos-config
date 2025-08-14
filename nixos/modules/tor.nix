# Tor service configuration for privacy and anonymity.

{ lib, ... }:

{
  services.tor = {
    enable = lib.mkDefault true;
    torsocks.enable = true;
    client.enable = true;
  };
}
