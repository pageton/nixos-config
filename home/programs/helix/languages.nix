{
  programs.helix.languages = {
    language-server.gopls = {
      command = "gopls";
      config = {
        gofumpt = true;
        staticcheck = false;
        analyses = {
          unusedparams = true;
          shadow = true;
          unreachable = true;
        };
        hints = {
          assignVariableTypes = true;
          compositeLiteralFields = true;
          compositeLiteralTypes = true;
          constantValues = true;
          functionTypeParameters = true;
          parameterNames = true;
          rangeVariableTypes = true;
        };
        codelenses = {
          generate = false;
          gc_details = true;
        };
        completeUnimported = true;
        usePlaceholders = true;
        hoverKind = "FullDocumentation";
        linksInHover = true;
        experimentalPostfixCompletions = true;
        verboseOutput = false;
      };
    };

    language-server.tabby-ml = {
      command = "npx";
      args = [
        "tabby-agent"
        "--lsp"
        "--stdio"
      ];
    };

    language = [
      {
        name = "go";
        language-servers = [
          "gopls"
          "tabby-ml"
        ];
        auto-format = true;
        formatter = {
          command = "gofumpt";
          args = [ ];
        };
        comment-token = "//";
      }
      {
        name = "nix";
        language-servers = [
          "nixd"
          "nil"
          "tabby-ml"
        ];
      }
    ];
  };
}
