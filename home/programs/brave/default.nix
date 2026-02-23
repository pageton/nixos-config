# Brave Browser configuration
{...}: {
  programs.brave = {
    enable = true;
    commandLineArgs = [
      "--enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecodeLinuxGL"
      "--ozone-platform-hint=auto"
      "--disable-gpu-shader-disk-cache" # Prevents shader cache corruption causing glitches
      "--enable-zero-copy" # Reduces buffer copies for smoother scrolling
    ];
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
    ];
  };
}
