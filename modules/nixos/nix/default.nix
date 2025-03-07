{
  lib,
  config,
  ...
}:

let
  cfg = config.qnix.nix;
in
{
  imports = [
    ./sops.nix
    ./nh.nix
    ./impermanence.nix
  ];

  config.qnix.nix = with lib; {
    nh = {
      enable = mkDefault true;
      clean.enable = mkDefault true;
    };
  };
}
