# Nix-ld: run non-NixOS dynamically linked binaries.
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

      # X11 and graphics
      libxcb
      libx11
      libxext
      libxi
      libxrender
      libxft
      libxcursor
      libxrandr
      libxinerama
      libxcomposite
      libxdamage
      libxfixes
      libxscrnsaver
      libxtst
      libxkbfile
      libxshmfence
      libGL

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
      gtk4
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

      # Video and audio codecs
      ffmpegthumbnailer # Video thumbnail generation
      ffmpeg-full # Complete FFmpeg suite
      libva # VAAPI support
      libvdpau # VDPAU support
      intel-media-driver # Intel GPU media driver

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
