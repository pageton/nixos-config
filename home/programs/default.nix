{
  lib,
  hostname,
  ...
}: {
  imports =
    [
      ./languages
      ./gpg
      ./obs
      ./glance
      ./brave
      ./helix
      ./tailscale
      ./shell
    ]
    ++ lib.optionals (hostname != "server") [
      ./discord
      ./spicetify
      ./zen
      ./terminal
      ./thunar
      ./nvf
      ./zellij
      ./isolation
    ];
}
