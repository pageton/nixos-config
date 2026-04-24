# Single source of truth for Zen Browser profile definitions.
# Used by default.nix (browser config) and desktop entries (launcher entries).

{ constants }:
let
  homepage = "http://${constants.localhost}:8082";
  inherit (constants.proxies.zen-browser)
    personal
    work
    banking
    shopping
    illegal
    ;
  inherit (constants.proxies) i2pd;
in
[
  {
    name = "personal";
    label = "Personal";
    comment = "Zen Browser with Sweden proxy";
    id = 0;
    isDefault = true;
    path = "personal.default";
    proxyHost = personal;
    inherit homepage;
    extraSettings = {
      # Always start on the configured homepage for this profile.
      "browser.startup.page" = 1;
      # Keep the browser new tab page enabled so the forced extension can
      # redirect new tabs to the homepage.
      "browser.newtabpage.enabled" = true;
    };
  }
  {
    name = "work";
    label = "Work";
    comment = "Zen Browser with Germany proxy";
    id = 1;
    isDefault = false;
    path = "work.default";
    proxyHost = work;
    inherit homepage;
    extraSettings = {
      "browser.startup.page" = 1;
      "browser.newtabpage.enabled" = true;
    };
  }
  {
    name = "banking";
    label = "Banking";
    comment = "Zen Browser with Netherlands proxy";
    id = 2;
    isDefault = false;
    path = "banking.default";
    proxyHost = banking;
    homepage = "about:blank";
  }
  {
    name = "shopping";
    label = "Shopping";
    comment = "Zen Browser with Romania proxy";
    id = 3;
    isDefault = false;
    path = "shopping.default";
    proxyHost = shopping;
    homepage = "about:blank";
  }
  {
    name = "illegal";
    label = "Illegal";
    comment = "Zen Browser with Switzerland proxy";
    id = 4;
    isDefault = false;
    path = "illegal.default";
    proxyHost = illegal;
    homepage = "about:blank";
  }
  {
    name = "i2pd";
    label = "I2P";
    comment = "Zen Browser with I2P proxy";
    id = 5;
    isDefault = false;
    path = "i2pd.default";
    proxyHost = i2pd;
    homepage = "about:blank";
    extraSettings = {
      "browser.newtabpage.enabled" = false;
      "network.proxy.socks_port" = constants.ports.i2pd-socks;
    };
  }
]
