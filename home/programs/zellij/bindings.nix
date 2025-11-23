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
        "bind \"Left\"" = {
          GoToPreviousTab = { };
        };
        "bind \"Right\"" = {
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
      };

      scroll = {
        "bind \"Alt s\" \"Esc\"" = {
          SwitchToMode = "Normal";
        };
        "bind \"e\"" = {
          EditScrollback = { };
          SwitchToMode = "Normal";
        };
        "bind \"Down\"" = {
          ScrollDown = { };
        };
        "bind \"Up\"" = {
          ScrollUp = { };
        };
      };
    };
  };
}
