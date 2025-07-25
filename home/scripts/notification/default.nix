{ pkgs, ... }:
let
  notif = pkgs.writeShellScriptBin "notif" ''
    NOTIF_FOLDER="/tmp/notif"
    sender_id=$1
    title=$2
    description=$3

    [[ -d "$NOTIF_FOLDER" ]] || mkdir $NOTIF_FOLDER
    [[ -f "$NOTIF_FOLDER/$sender_id" ]] || (echo "0" > "$NOTIF_FOLDER/$sender_id")

    old_notification_id=$(cat "$NOTIF_FOLDER/$sender_id")
    [[ -z "$old_notification_id" ]] && old_notification_id=0

     ${pkgs.libnotify}/bin/notify-send \
    --replace-id="$old_notification_id" --print-id \
    --app-name="$sender_id" \
    "$title" \
    "$description" \
    > "$NOTIF_FOLDER/$sender_id"
  '';

in
{
  home.packages = [ notif ];
}
