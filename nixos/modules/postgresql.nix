# PostgreSQL database server module
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.mySystem.postgresql;
in {
  options.mySystem.postgresql = {
    enable = lib.mkEnableOption "PostgreSQL database server";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.postgresql_16;
      description = "PostgreSQL package to use";
    };

    port = lib.mkOption {
      type = lib.types.int;
      default = 5432;
      description = "PostgreSQL port";
    };

    enableTCPIP = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable TCP/IP connections (for remote access)";
    };

    authentication = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local   all             all                                     trust
        host    all             all             127.0.0.1/32            trust
        host    all             all             ::1/128                 trust
      '';
      description = "PostgreSQL pg_hba.conf authentication rules";
    };
  };

  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = cfg.package;
      enableTCPIP = cfg.enableTCPIP;
      ensureDatabases = [];
      ensureUsers = [];
      authentication = cfg.authentication;
      settings = {
        port = cfg.port;
        max_connections = 200;
        shared_buffers = "256MB";
        effective_cache_size = "1GB";
        maintenance_work_mem = "64MB";
        checkpoint_completion_target = 0.9;
        wal_buffers = "16MB";
        default_statistics_target = 100;
        random_page_cost = 1.1;
        effective_io_concurrency = 200;
        work_mem = "2621kB";
        min_wal_size = "1GB";
        max_wal_size = "4GB";
      };
    };

    # Add PostgreSQL client tools
    environment.systemPackages = with pkgs; [
      postgresql_16 # psql and other client tools
    ];

    # Open firewall for PostgreSQL (if TCP is enabled)
    networking.firewall.allowedTCPPorts = lib.optionals cfg.enableTCPIP [cfg.port];
  };
}
