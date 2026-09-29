# Glance dashboard settings tree: widgets, theming, service monitors.
{ constants }:
let
  inherit (constants) localhost ports urls;

  # Convert hex (#RRGGBB) to Glance's decimal HSL format ("H S L").
  hexToGlanceHsl =
    hex:
    let
      hexChar =
        c:
        {
          "0" = 0;
          "1" = 1;
          "2" = 2;
          "3" = 3;
          "4" = 4;
          "5" = 5;
          "6" = 6;
          "7" = 7;
          "8" = 8;
          "9" = 9;
          "a" = 10;
          "b" = 11;
          "c" = 12;
          "d" = 13;
          "e" = 14;
          "f" = 15;
          "A" = 10;
          "B" = 11;
          "C" = 12;
          "D" = 13;
          "E" = 14;
          "F" = 15;
        }
        .${c};

      hexByte = s: hexChar (builtins.substring 0 1 s) * 16 + hexChar (builtins.substring 1 1 s);
      round = x: builtins.floor (x + 0.5);

      h = builtins.substring 1 6 hex;
      r = hexByte (builtins.substring 0 2 h);
      g = hexByte (builtins.substring 2 2 h);
      b = hexByte (builtins.substring 4 2 h);

      rn = r / 255.0;
      gn = g / 255.0;
      bn = b / 255.0;

      max = if rn > gn then (if rn > bn then rn else bn) else (if gn > bn then gn else bn);
      min = if rn < gn then (if rn < bn then rn else bn) else (if gn < bn then gn else bn);
      delta = max - min;

      l = (max + min) / 2.0;

      s =
        if delta == 0 then
          0.0
        else if l <= 0.5 then
          delta / (max + min)
        else
          delta / (2.0 - max - min);

      rawH =
        if delta == 0 then
          0.0
        else if max == rn then
          (gn - bn) / delta + (if gn < bn then 6.0 else 0.0)
        else if max == gn then
          (bn - rn) / delta + 2.0
        else
          (rn - gn) / delta + 4.0;
    in
    "${toString (round (rawH * 60.0))} ${toString (round (s * 100.0))} ${toString (round (l * 100.0))}";

  searchBangs = [
    {
      title = "GitHub";
      shortcut = "!gh";
      url = "https://github.com/search?q={QUERY}";
    }
    {
      title = "NixOS";
      shortcut = "!nix";
      url = "https://search.nixos.org/packages?query={QUERY}";
    }
    {
      title = "YouTube";
      shortcut = "!yt";
      url = "https://www.youtube.com/results?search_query={QUERY}";
    }
    {
      title = "Crates";
      shortcut = "!crate";
      url = "https://crates.io/search?q={QUERY}";
    }
    {
      title = "NPM";
      shortcut = "!npm";
      url = "https://www.npmjs.com/search?q={QUERY}";
    }
  ];

  bookmarkGroups = [
    {
      title = "AI";
      links = [
        {
          title = "Claude";
          url = "https://claude.ai/";
          icon = "si:anthropic";
        }
        {
          title = "ChatGPT";
          url = "https://chatgpt.com/";
          icon = "si:openai";
        }
        {
          title = "DeepSeek";
          url = "https://chat.deepseek.com/";
          icon = "si:deepseek";
        }
      ];
    }
    {
      title = "Dev";
      links = [
        {
          title = "GitHub";
          url = "https://github.com";
          icon = "si:github";
        }
        {
          title = "Excalidraw";
          url = "https://excalidraw.com/";
          icon = "si:excalidraw";
        }
        {
          title = "Codeberg";
          url = "https://codeberg.org/";
          icon = "si:codeberg";
        }
      ];
    }
    {
      title = "Social";
      links = [
        {
          title = "Reddit";
          url = "https://www.reddit.com/";
          icon = "si:reddit";
        }
        {
          title = "YouTube";
          url = "https://www.youtube.com/";
          icon = "si:youtube";
        }
        {
          title = "X";
          url = "https://x.com/home";
          icon = "si:x";
        }
      ];
    }
    {
      title = "Accounts";
      links = [
        {
          title = "Proton Mail";
          url = "https://mail.proton.me/u/1/inbox";
          icon = "si:protonmail";
        }
        {
          title = "SimpleLogin";
          url = "https://app.simplelogin.io/dashboard/";
          icon = "mdi:shield-lock-outline";
        }
        {
          title = "Cloudflare";
          url = "https://dash.cloudflare.com";
          icon = "si:cloudflare";
        }
        {
          title = "Namecheap";
          url = "https://www.namecheap.com/";
          icon = "si:namecheap";
        }
        {
          title = "Gmail";
          url = "https://mail.google.com/mail/u/0/#inbox";
          icon = "si:gmail";
        }
      ];
    }
    {
      title = "Hosting";
      links = [
        {
          title = "Vultr";
          url = "https://www.vultr.com/";
          icon = "si:vultr";
        }
        {
          title = "Contabo";
          url = "https://contabo.com/en/";
          icon = "mdi:server";
        }
        {
          title = "DigitalOcean";
          url = "https://www.digitalocean.com/";
          icon = "si:digitalocean";
        }
        {
          title = "Hetzner";
          url = "https://hetzner.com/";
          icon = "si:hetzner";
        }
      ];
    }
  ];

  marketSymbols = [
    {
      symbol = "BTC-USD";
      name = "Bitcoin";
    }
    {
      symbol = "LTC-USD";
      name = "Litecoin";
    }
    {
      symbol = "XMR-USD";
      name = "Monero";
    }
    {
      symbol = "TON11419-USD";
      name = "Toncoin";
    }
    {
      symbol = "GC=F";
      name = "Gold";
    }
    {
      symbol = "SI=F";
      name = "Silver";
    }
  ];

  serverStats = [
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

  githubRepos = [
    "rust-lang/rust"
    "golang/go"
    "YaLTeR/niri"
    "neovim/neovim"
    "glanceapp/glance"
  ];

  redditFeeds = [
    {
      subreddit = "unixporn";
      style = "vertical-list";
      limit = 10;
      collapse-after = 5;
    }
    {
      subreddit = "nixos";
      style = "vertical-list";
      limit = 10;
      collapse-after = 5;
    }
    {
      subreddit = "linux";
      style = "vertical-list";
      limit = 10;
      collapse-after = 5;
    }
  ];

  youtubeChannels = [
    "UCsBjURrPoezykLs9EqgamOA"
    "UCUyeluBRhGPCW4rPe_UvBZQ"
    "UCc0YbtMkRdhcqwhu3Oad-lw"
    "UC2Xd-TjJByJyK2w1zNwY0zQ"
    "UCkVfrGwV-iG9bSsgCbrNPxQ"
    "UCFPTbsXLqWLHcXosYYw3D6Q"
    "UCW6MNdOsqv2E9AjQkv9we7A"
    "UCZgt6AzoyjslHTC9dz0UoTw"
    "UCWQaM7SpSECp9FELz-cHzuQ"
    "UCW6xlqxSY3gGur4PkGPEUeA"
    "UCvF3C7NCZBHuE9iJvmsxO3w"
    "UC5--wS0Ljbin1TjWQX6eafA"
    "UCjREVt2ZJU8ql-NC9Gu-TJw"
    "UC7YOGHUfC1Tb6E4pudI9STA"
    "UC_zBdZ0_H_jn41FDRG7q4Tw"
    "UCTMiGZ6t4wry5sk7Cso2plQ"
    "UCbRP3c757lWg9M-U7TyEkXA"
    "UCzPpbeK8ANcNKg5aoMB0miw"
    "UCXzw-OdotBUcNA9yhuYQBwA"
    "UCLB2b6r4jfV4vs6Hvv0YO2g"
    "UClILBikQbI_4izI-sTa-Znw"
  ];

  githubTrending = {
    type = "custom-api";
    title = "Trending Repos";
    cache = "24h";
    url = "https://api.ossinsight.io/v1/trends/repos/?period=past_24_hours&language=All";
    template = ''
      <ul class="list list-gap-10 collapsible-container" data-collapse-after="3">
        {{ range .JSON.Array "data.rows" }}
          <li>
            <a class="color-primary-if-not-visited" href="https://github.com/{{ .String "repo_name" }}">{{ .String "repo_name" }}</a>
            <ul class="list-horizontal-text">
              <li class="color-highlight">{{ .String "primary_language" }}</li>
              <li>{{ .String "stars" }} stars</li>
              <li>{{ .String "forks" }} forks</li>
            </ul>
            <ul class="list collapsible-container">
              <li class="color-subdue">{{ .String "description" }}</li>
            </ul>
          </li>
        {{ end }}
      </ul>
    '';
  };

  githubActivity = {
    notifications = {
      type = "custom-api";
      title = "Notifications";
      cache = "30m";
      url = "https://api.github.com/notifications?all=false&per_page=15";
      headers = {
        Authorization = "Bearer \${GITHUB_TOKEN}";
        Accept = "application/vnd.github+json";
      };
      template = ''
        <ul class="list list-gap-10 collapsible-container" data-collapse-after="5">
          {{ range .JSON.Array "" }}
            <li>
              <div class="flex items-center gap-5">
                {{ if eq (.String "reason") "assign" }}<span class="color-positive">A</span>
                {{ else if eq (.String "reason") "mention" }}<span class="color-highlight">@</span>
                {{ else if eq (.String "reason") "review_requested" }}<span class="color-primary">R</span>
                {{ else if eq (.String "reason") "subscribed" }}<span class="color-subdue">S</span>
                {{ else }}<span class="color-subdue">&bull;</span>
                {{ end }}
                <a class="color-primary-if-not-visited" href="{{ .String "subject.url" | replaceAll "api.github.com/repos" "github.com" | replaceAll "/pulls/" "/pull/" }}">{{ .String "subject.title" }}</a>
              </div>
              <div class="color-subdue text-small">{{ .String "repository.full_name" }}</div>
            </li>
          {{ else }}
            <li class="color-subdue">No new notifications</li>
          {{ end }}
        </ul>
      '';
    };

    personalRepos = {
      type = "custom-api";
      title = "My Repos";
      cache = "30m";
      url = "https://api.github.com/user/repos?affiliation=owner&sort=updated&per_page=10";
      headers = {
        Authorization = "Bearer \${GITHUB_TOKEN}";
        Accept = "application/vnd.github.v3+json";
      };
      template = ''
        <ul class="list list-gap-10 collapsible-container" data-collapse-after="5">
          {{ range .JSON.Array "" }}
            <li>
              <div class="flex items-center justify-between">
                <a class="color-primary-if-not-visited" href="{{ .String "html_url" }}">{{ .String "name" }}</a>
                <ul class="list-horizontal-text">
                  <li class="text-small color-subdue">{{ .String "language" }}</li>
                  <li class="text-small color-subdue">&#9733; {{ .Int "stargazers_count" }}</li>
                </ul>
              </div>
              <div class="color-subdue text-small margin-top-2">{{ .String "description" }}</div>
            </li>
          {{ end }}
        </ul>
      '';
    };
  };

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
    channels = youtubeChannels;
  };

  bookmarksWidget = {
    type = "bookmarks";
    groups = bookmarkGroups;
  };

  releasesWidget = {
    type = "releases";
    title = "Releases";
    show-source-icon = true;
    limit = 6;
    collapse-after = 3;
    token = "\${GITHUB_TOKEN}";
    repositories = githubRepos;
  };

  serviceSites = [
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
      url = "http://${localhost}:8384";
      icon = "si:syncthing";
    }
  ];
in
{
  server = {
    host = localhost;
    port = ports.glance;
  };

  branding = {
    logo-text = "S";
    app-name = "Dashboard";
    hide-footer = true;
    app-background-color = hexToGlanceHsl constants.color.bg;
  };

  theme = {
    background-color = hexToGlanceHsl constants.color.bg;
    primary-color = hexToGlanceHsl constants.color.blue;
    positive-color = hexToGlanceHsl constants.color.green;
    negative-color = hexToGlanceHsl constants.color.red;
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
          markets = marketSymbols;
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
              sites = serviceSites;
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
          ]
          ++ (map (sub: {
            type = "reddit";
            inherit (sub)
              subreddit
              style
              limit
              collapse-after
              ;
          }) redditFeeds);
        }
        {
          size = "small";
          widgets = [
            {
              type = "server-stats";
              servers = serverStats;
            }
            bookmarksWidget
            releasesWidget
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
    {
      name = "GitHub";

      columns = [
        {
          size = "full";
          widgets = [
            githubTrending
            githubActivity.notifications
            githubActivity.personalRepos
            releasesWidget
          ];
        }
      ];
    }
  ];
}
