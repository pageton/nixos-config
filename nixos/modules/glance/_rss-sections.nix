{
  releases = {
    title = "Releases";
    cache = "1h";
    limit = 12;
    collapse-after = 6;
    feeds = [
      {
        url = "https://github.com/rust-lang/rust/releases.atom";
        title = "Rust Releases";
        limit = 3;
      }
      {
        url = "https://github.com/golangci/golangci-lint/releases.atom";
        title = "GolangCI Releases";
        limit = 2;
      }
      {
        url = "https://github.com/NixOS/nixfmt/releases.atom";
        title = "Nixfmt Releases";
        limit = 2;
      }
      {
        url = "https://github.com/YaLTeR/niri/releases.atom";
        title = "Niri Releases";
        limit = 2;
      }
      {
        url = "https://github.com/neovim/neovim/releases.atom";
        title = "Neovim Releases";
        limit = 1;
      }
      {
        url = "https://github.com/glanceapp/glance/releases.atom";
        title = "Glance Releases";
        limit = 1;
      }
      {
        url = "https://github.com/golang/go/tags.atom";
        title = "Go Tags";
        limit = 4;
      }
      {
        url = "https://go.dev/blog/feed.atom";
        title = "Go Blog";
        limit = 3;
      }
      {
        url = "https://github.com/NixOS/nix/tags.atom";
        title = "Nix Tags";
        limit = 2;
      }
      {
        url = "https://nixos.org/blog/announcements-rss.xml";
        title = "NixOS News";
        limit = 2;
      }
      {
        url = "https://weekly.nixos.org/feeds/all.rss.xml";
        title = "NixOS Weekly";
        limit = 1;
      }
    ];
  };
}
