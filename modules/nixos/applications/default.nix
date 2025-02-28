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
    ./general/hyprsuite/hyprsuite.nix
    ./gui/chromium/chromium.nix
  ];
}
