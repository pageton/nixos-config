{
  ...
}:
{
  programs.zellij.settings = {
    "keybinds clear-defaults=true" = {
      normal = {
        "bind \"Alt n\"" = {
          SwitchToMode = "Resize";
        };
        "bind \"Alt p\"" = {
          SwitchToMode = "Pane";
        };
        "bind \"Alt h\"" = {
          SwitchToMode = "Move";
        };
        "bind \"Alt t\"" = {
          SwitchToMode = "Tab";
        };
        "bind \"Alt s\"" = {
          SwitchToMode = "Scroll";
        };
        "bind \"Alt r\"" = {
          Run = {
            _args = ["zellij" "setup" "--check"];
          };
        };
        "bind \"Alt 1\"" = { GoToTab = 1; };
        "bind \"Alt 2\"" = { GoToTab = 2; };
        "bind \"Alt 3\"" = { GoToTab = 3; };
        "bind \"Alt 4\"" = { GoToTab = 4; };
        "bind \"Alt 5\"" = { GoToTab = 5; };
        "bind \"Alt 6\"" = { GoToTab = 6; };
        "bind \"Alt 7\"" = { GoToTab = 7; };
        "bind \"Alt 8\"" = { GoToTab = 8; };
        "bind \"Alt 9\"" = { GoToTab = 9; };
        "bind \"Alt Enter\"" = { NewTab = { }; };
        "bind \"Alt [\"" = { SwitchToMode = "Scroll"; }; # tmux-style: Alt+[ → scroll mode
      };

      resize = {
        "bind \"Alt n\" \"Esc\"" = {
          SwitchToMode = "Normal";
        };
        "bind \"Left\"" = {
          Resize = "Increase Left";
        };
        "bind \"Down\"" = {
          Resize = "Increase Down";
        };
        "bind \"Up\"" = {
          Resize = "Increase Up";
        };
        "bind \"Right\"" = {
          Resize = "Increase Right";
        };
        "bind \"=\" \"+\"" = {
          Resize = "Increase";
        };
        "bind \"-\"" = {
          Resize = "Decrease";
        };
      };

      pane = {
        "bind \"Alt p\" \"Esc\"" = {
          SwitchToMode = "Normal";
        };
        "bind \"Left\"" = {
          MoveFocus = "Left";
        };
        "bind \"Right\"" = {
          MoveFocus = "Right";
        };
        "bind \"Down\"" = {
          MoveFocus = "Down";
        };
        "bind \"Up\"" = {
          MoveFocus = "Up";
        };
        "bind \"p\"" = {
          SwitchFocus = { };
          SwitchToMode = "Normal";
        };
        "bind \"n\"" = {
          NewPane = { };
          SwitchToMode = "Normal";
        };
        "bind \"d\"" = {
          NewPane = "Down";
          SwitchToMode = "Normal";
        };
        "bind \"r\"" = {
          NewPane = "Right";
          SwitchToMode = "Normal";
        };
        "bind \"s\"" = {
          NewPane = "stacked";
          SwitchToMode = "Normal";
        };
        "bind \"x\"" = {
          CloseFocus = { };
          SwitchToMode = "Normal";
        };
        "bind \"w\"" = {
          ToggleFloatingPanes = { };
          SwitchToMode = "Normal";
        };
        "bind \"e\"" = {
          TogglePaneEmbedOrFloating = { };
          SwitchToMode = "Normal";
        };
        "bind \"i\"" = {
          TogglePanePinned = { };
          SwitchToMode = "Normal";
        };
      };

      move = {
        "bind \"Alt h\" \"Esc\"" = {
          SwitchToMode = "Normal";
        };
        "bind \"n\" \"Tab\"" = {
          MovePane = { };
        };
        "bind \"p\"" = {
          MovePaneBackwards = { };
        };
        "bind \"Left\"" = {
          MovePane = "Left";
        };
        "bind \"Down\"" = {
          MovePane = "Down";
        };
        "bind \"Up\"" = {
          MovePane = "Up";
        };
        "bind \"Right\"" = {
          MovePane = "Right";
        };
      };

      tab = {
        "bind \"Alt t\" \"Esc\"" = {
          SwitchToMode = "Normal";
        };
        "bind \"Left\" \"h\"" = {
          GoToPreviousTab = { };
        };
        "bind \"Right\" \"l\"" = {
          GoToNextTab = { };
        };
        "bind \"n\"" = {
          NewTab = { };
          SwitchToMode = "Normal";
        };
        "bind \"x\"" = {
          CloseTab = { };
          SwitchToMode = "Normal";
        };
        "bind \"1\"" = { GoToTab = 1; SwitchToMode = "Normal"; };
        "bind \"2\"" = { GoToTab = 2; SwitchToMode = "Normal"; };
        "bind \"3\"" = { GoToTab = 3; SwitchToMode = "Normal"; };
        "bind \"4\"" = { GoToTab = 4; SwitchToMode = "Normal"; };
        "bind \"5\"" = { GoToTab = 5; SwitchToMode = "Normal"; };
        "bind \"6\"" = { GoToTab = 6; SwitchToMode = "Normal"; };
        "bind \"7\"" = { GoToTab = 7; SwitchToMode = "Normal"; };
        "bind \"8\"" = { GoToTab = 8; SwitchToMode = "Normal"; };
        "bind \"9\"" = { GoToTab = 9; SwitchToMode = "Normal"; };
      };

      scroll = {
        "bind \"Esc\"" = {
          SwitchToMode = "Normal";
        };
        "bind \"e\"" = {
          EditScrollback = { };
          SwitchToMode = "Normal";
        };
        "bind \"Down\" \"j\"" = {
          ScrollDown = { };
        };
        "bind \"Up\" \"k\"" = {
          ScrollUp = { };
        };
        "bind \"d\"" = {
          HalfPageScrollDown = { };
        };
        "bind \"u\"" = {
          HalfPageScrollUp = { };
        };
        "bind \"g\"" = {
          ScrollToTop = { };
        };
        "bind \"G\"" = {
          ScrollToBottom = { };
        };
      };
    };
  };
}
