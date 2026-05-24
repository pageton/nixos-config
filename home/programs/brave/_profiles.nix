# Single source of truth for Brave profile definitions.
# Used by brave/default.nix (browser config) and desktop entries (launcher entries).
{ constants }:
let
  inherit (constants.proxies.brave)
    personal
    work
    banking
    shopping
    illegal
    ;
in
[
  {
    name = "personal";
    label = "Personal";
    comment = "Brave with Finland proxy";
    path = "Personal";
    proxyHost = personal;
    homepage = "http://${constants.localhost}:${toString constants.ports.glance}/search";
  }
  {
    name = "work";
    label = "Work";
    comment = "Brave with Germany proxy";
    path = "Work";
    proxyHost = work;
    homepage = "about:blank";
  }
  {
    name = "banking";
    label = "Banking";
    comment = "Brave with Netherlands proxy";
    path = "Banking";
    proxyHost = banking;
    homepage = "about:blank";
  }
  {
    name = "shopping";
    label = "Shopping";
    comment = "Brave with Romania proxy";
    path = "Shopping";
    proxyHost = shopping;
    homepage = "about:blank";
  }
  {
    name = "illegal";
    label = "Illegal";
    comment = "Brave with Switzerland proxy";
    path = "Illegal";
    proxyHost = illegal;
    homepage = "about:blank";
  }
]
