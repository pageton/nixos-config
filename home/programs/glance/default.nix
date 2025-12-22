# Glance dashboard configuration.
# This module configures Glance, a self-hosted dashboard that aggregates
# Features include RSS feeds, weather, calendar, bookmarks, and more.
{
  lib,
  pkgs,
  ...
}:
with lib; {
  # Glance dashboard service configuration
  services.glance = {
    enable = true; # Enable the Glance dashboard service
    package = pkgs.glance; # Use the standard Glance package

    # Use the settings as a YAML value (compatible with existing service)
    settings = {
      server = {
        host = mkDefault "127.0.0.1";
        port = mkDefault 8080;
      };

      # Catppuccin Mocha theme
      theme = {
        background-color = mkForce "240 21 15";
        primary-color = mkForce "217 92 83";
        positive-color = mkForce "115 54 76";
        negative-color = mkForce "347 70 65";
        contrast-multiplier = mkForce 1.2;
        text-saturation-multiplier = mkForce 1.3;
      };

      branding = mkForce {
        app-name = "Sadiq's Dashboard";
        logo-text = "S";
      };

      pages = mkForce [
        {
          name = "Home";
          columns = [
            {
              size = "small";
              widgets = [
                {
                  type = "calendar";
                  first-day-of-week = "monday";
                }
                {
                  type = "weather";
                  location = "Basrah, Iraq";
                  units = "metric";
                  hour-format = "24h";
                }
                {
                  type = "clock";
                  hour-format = "24h";
                  timezones = [
                    {
                      timezone = "Asia/Amman";
                      label = "Local";
                    }
                    {
                      timezone = "UTC";
                      label = "UTC";
                    }
                  ];
                }
                {
                  type = "to-do";
                  title = "Quick Notes";
                }
              ];
            }
            {
              size = "full";
              widgets = [
                {
                  type = "group";
                  widgets = [
                    {
                      type = "hacker-news";
                      limit = 15;
                      collapse-after = 5;
                    }
                    {
                      type = "lobsters";
                      limit = 10;
                      collapse-after = 3;
                    }
                  ];
                }
                {
                  type = "rss";
                  title = "Dev Blogs & News";
                  limit = 25;
                  collapse-after = 6;
                  cache = "3h";
                  feeds = [
                    {
                      url = "https://mitchellh.com/writing/feed.xml";
                      title = "Mitchell Hashimoto";
                      limit = 3;
                    }
                    {
                      url = "https://blog.rust-lang.org/feed.xml";
                      title = "Rust Blog";
                      limit = 3;
                    }
                    {
                      url = "https://bun.sh/blog/rss.xml";
                      title = "Bun Blog";
                      limit = 3;
                    }
                    {
                      url = "https://deno.com/blog/feed";
                      title = "Deno Blog";
                      limit = 3;
                    }
                    {
                      url = "https://nixos.org/blog/announcements-rss.xml";
                      title = "NixOS News";
                      limit = 3;
                    }
                    {
                      url = "https://weekly.nixos.org/feeds/all.rss.xml";
                      title = "NixOS Weekly";
                      limit = 3;
                    }
                    {
                      url = "https://ziglang.org/news/index.xml";
                      title = "Zig News";
                      limit = 3;
                    }
                    {
                      url = "https://webassembly.org/feed.xml";
                      title = "WebAssembly";
                      limit = 2;
                    }
                    {
                      url = "https://sqlite.org/news.rss";
                      title = "SQLite News";
                      limit = 2;
                    }
                  ];
                }
              ];
            }
            {
              size = "small";
              widgets = [
                {
                  type = "markets";
                  markets = [
                    {
                      symbol = "BTC-USD";
                      name = "Bitcoin";
                    }
                    {
                      symbol = "ETH-USD";
                      name = "Ethereum";
                    }
                    {
                      symbol = "LTC-USD";
                      name = "Litecoin";
                    }
                    {
                      symbol = "TON11419-USD";
                      name = "Toncoin";
                    }
                  ];
                }
                {
                  type = "rss";
                  title = "Tech News";
                  cache = "3h";
                  limit = 10;
                  collapse-after = 5;
                  feeds = [
                    {
                      url = "https://github.blog/feed/";
                      title = "GitHub Blog";
                      limit = 3;
                    }
                    {
                      url = "https://vercel.com/blog/rss.xml";
                      title = "Vercel Blog";
                      limit = 3;
                    }
                    {
                      url = "https://blog.cloudflare.com/rss/";
                      title = "Cloudflare Blog";
                      limit = 4;
                    }
                  ];
                }
              ];
            }
          ];
        }
        {
          name = "Development";
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "videos";
                  title = "Dev YouTube";
                  limit = 20;
                  collapse-after = 8;
                  channels = [
                    "UC5mIA5Y5_oARjxK8DCT-Cww" # IsaacHarrisHolt
                    "UC5KDiSAFxrDWhmysBcNqtMA" # EricMurphyxyz
                    "UCswG6FSbgZjbWtdf_hMLaow" # mattpocockuk
                    "UCvGwM5woTl13I-qThI4YMCg" # joshtriedcoding
                    "UC_mYaQAE6-71rjSN6CeCA-g" # NeetCode
                    "UCGD_0i6L48hucTiiyhb5QzQ" # basarat
                    "UC2Xd-TjJU8ql-NC9Gu-TJw" # beyondfireship
                    "UCjREVt2ZJU8ql-NC9Gu-TJw" # codetothemoon
                    "UCW6MNdOsqv2E9AjQkv9we7A" # PwnFunction
                    "UCP_eG7JBgRWNlNIOLYS6GZA" # realcrin
                    "UCFPTbsXLqWLHcXosYYw3D6Q" # codingjerk
                    "UCd3dNckv1Za2coSaHGHl5aA" # teej_dv
                    "UCpwl7jNE9PJc-lBTShNs5TQ" # codingwithsphere
                    "UCIaB0dv2_ARFj1co8SxXOkQ" # CodeWithCypert
                    "UCRgAOWBpaksZ_plUlJNs1ew" # deadoverflow
                    "UCZgt6AzoyjslHTC9dz0UoTw" # ByteByteGo
                    "UC2eYFnH61tmytImy1mTYvhA" # LukeSmithxyz
                    "UC1Zfv1Zrp1q5lKgBomzOyCA" # MelkeyDev
                    "UClcE-kVhqyiHCcjYwcpfj9w" # LiveOverflow
                    "UCAH6rw_O6p2ery3WG-t7GEQ" # swanend
                    "UC-mTIBh__DzAqW495JHXy5A" # TheCodingGopher
                    "UCrz1EgFHSkWpRkS0P-CPSXg" # Oscar_CS
                    "UCdSsl5RM4Tne4MhDRz2HjWw" # arjay_the_dev
                    "UCUMwY9iS8oMyWDYIe6_RmoA" # NoBoilerplate
                    "UC_zBdZ0_H_jn41FDRG7q4Tw" # vimjoyer
                    "UCYuQjtwffrSIzfswH3V24mQ" # tom-delalande
                    "UCW6xlqxSY3gGur4PkGPEUeA" # Seytonic
                    "UCFVteOob_YXJHPaGTqlDV2Q" # codehead01
                    "UCWQaM7SpSECp9FELz-cHzuQ" # dreamsofcode
                    "UCqC2G2M-rg4fzg1esKFLFIw" # deno_land
                    "UC8ENHE5xdFSwx71u3fDH5Xw" # ThePrimeagen
                    "UC9H0HzpKf5JlazkADWnW1Jw" # bashbunni
                    "UCXzw-OdotBUcNA9yhuYQBwA" # awesome-coding
                    "UC04nROIJrY22Gl2aFqKcdqQ" # sylvanfranklin
                    "UC7YOGHUfC1Tb6E4pudI9STA" # MentalOutlaw
                    "UC5--wS0Ljbin1TjWQX6eafA" # bigboxSWE
                    "UCsBjURrPoezykLs9EqgamOA" # Fireship
                    "UCxVPH8W2ayMey1-b0SY8rBQ" # TheCodingSloth
                    "UCUyeluBRhGPCW4rPe_UvBZQ" # ThePrimeTimeagen
                    "UC2WHjPDvbE6O328n17ZGcfg" # fknight
                    "UCbRP3c757lWg9M-U7TyEkXA" # t3dotgg
                  ];
                }
                {
                  type = "reddit";
                  subreddit = "programming";
                  show-thumbnails = true;
                  limit = 12;
                  collapse-after = 4;
                }
                {
                  type = "reddit";
                  subreddit = "golang";
                  show-thumbnails = false;
                  limit = 6;
                  collapse-after = 3;
                }
                {
                  type = "reddit";
                  subreddit = "typescript";
                  show-thumbnails = false;
                  limit = 6;
                  collapse-after = 3;
                }
                {
                  type = "reddit";
                  subreddit = "rust";
                  show-thumbnails = false;
                  limit = 6;
                  collapse-after = 3;
                }
                {
                  type = "reddit";
                  subreddit = "javascript";
                  show-thumbnails = false;
                  limit = 6;
                  collapse-after = 3;
                }
                {
                  type = "reddit";
                  subreddit = "webdev";
                  show-thumbnails = false;
                  limit = 6;
                  collapse-after = 3;
                }
                {
                  type = "reddit";
                  subreddit = "linux";
                  show-thumbnails = false;
                  limit = 6;
                  collapse-after = 3;
                }
              ];
            }
          ];
        }
        {
          name = "Startpage";
          width = "slim";
          hide-desktop-navigation = true;
          center-vertically = true;
          columns = [
            {
              size = "full";
              widgets = [
                {
                  type = "search";
                  autofocus = true;
                }
                {
                  type = "bookmarks";
                  groups = [
                    {
                      title = "Development";
                      color = "217 92 83";
                      links = [
                        {
                          title = "GitHub";
                          url = "https://github.com";
                          icon = "si:github";
                        }
                        {
                          title = "My Repos";
                          url = "https://github.com/pageton";
                          icon = "si:github";
                        }
                        {
                          title = "Bun Docs";
                          url = "https://bun.sh/docs";
                          icon = "si:bun";
                        }
                        {
                          title = "Deno Docs";
                          url = "https://docs.deno.com";
                          icon = "si:deno";
                        }
                        {
                          title = "TypeScript";
                          url = "https://www.typescriptlang.org/docs";
                          icon = "si:typescript";
                        }
                        {
                          title = "Zig Learn";
                          url = "https://ziglearn.org";
                          icon = "si:zig";
                        }
                        {
                          title = "Rust Docs";
                          url = "https://doc.rust-lang.org";
                          icon = "si:rust";
                        }
                        {
                          title = "C Reference";
                          url = "https://en.cppreference.com/w/c";
                          icon = "si:c";
                        }
                        {
                          title = "WebAssembly";
                          url = "https://webassembly.org";
                          icon = "si:webassembly";
                        }
                      ];
                    }
                    {
                      title = "Courses & Learning";
                      color = "115 54 76"; # Gruvbox yellow
                      links = [
                        {
                          title = "Low Level Academy";
                          url = "https://lowlevel.academy/";
                        }
                        {
                          title = "Total TypeScript";
                          url = "https://www.totaltypescript.com/";
                        }
                        {
                          title = "Fireship.io";
                          url = "https://fireship.io/";
                        }
                        {
                          title = "NeetCode";
                          url = "https://neetcode.io/";
                        }
                      ];
                    }
                    {
                      title = "Social & Community";
                      color = "217 92 83"; # Gruvbox orange
                      links = [
                        {
                          title = "Dev.to";
                          url = "https://dev.to/";
                          icon = "si:devdotto";
                        }
                        {
                          title = "Reddit";
                          url = "https://reddit.com";
                          icon = "si:reddit";
                        }
                        {
                          title = "Hacker News";
                          url = "https://news.ycombinator.com";
                          icon = "si:ycombinator";
                        }
                        {
                          title = "X (Twitter)";
                          url = "https://x.com";
                          icon = "si:x";
                        }
                        {
                          title = "LinkedIn";
                          url = "https://linkedin.com";
                          icon = "si:linkedin";
                        }
                        {
                          title = "Meetup";
                          url = "https://www.meetup.com/home";
                          icon = "si:meetup";
                        }
                      ];
                    }
                    {
                      title = "Tools & Utilities";
                      color = "347 70 65"; # Gruvbox red
                      links = [
                        {
                          title = "Proton Mail";
                          url = "https://mail.proton.me/u/1/inbox";
                          icon = "si:protonmail";
                        }
                        {
                          title = "Excalidraw";
                          url = "https://excalidraw.com/";
                          icon = "si:figma";
                        }
                        {
                          title = "YouTube";
                          url = "https://youtube.com";
                          icon = "si:youtube";
                        }
                        {
                          title = "Translate";
                          url = "https://translate.google.com";
                          icon = "si:googletranslate";
                        }
                        {
                          title = "Cloudflare";
                          url = "https://dash.cloudflare.com";
                          icon = "si:cloudflare";
                        }
                      ];
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
  };
}
