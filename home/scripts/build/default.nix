{ pkgs, ... }:

let
  # Import all build script modules
  modulesCheckScript = pkgs.callPackage ./modules-check.nix { };
  securityAuditScript = pkgs.callPackage ./security-audit.nix { };
  performanceAuditScript = pkgs.callPackage ./performance-audit.nix { };
  hardeningAuditScript = pkgs.callPackage ./hardening-audit.nix { };
  evalAuditScript = pkgs.callPackage ./eval-audit.nix { };
in
{
  # Add build scripts to home.packages
  home.packages = [
    modulesCheckScript
    securityAuditScript
    performanceAuditScript
    hardeningAuditScript
    evalAuditScript
  ];
}
