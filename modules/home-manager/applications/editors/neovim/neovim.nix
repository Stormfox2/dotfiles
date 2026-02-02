{
  config,
  lib,
  pkgs,
  dots,
  ...
}:

let
  cfg = config.qnix.applications.editors.neovim;
in
{
  options.qnix.applications.editors.neovim = with lib; {
    enable = mkEnableOption "neovim" // {
      default = true;
    };
    default = mkEnableOption "set neovim to default editor" // {
      default = true;
    };
  };

  config = {
    qnix.persist.home = {
      directories = [
        ".local/share/nvf/site/spell"
      ];
    };

    programs = {
      nvf = {
        inherit (cfg) enable;
        defaultEditor = cfg.default;
        settings = {
          vim = {

            spellcheck = {
              enable = true;
              programmingWordlist.enable = true; # :DirtytalkUpdate
            };

            options = {
              expandtab = true;
              shiftwidth = 2;
              tabstop = 2;
            };

            lsp = {
              enable = true;
              formatOnSave = true;
              lightbulb.enable = true;
              lspkind.enable = true;

              servers = {
                nixd = lib.mkIf (dots != null) {
                  enable = true;
                  options = {
                    nixos = {
                      expr = ''(builtins.getFlake "${dots}").nixosConfigurations."QFrame13".options'';
                    };
                    home-manager = {
                      expr = ''(builtins.getFlake "${dots}").homeConfigurations."QFrame13".options'';
                    };
                  };
                };
                pyright = {
                  enable = true;
                };
                clangd = {
                  enable = true;
                };
              };
            };

            treesitter = {
              enable = true;
              highlight.enable = true;
              indent.enable = true;
              autotagHtml = true;
            };

            languages = {
              nix.enable = true;
              python.enable = true;
              clang.enable = true;
            };

            formatter.conform-nvim = {
              enable = true;
              setupOpts = {
                formatters_by_ft = {
                  nix = [ "nixfmt-rfc-style" ];
                };
                formatters = {
                  "nixfmt-rfc-style" = {
                    command = "${lib.getExe pkgs.nixfmt-rfc-style}";
                  };
                };
              };
            };

            autopairs.nvim-autopairs.enable = true;

            autocomplete.nvim-cmp = {
              enable = true;

              sources = {
                path = "[Path]";
              };
            };

            luaConfigRC = {

              "00-disable-deprecations" = ''
                vim.deprecate = function() end
              '';
            };
          };
        };

      };
    };
  };
}
