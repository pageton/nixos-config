# Networking configuration (NetworkManager).

{
  networking.networkmanager.enable = true;

  services.redis.servers."default" = {
    enable = true;
    port = 6379;
    bind = "127.0.0.1";
  };
}
