# Nautilus (GNOME Files) configuration.

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core Nautilus
    nautilus
    nautilus-python # For extensions

    # Thumbnails and previews (videos, PDFs, images, docs)
    gst_all_1.gst-plugins-good # Media thumbnails
    poppler_utils # PDF thumbnails
    ffmpegthumbnailer # Video thumbnails
    gnome-epub-thumbnailer # EPUB/book previews
    sushi # Quick file previews (hover/open without full app—super cool for quick peeks)
  ];

  # Enable udisks2 for automounting
  systemd.services.udisks2.enable = true;

  # PolicyKit rule for passwordless mounting (reusing your existing rule)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Enforce Gruvbox theming (inherits from Stylix, but explicit for consistency)
  environment.variables = {
    GTK_THEME = "Gruvbox-Dark";
  };
}
