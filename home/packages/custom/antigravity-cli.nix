{ pkgs, ... }:

let
  antigravityCli = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "antigravity-cli";
    version = "1.2.9";

    src = pkgs.fetchurl {
      url = "https://github.com/google-antigravity/antigravity-cli/releases/download/${version}/agy_cli_linux_x64.tar.gz";
      hash = "sha256-2YUDc/PfhmARAkqWH6l0DMStqsBg7r6ccPvyY6xrJiQ=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      install -Dm755 antigravity "$out/bin/agy"

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Terminal-first agent CLI from Google Antigravity";
      homepage = "https://github.com/google-antigravity/antigravity-cli";
      license = licenses.unfree;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "x86_64-linux" ];
      mainProgram = "agy";
    };
  };
in
[ antigravityCli ]
