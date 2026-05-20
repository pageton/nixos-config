# NixOS systemd helpers: service hardening, persistent timers, oneshot services.
#
# Timer functions are imported from shared/_systemd-timer-helpers.nix which
# contains both NixOS and HM variants side-by-side. Use mkNixosTimer here;
# use mkHmTimer in home/_helpers/_systemd-helpers.nix.

{ lib, ... }:
let
  timerHelpers = import ../../../shared/_systemd-timer-helpers.nix { inherit lib; };
in
{
  inherit (timerHelpers) mkNixosTimer;

  mkServiceHardening =
    {
      readWritePaths ? [ ],
      protectHome ? "read-only",
      protectSystem ? "strict",
      memoryMax ? null,
      memoryHigh ? null,
      useMkForce ? false,
    }:
    let
      wrap = if useMkForce then lib.mkForce else (x: x);
    in
    lib.optionalAttrs (readWritePaths != [ ]) { ReadWritePaths = readWritePaths; }
    // {
      PrivateTmp = wrap true;
      ProtectHome = wrap protectHome;
      NoNewPrivileges = wrap true;
      ProtectKernelTunables = wrap true;
      ProtectControlGroups = wrap true;
      RestrictSUIDSGID = wrap true;
    }
    // lib.optionalAttrs (protectSystem != null) { ProtectSystem = wrap protectSystem; }
    // lib.optionalAttrs (memoryMax != null) { MemoryMax = memoryMax; }
    // lib.optionalAttrs (memoryHigh != null) { MemoryHigh = memoryHigh; };

  mkOneshotService =
    {
      description,
      execStart,
      extraServiceConfig ? { },
    }:
    {
      inherit description;
      serviceConfig = {
        Type = "oneshot";
        ExecStart = execStart;
      }
      // extraServiceConfig;
    };
}
