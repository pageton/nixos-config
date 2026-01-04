# Multimedia and media processing packages for media playback,
# image viewing, video processing, and media information analysis.
{pkgsStable, ...}:
with pkgsStable; [
  # === Media Players ===
  mpv # Advanced video player with extensive features

  # === Image Viewers ===
  imv # Minimalist image viewer for Wayland
  feh # Lightweight image viewer for X11

  # === Media Processing ===
  ffmpeg # Complete multimedia processing toolkit
  ffmpegthumbnailer # Video thumbnail generator for file managers

  # === Media Information ===
  mediainfo # Media file information analyzer

  # === Media Playback ===
  vlc
]
