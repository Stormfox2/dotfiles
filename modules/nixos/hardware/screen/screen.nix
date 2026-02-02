{
  lib,
  config,
  user,
  pkgs,
  ...
}:

let
  cfg = config.hm.qnix.hardware.screen;
  inherit (lib) mkIf;
in
{
  config = mkIf cfg.enable {
    services.hardware.bolt.enable = true;

    programs.light = {
      enable = true;
      brightnessKeys = {
        enable = true;
        step = 10;
      };
    };

    users.users.${user}.extraGroups = [
      "video"
    ];

    qnix.persist = {
      root.directories = [ "/etc/light" ];
      home.directories = [ ".config/light" ];
    };
  };
}
