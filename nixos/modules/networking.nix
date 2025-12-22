# Networking configuration (NetworkManager).
{
  lib,
  hostname,
  user,
  ...
}: {
  networking.networkmanager.enable = lib.mkDefault (hostname != "server");
  services.openssh = lib.mkIf (hostname == "server") {
    enable = true;
    ports = [22];
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [user];
    };
  };

  networking.firewall.allowedTCPPorts = lib.mkIf (hostname != "server") [22];

  users.users."${user}" = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINGZ2wUekd/I4jKLlbos1CLvNdfiABE+QgUHGKHcDota pageton@proton.me"
    ];
  };

  services.redis.servers."default" = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };
}
