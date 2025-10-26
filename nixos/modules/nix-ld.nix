# Nix-ld configuration for running non-Nix binaries.
# This module enables nix-ld, which allows running dynamically linked
# executables that were not built for NixOS by providing common shared libraries.

{ pkgs, ... }:

{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      # Core system libraries
      stdenv.cc.cc
      libgcc
      glibc
      glib

      # Compression and crypto
      zlib
      bzip2
      xz
      openssl

      # Printing support
      cups

      # XCB protocol library
      xorg.libxcb

      # X11 and graphics
      xorg.libX11
      xorg.libXext
      xorg.libXi
      xorg.libXrender
      xorg.libXft
      xorg.libXcursor
      xorg.libXrandr
      xorg.libXinerama
      libGL

      # Additional X11 libraries for Chrome/Chromium
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXfixes
      xorg.libXScrnSaver
      xorg.libXtst
      xorg.libxkbfile
      xorg.libxshmfence

      # System services
      dbus
      systemd

      # Text and fonts
      fontconfig
      freetype
      expat

      # Additional libraries for Chrome/Chromium
      atk
      at-spi2-atk
      cairo
      gdk-pixbuf
      gtk3
      pango
      alsa-lib
      libdrm
      libxkbcommon
      mesa
      libgbm

      # Development libraries
      libffi
      ncurses
      readline

      # Network
      curl
      libxml2
      nss
      nspr

      # Additional libraries for broader application support
      sqlite # Database support for many applications
      icu # Unicode support
      libpng # PNG image support
      libjpeg # JPEG image support
      libwebp # WebP image support
      libtiff # TIFF image support
      librsvg # SVG rendering
      gdk-pixbuf # Image loading
      harfbuzz # Text shaping
      graphite2 # Smart font rendering
      pcre # Regular expressions
      gmp # Arbitrary precision arithmetic
      libtasn1 # ASN.1 library
      libunistring # Unicode string library
      libidn2 # Internationalized domain names
      libpsl # Public Suffix List library
      libssh2 # SSH2 library
      nghttp2 # HTTP/2 library
      libbsd # BSD library functions
      libcap # POSIX capabilities
      libseccomp # seccomp filtering
      libapparmor # AppArmor support
      systemd # Systemd libraries

      # Video and audio codecs
      ffmpegthumbnailer # Video thumbnail generation
      ffmpeg-full # Complete FFmpeg suite
      libva # VAAPI support
      libvdpau # VDPAU support
      intel-media-driver # Intel GPU media driver
      mesa # Mesa GPU drivers

      # Python support (for Python applications)
      python3
      python3Packages.numpy
      python3Packages.pillow

      # Node.js support (for Node applications)
      nodejs

      # Java support (for Java applications)
      jdk17

      # Wine and Proton compatibility
      wine
      winetricks
    ];
  };
}
