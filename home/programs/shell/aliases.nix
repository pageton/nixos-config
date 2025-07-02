{
  programs.zsh.shellAliases = {
    ls = "eza";
    ll = "eza -l";
    cd = "z";
    find = "fd";
    grep = "rg";
    etree = "eza --tree --level=1 --icons";
    cat = "bat";
    tk = "tokei";
    tf = "tokei --files";
    fs = "fselect";
    se = "sudoedit";
    ff = "fastfetch";
    mf = "microfetch";
    of = "onefetch";
    lg = "lazygit";
    ns = "nix-shell";
    nd = "nix develop --command zsh";
    nfu = "nix flake update";
    nfs = "nix flake show";
    y = "yazi";
    n = "nvim";
    h = "hx";
    c = "clear";
  };
}
