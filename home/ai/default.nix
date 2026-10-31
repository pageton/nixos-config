# Install pinned AI applications and import agent settings without managing mutable data.
{ aiPackages, pkgs, ... }:
let
  # Codex 0.157 enables daemon auto-start, but this source-built package lacks
  # the complete-package metadata needed to launch the daemon. Override only
  # this feature for the CLI until the upstream packaging is fixed; leave the
  # user's mutable Codex config and credentials outside Nix.
  codexCli = pkgs.symlinkJoin {
    name = "codex-no-auto-daemon";
    paths = [ aiPackages.codex ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/codex" --add-flags "--disable daemon_auto_start"
    '';
  };
  # t3code's backend spawns with node-pty, whose prebuilt pty.node needs
  # libstdc++.so.6 that Electron's environment does not provide; without it
  # the backend crash-loops and the window never opens. Inject the library
  # path until the package carries the dependency itself.
  t3codeCli = pkgs.symlinkJoin {
    name = "t3code-desktop-libstdcpp";
    paths = [ aiPackages.t3code-desktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/t3code-desktop" \
        --prefix LD_LIBRARY_PATH : ${pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc.lib ]}
    '';
  };
  # The Iran<->China transit to Z.ai's CDN suffers evening packet-loss
  # bursts (bursty ETIMEDOUTs against zcode.z.ai in the zcode host log).
  # WARP runs in local SOCKS proxy mode (warp-svc "WarpProxy", listener
  # 127.0.0.1:40000 — see nixos/modules/cloudflare-warp.nix): traffic exits
  # via Cloudflare without touching system routes or DNS, so only apps that
  # opt in are proxied. Probe the listener first: when WARP is down, zcode
  # falls back to its direct route (plus the pinned hosts entry from
  # network.nix).
  zcodeCli = pkgs.symlinkJoin {
    name = "zcode-warp-socks";
    paths = [ aiPackages.zcode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/zcode" --run '
        if (exec 3<>/dev/tcp/127.0.0.1/40000) 2>/dev/null; then
          exec 3<&- 3>&-
          export https_proxy="socks5://127.0.0.1:40000"
          export HTTPS_PROXY="socks5://127.0.0.1:40000"
          export no_proxy="localhost,127.0.0.1,::1,.local,.ts.net"
          export NO_PROXY="$no_proxy"
        fi
      '
    '';
  };
  # Numtide's V2 package exposes `opencode2`; provide the usual CLI name and
  # generate matching Zsh completion from that package.
  opencodeCli = pkgs.symlinkJoin {
    name = "opencode-cli";
    paths = [
      (pkgs.writeShellScriptBin "opencode" ''
        exec ${aiPackages.opencode2}/bin/opencode2 "$@"
      '')
    ];
    postBuild = ''
      mkdir -p "$out/share/zsh/site-functions"
      HOME="$TMPDIR" \
        XDG_CONFIG_HOME="$TMPDIR/config" \
        XDG_DATA_HOME="$TMPDIR/data" \
        XDG_CACHE_HOME="$TMPDIR/cache" \
        XDG_STATE_HOME="$TMPDIR/state" \
        ${aiPackages.opencode2}/bin/opencode2 --completions zsh > "$out/share/zsh/site-functions/_opencode"
    '';
  };
in
{
  imports = [
    ./herdr.nix
    ./herdr-backup.nix
    ./agent-reach.nix
    ./our-free-model.nix
    ./chrome-devtools
    ./pi
    ./pi-re
    ./open-design.nix
    ./thinkrail.nix
    ./skills.nix
    ./voice
  ];

  # Share portable guidance, not Pi's extension-specific instructions. Runtime
  # settings and credentials remain writable and outside Nix.
  home.file.".codex/AGENTS.md".source = ./agent-instructions.md;
  xdg.configFile."opencode/AGENTS.md".source = ./agent-instructions.md;

  # Executables come from Numtide; settings, logins, and session data remain
  # in the user's home until deliberately migrated one app at a time.
  home.packages = with aiPackages; [
    antigravity-cli
    chatgpt
    codexCli
    ctx
    executor
    herdr
    officecli
    omp # oh-my-pi
    opencodeCli
    pi
    skills
    t3codeCli
    zcodeCli
  ];
}
