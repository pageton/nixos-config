# Niri compositor and Wayland utilities including clipboard management,
# screenshot tools, and desktop integration.
{ pkgsStable, ... }: with pkgsStable;
[
  # === Clipboard Management ===
  cliphist # Clipboard history manager
  wl-clip-persist # Keep clipboard content after source closes
  wl-clipboard # Wayland clipboard utilities (wl-copy, wl-paste)
  wtype # Wayland keyboard and mouse input simulation

  # === Desktop Integration ===
  # libnotify's notify-send carries no gdk-pixbuf runpath (resolution relies
  # on the host /lib FHS hack), so it dies with "libgdk_pixbuf-2.0.so.0:
  # cannot open shared object file" in clean contexts (systemd user services,
  # sandboxes). Wrap it with the real loader path.
  (pkgsStable.symlinkJoin {
    name = "libnotify-wrapped";
    paths = [ pkgsStable.libnotify ];
    buildInputs = [ pkgsStable.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/notify-send" --prefix LD_LIBRARY_PATH : ${
        pkgsStable.lib.makeLibraryPath [ pkgsStable.gdk-pixbuf ]
      }
    '';
  })
  # playerctl is provided by services.playerctld (home/desktop/niri/default.nix)

  # === Screenshot and Capture ===
  grim # Wayland screenshot tool (used by swappy pipeline)
  slurp # Region selector for grim

  # === Wayland Utilities ===
  bemoji # Emoji picker for Wayland
  brightnessctl # Screen brightness control
  showmethekey # Show pressed keys on screen
]
