# Runtime dependencies for DMS-provided features.
#
# Carried over from the old Noctalia packages.nix — these are not bundled by
# the dms-shell package itself but are used by DMS features (screenshot OCR,
# QR/barcode scan, inline translation, screen recording, gif export).
# DMS's own module pulls in dgop/matugen/cava/khal/wtype/glib/networkmanager
# behind its `enable*` options; those are not duplicated here.
{ pkgs, ... }: {
  home.packages = with pkgs; [
    tesseract # OCR (DMS screenshot → text)
    zbar # barcode/QR scan
    translate-shell # translation widget
    wl-screenrec # screen capture
    gifski # gif export
  ];
}
