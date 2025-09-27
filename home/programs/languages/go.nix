# Go programming language configuration.
# This module configures the Go programming language environment
# with development tools, LSP support, and project workspace setup.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    go = {
      enable = true; # Enable Go programming language
      package = pkgs.go; # Use the standard Go package

      # Go environment configuration
      env = {
        GOPATH = "go"; # GOPATH relative to home directory
        GOBIN = "go/bin"; # GOBIN relative to home directory
        # Private Go modules (for private repositories)
        GOPRIVATE = [ ]; # Add private module patterns here

      };
    };

    # Zsh shell aliases for efficient Go development
    zsh.shellAliases = {
      # Core Go commands with shortcuts
      gorun = "go run"; # Run Go programs
      gobuild = "go build"; # Build Go binaries
      gotest = "go test -v"; # Run tests with verbose output
      gomod = "go mod"; # Go module management
      gofmt = "gofumpt -w"; # Format Go code with gofumpt
      golint = "golangci-lint run"; # Run comprehensive linter
      goair = "air"; # Live reload with Air

      # Debugging commands
      godebug = "dlv debug"; # Start Delve debugger
      gotrace = "dlv trace"; # Trace program execution
    };

    # Git ignore patterns for Go projects
    git.ignores = [
      # Go-specific build artifacts and dependencies
      "vendor/" # Vendored dependencies
      "*.exe" # Windows executables
      "*.exe~" # Windows executable backups
      "*.dll" # Dynamic link libraries
      "*.so" # Shared object libraries
      "*.dylib" # macOS dynamic libraries
      "*.test" # Test binaries
      "*.out" # Output files
      "go.work" # Go workspace file
      "go.work.sum" # Go workspace checksums
    ];
  };

  # Go development environment configuration
  home = {
    # Essential Go development packages
    packages = with pkgs; [
      # Core language server and tools
      gopls # Go language server for IDE support
      go-tools # Collection of Go development tools
      delve # Go debugger
      golangci-lint # Comprehensive Go linter
      air # Live reload for Go applications

      # Code formatting and generation
      gofumpt # Stricter version of gofmt
      golines # Go line formatter
      gotests # Generate Go test functions
      impl # Generate interface implementations
      gomodifytags # Modify struct field tags
      goimports-reviser # Go imports formatter

      # Security and quality tools
      govulncheck # Go vulnerability checker

      # Database and API tools
      go-migrate # Database migration tool
      sqlc # Generate Go code from SQL queries
      protobuf # Protocol buffer compiler
      protoc-gen-go # Go protobuf code generator
      protoc-gen-go-grpc # gRPC Go code generator
    ];

    # Environment variables for Go development
    sessionVariables = {
      GOPATH = "${config.home.homeDirectory}/go"; # Go workspace path
      GOBIN = "${config.home.homeDirectory}/go/bin"; # Go binary installation path
      GO111MODULE = "on"; # Enable Go modules
      GOPROXY = "https://proxy.golang.org,direct"; # Go module proxy
      GOSUMDB = "sum.golang.org"; # Go checksum database
    };

    # Add Go binaries to system PATH
    sessionPath = [
      "${config.home.homeDirectory}/go/bin" # Include Go bin in PATH
    ];

    # Automatic workspace directory creation
    activation.createGoWorkspace = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p $HOME/go/{bin,pkg,src}       # Create Go workspace structure
      $DRY_RUN_CMD mkdir -p $HOME/Projects/go            # Create projects directory
    '';
  };
}
