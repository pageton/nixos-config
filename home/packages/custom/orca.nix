{
  pkgs,
  pkgsStable,
  constants,
}:

let
  version = "1.4.137";

  src = pkgs.fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/orca-linux.AppImage";
    hash = "sha256-jHQSL6aTSnZEZgsKT7HxyXZppQwatUgiF1UPzR4fyZg=";
  };

  appContents = pkgs.appimageTools.extract {
    pname = "orca";
    inherit version src;
  };

  orca = pkgs.appimageTools.wrapType2 {
    pname = "orca";
    inherit version src;
    extraPkgs = _: [
      pkgs.libsecret # credential/keyring storage
      pkgs.libappindicator-gtk3 # system tray
      pkgs.xdg-utils # open URLs/files from in-app
    ];
    extraInstallCommands = ''
      install -Dm644 ${appContents}/orca-ide.desktop $out/share/applications/orca.desktop
      substituteInPlace $out/share/applications/orca.desktop \
        --replace "Exec=AppRun --no-sandbox %U" "Exec=orca --no-sandbox %U"
      for size in 16 32 48 64 128 256 512 1024; do
        install -Dm644 \
          ${appContents}/usr/share/icons/hicolor/''${size}x''${size}/apps/orca-ide.png \
          $out/share/icons/hicolor/''${size}x''${size}/apps/orca-ide.png
      done
    '';
  };
in
[ orca ]
