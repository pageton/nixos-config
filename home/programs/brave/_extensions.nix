# Brave extension IDs from Chrome Web Store — force-installed via managed preferences.
# On Chromium-based browsers, extensions are installed via JSON files in the
# External Extensions directory, handled by programs.brave.extensions.
let
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
    "dphilobhebphkdjbpfohgikllaljmgbn" # SimpleLogin by Proton
    "clngdbkpkpeebahjckkjfobafhncgmne" # Stylus
    "bkkmolkhemgaeaeggcmfbghljjjoofoh" # Catppuccin Chrome Theme - Mocha
    "mnlohknjofogcljbcknkakphddjpijak" # Translate - Translator, Dictionary, TTS
    "jhnleheckmknfcgijgkadoemagpecfol" # Auto Tab Discard
  ];
in
{
  inherit extensions;
}
