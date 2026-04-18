# Glance self-hosted dashboard (localhost:8082).
{ config, lib, ... }:
{
  options.mySystem.glance = {
    enable = lib.mkEnableOption "Glance dashboard";
  };

  config = lib.mkIf config.mySystem.glance.enable {
    services.glance = {
      enable = true;
      openFirewall = false;

      settings =
        let
          searchBangs = import ./_search-bangs.nix;
          bookmarkGroups = import ./_bookmarks.nix;
          markets = import ./_markets.nix;
          rssSections = import ./_rss-sections.nix;

          searchWidget = {
            type = "search";
            search-engine = "duckduckgo";
            new-tab = true;
            bangs = searchBangs;
          };

          youtubeWidget = {
            type = "videos";
            title = "YouTube";
            style = "grid-cards";
            channels = import ./_youtube-channels.nix;
          };

          bookmarksWidget = {
            type = "bookmarks";
            groups = bookmarkGroups;
          };
        in
        {
          server = {
            host = "127.0.0.1";
            port = 8082;
          };

          branding = {
            logo-text = "S";
            app-name = "Dashboard";
            hide-footer = true;
            app-background-color = "240 13 14";
          };

          theme = {
            background-color = "240 13 14";
            primary-color = "218 52 67";
            positive-color = "107 17 50";
            negative-color = "359 51 51";
            contrast-multiplier = 1.2;
            text-saturation-multiplier = 1.3;
          };

          pages = [
            {
              name = "Home";

              head-widgets = [
                {
                  type = "markets";
                  hide-header = true;
                  inherit markets;
                }
              ];

              columns = [
                {
                  size = "small";
                  widgets = [
                    searchWidget
                    {
                      type = "monitor";
                      title = "Services";
                      cache = "1m";
                      sites = import ./_service-sites.nix;
                    }
                    {
                      type = "docker-containers";
                      format-container-names = true;
                    }
                  ];
                }
                {
                  size = "full";
                  widgets = [
                    {
                      type = "hacker-news";
                      limit = 10;
                      collapse-after = 5;
                      extra-sort-by = "engagement";
                    }
                    youtubeWidget
                  ];
                }
                {
                  size = "small";
                  widgets = [
                    {
                      type = "server-stats";
                      servers = [
                        {
                          type = "local";
                          name = "PC";
                          mountpoints = {
                            "/" = {
                              name = "Root";
                            };
                            "/home" = {
                              name = "Home";
                            };
                          };
                        }
                      ];
                    }
                    bookmarksWidget
                    {
                      type = "rss";
                      inherit (rssSections.releases)
                        title
                        cache
                        limit
                        collapse-after
                        feeds
                        ;
                    }
                  ];
                }
              ];
            }
            {
              name = "Search";
              columns = [
                {
                  size = "full";
                  widgets = [
                    searchWidget
                    bookmarksWidget
                  ];
                }
              ];
            }
            {
              name = "YouTube";
              columns = [
                {
                  size = "full";
                  widgets = [ youtubeWidget ];
                }
              ];
            }
          ];
        };
    };

    systemd.services.glance.serviceConfig.SupplementaryGroups = [ "docker" ];
  };
}
