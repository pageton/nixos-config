# Brave browser with Wayland wrapper and declarative extensions.
{ pkgs, ... }:
let
  inherit (import ./isolation/_mk-wayland-browser-wrapper.nix) mkWaylandBrowserWrapper;
in
{
  programs.brave = {
    enable = true;
    package = pkgs.brave;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden Password Manager
      "ielooaepfhfcnmihgnabkldnpddnnldl" # Multilanguage Translator
      "mpbjkejclgfgadiemmefgebjfooflfhl" # Buster: Captcha Solver for Humans
      "amefmmaoenlhckgaoppgnmhlcolehkho" # github-vscode-icons
      "iphcomljdfghbkdcfndaijbokpgddeno" # Cookie Editor
      "cclelndahbckbenkjhflpdbgdldlbecc" # Get cookies.txt LOCALLY
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
      "gppongmhjkpfnbhagpmjfkannfbllamg" # Wappalyzer - Technology profiler
      "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium C - All by Keyboard
      "eifflpmocdbdmepbjaopkkhbfmdgijcc" # JSON Viewer Pro
      "bkhaagjahfmjljalopjnoealnfndnagc" # Octotree - GitHub code tree
      "anlikcnbgdeidpacdbdljnabclhahhmd" # Enhanced Github
      "dphilobhebphkdjbpfohgikllaljmgbn" # SimpleLogin by Proton: Secure Email Aliases
      "clngdbkpkpeebahjckkjfobafhncgmne" # Stylus
      "bkkmolkhemgaeaeggcmfbghljjjoofoh" # Catppuccin Chrome Theme - Mocha
      "mnlohknjofogcljbcknkakphddjpijak" # Translate - Translator, Dictionary, TTS
    ];
  };

  home.file.".local/bin/brave" = mkWaylandBrowserWrapper { bin = "${pkgs.brave}/bin/brave"; };
}
