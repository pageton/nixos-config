# JavaScript/TypeScript programming language configuration.
# This module configures JavaScript/TypeScript development environment
# with runtimes, package managers, LSP support, and project workspace setup.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Configurable list of global npm packages to install
  globalNpmPackages = [
    "@google/gemini-cli"
    "@anthropic-ai/claude-code"
    "opencode-ai"
  ];
in
{
  programs = {
    # JavaScript/TypeScript runtimes and package managers
    zsh.shellAliases = {
      # Development tools
      tscl = "tsc --noEmit"; # TypeScript check
      tscw = "tsc --watch"; # TypeScript watch mode
      tscb = "tsc --build"; # TypeScript build
      el = "eslint --fix"; # Fix ESLint issues
      pf = "prettier --write"; # Format with Prettier
      jt = "jest --watch"; # Jest watch mode
      vt = "npx vitest"; # Run Vitest
      pt = "npx playwright"; # Run Playwright tests
    };

    # Git ignore patterns for JavaScript/TypeScript projects
    git.ignores = [
      # Dependencies
      "node_modules/" # Node.js dependencies
      "bun.lockb" # Bun lockfile
      ".pnpm-debug.log*" # pnpm debug logs
      ".yarn/install-state.gz" # Yarn install state
      ".yarn/cache" # Yarn cache
      ".yarn/build-state.yml" # Yarn build state

      # Build outputs
      "dist/" # Distribution folder
      "build/" # Build output
      ".next/" # Next.js build output
      ".nuxt/" # Nuxt.js build output
      ".output/" # Nuxt.js output
      ".vercel/" # Vercel deployment
      ".netlify/" # Netlify deployment

      # Environment and config
      ".env" # Environment variables
      ".env.local" # Local environment
      ".env.development.local" # Development environment
      ".env.test.local" # Test environment
      ".env.production.local" # Production environment

      # Logs
      "logs" # Log files
      "*.log" # All log files
      "npm-debug.log*" # npm debug logs
      "yarn-debug.log*" # yarn debug logs
      "yarn-error.log*" # yarn error logs

      # Runtime data
      "pids" # Process IDs
      "*.pid" # PID files
      "*.seed" # Seed files
      "*.pid.lock" # PID lock files

      # Coverage directory used by tools like istanbul
      "coverage/" # Coverage reports
      "*.lcov" # LCOV coverage files

      # nyc test coverage
      ".nyc_output" # NYC coverage output

      # Dependency directories
      "jspm_packages/" # jspm packages

      # Optional npm cache directory
      ".npm" # npm cache

      # Optional eslint cache
      ".eslintcache" # ESLint cache

      # Microbundle cache
      ".rpt2_cache/" # Rollup TypeScript cache
      ".rts2_cache_cjs/" # RTS2 cache
      ".rts2_cache_es/" # RTS2 cache
      ".rts2_cache_umd/" # RTS2 cache

      # Optional REPL history
      ".node_repl_history" # Node REPL history

      # Output of 'npm pack'
      "*.tgz" # npm pack output

      # Yarn Integrity file
      ".yarn-integrity" # Yarn integrity

      # parcel-bundler cache (https://parceljs.org/)
      ".cache" # Parcel cache
      ".parcel-cache" # Parcel cache

      # Next.js build output
      ".next" # Next.js build

      # Nuxt.js build / generate output
      ".nuxt" # Nuxt.js build

      # Gatsby files
      ".cache/" # Gatsby cache
      "public" # Gatsby public folder

      # Storybook build outputs
      ".out" # Storybook output
      ".storybook-out" # Storybook output

      # Temporary folders
      "tmp/" # Temporary files
      "temp/" # Temporary files

      # Editor directories and files
      ".vscode/" # VSCode settings
      ".idea" # IntelliJ IDEA
      "*.swp" # Vim swap files
      "*.swo" # Vim swap files
      "*~" # Backup files

      # OS generated files
      ".DS_Store" # macOS
      ".DS_Store?" # macOS
      "._*" # macOS
      ".Spotlight-V100" # macOS
      ".Trashes" # macOS
      "ehthumbs.db" # Windows
      "Thumbs.db" # Windows
    ];
  };

  # JavaScript/TypeScript development environment configuration
  home = {
    # Essential JavaScript/TypeScript development packages
    packages = with pkgs; [
      # Core runtimes
      nodejs # Node.js JavaScript runtime
      bun # Bun JavaScript runtime and toolkit
      deno # Deno JavaScript/TypeScript runtime

      # Package managers
      pnpm # Fast npm alternative package manager
      yarn # Yarn package manager

      # Language servers and IDE support
      typescript-language-server # TypeScript language server
      vscode-langservers-extracted # HTML/CSS/JSON/ESLint language servers
      emmet-language-server # Emmet support for HTML/CSS
      tailwindcss-language-server # Tailwind CSS language server

      # Linters and formatters
      eslint # JavaScript/TypeScript linter
      prettier # Code formatter
      stylelint # CSS/SCSS linter
      eslint_d # Fast ESLint daemon
      biome # JavaScript/TypeScript formatter

      # Build tools and bundlers
      vite # Next generation frontend tooling
      esbuild # Extremely fast JavaScript bundler
      swc # Super-fast TypeScript/JavaScript compiler

      # Development servers and tools
      live-server # Simple development server
      http-server # Simple static HTTP server

      # Package development tools
      np # Better npm publish
      commitizen # Conventional commit helper

      # Database and API tools
      prisma # Database toolkit and ORM
      graphql-language-service-cli # GraphQL language service

      # Cloud and deployment
      netlify-cli # Netlify CLI
      supabase-cli # Supabase CLI

      # Container and orchestration
      dockerfile-language-server # Dockerfile language server
    ];

    # Environment variables for JavaScript/TypeScript development
    sessionVariables = {
      # Node.js configuration
      NODE_ENV = "development"; # Default to development mode
      NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global"; # Global npm packages location
      PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm"; # pnpm home directory
      BUN_INSTALL = "${config.home.homeDirectory}/.bun"; # Bun installation directory

      # SSL certificate configuration for Node.js
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"; # System CA certificates
      NODE_EXTRA_CA_CERTS = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"; # Extra CA certificates for Node.js

      # Enable corepack for package manager management
      COREPACK_ENABLE_AUTO_PIN = "1"; # Auto-pin package managers
      COREPACK_DEFAULT_TO_LATEST = "0"; # Don't default to latest versions
    };

    # Add JavaScript/TypeScript binaries to system PATH
    sessionPath = [
      "${config.home.homeDirectory}/.npm-global/bin" # Global npm packages
      "${config.home.homeDirectory}/.bun/bin" # Bun binaries
      "${config.home.homeDirectory}/.cache/.bun/bin" # Bun global packages
      "${config.home.homeDirectory}/.local/share/pnpm" # pnpm binaries
      "${config.home.homeDirectory}/.deno/bin" # Deno binaries
      "${pkgs.bun}/bin" # Bun binaries
    ];

    # Automatic workspace directory creation and global package installation
    activation.createJSWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BUN_BIN="${pkgs.bun}/bin/bun"  # Use Bun from Nix directly

      # Create workspace directories
      $DRY_RUN_CMD mkdir -p $HOME/Projects/javascript
      $DRY_RUN_CMD mkdir -p $HOME/Projects/typescript
      $DRY_RUN_CMD mkdir -p $HOME/Projects/react
      $DRY_RUN_CMD mkdir -p $HOME/Projects/node
      $DRY_RUN_CMD mkdir -p $HOME/.npm-global

      # Configure npm to use global directory
      if command -v npm &> /dev/null; then
        $DRY_RUN_CMD npm config set prefix "$HOME/.npm-global"
      fi

      # Install/update global npm packages using Bun
      if [ -x "$BUN_BIN" ]; then
        echo "📦 Managing global npm packages with Bun..."
        for package in ${lib.escapeShellArgs globalNpmPackages}; do
          if "$BUN_BIN" pm ls -g | grep -q "$package"; then
            echo "Updating $package..."
            "$BUN_BIN" update -g "$package" || echo "❌ Failed to update $package"
          else
            echo "Installing $package..."
            "$BUN_BIN" install -g "$package" || echo "❌ Failed to install $package"
          fi
        done
        echo "✔ Global packages management completed"
      else
        echo "⚠️ Bun not found at $BUN_BIN"
      fi
    '';
  };
}
