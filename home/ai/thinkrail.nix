# Install the prebuilt ThinkRail desktop app; its derivation ships the
# .desktop entry and hicolor icon, so only the package needs adding.
{ thinkrailPackage, ... }:
{
  home.packages = [ thinkrailPackage ];
}
