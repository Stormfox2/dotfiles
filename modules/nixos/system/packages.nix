{
  lib,
  config,
  ...
}:

let
  cfg = config.qnix.system.packages;
in
{
  options.qnix.system.packages = with lib; {
    git.install = mkEnableOption "git install";
    tree.install = mkEnableOption "tree install";
    yubico.install = mkEnableOption "yubico software";
    helix.install = mkEnableOption "helix";
    kitty.install = mkEnableOption "kitty";
    nemo.install = mkEnableOption "nemo" // {
      default = true;
    };
  };

  config.environment.variables = {
    NIXPKGS_ALLOW_UNFREE = 1;
  };

  # MOVED TO ./environment
  #  config = with lib; {
  #    environment.systemPackages = concatLists [
  #      (lists.optionals cfg.git.install [ pkgs.git ])
  #      (lists.optionals cfg.tree.install [ pkgs.tree ])
  #    ];
  #  };
}
