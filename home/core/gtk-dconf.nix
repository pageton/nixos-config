_: {
  gtk = {
    gtk4.theme = null;
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gtk/settings/file-chooser" = {
      sort-directories-first = true;
    };
    "org/gnome/desktop/privacy" = {
      remember-recent-files = false;
      recent-files-max-age = 0;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      old-files-age = 7;
    };
  };
}
