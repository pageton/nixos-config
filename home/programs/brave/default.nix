# Brave Browser configuration
{
  lib,
  hostname,
  ...
}: {
  programs.brave = lib.mkIf (hostname != "server") {
    enable = true;
    extensions = [
      "bfogiafebfohielmmehodmfbbebbbpei" # Keeper Password Manager
      "ielooaepfhfcnmihgnabkldnpddnnldl" # Multilanguage Translator
      "mpbjkejclgfgadiemmefgebjfooflfhl" # Buster: Captcha Solver for Humans
      "amefmmaoenlhckgaoppgnmhlcolehkho" # github-vscode-icons
      "iphcomljdfghbkdcfndaijbokpgddeno" # Cookie Editor
      "cclelndahbckbenkjhflpdbgdldlbecc" # Get cookies.txt LOCALLY
      "hlepfoohegkhhmjieoechaddaejaokhf" # Refined GitHub
      "gppongmhjkpfnbhagpmjfkannfbllamg" # Wappalyzer - Technology profiler
      "hfjbmagddngcpeloejdejnfgbamkjaeg" # Vimium C - All by Keyboard
      "eifflpmocdbdmepbjaopkkhbfmdgijcc" # JSON Viewer Pro
    ];
  };
}
