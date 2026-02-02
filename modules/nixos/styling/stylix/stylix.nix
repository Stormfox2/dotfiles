{
  config,
  pkgs,
  lib,
  isLaptop,
  ...
}:

let
  cfg = config.qnix.styling.stylix;
  inherit (lib) mkEnableOption mkIf;
  breezeGtkIcons = pkgs.runCommand "breeze-gtk-icons" { } ''
        mkdir -p $out/share/icons/Breeze-GTK
        cat > $out/share/icons/Breeze-GTK/index.theme <<'EOF'
    [Icon Theme]
    Name=Breeze-GTK
    Comment=Breeze icons with GTK-friendly fallbacks
    Inherits=breeze-dark,Adwaita,hicolor
    EOF
  '';
in
{
  options.qnix.styling.stylix = {
    enable = mkEnableOption "stylix style manager" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    # Ensure the inherited themes are actually installed somewhere in your profiles:
    environment.systemPackages = [
      pkgs.kdePackages.breeze-icons
      pkgs.adwaita-icon-theme
    ];
    stylix = {
      enable = true;
      overlays.enable = false;

      base16Scheme = "${pkgs.base16-schemes}/share/themes/solarized-dark.yaml";
      # override = {
      #   base00 = "#001e26";
      #   base01 = "#002731";
      #   base02 = "#006388";
      #   base03 = "#3a8298";
      #   base04 = "#74a2a9";
      #   base05 = "#aec2ba";
      #   base06 = "#e9e2cb";
      #   base07 = "#fcf4dc";
      #   base08 = "#d01b24";
      #   base09 = "#a57705";
      #   base0A = "#178dc7";
      #   base0B = "#6bbe6c";
      #   base0C = "#259185";
      #   base0D = "#2075c7";
      #   base0E = "#c61b6e";
      #   base0F = "#680d12";
      # };
      image = ./wallpapers/solarized-dark.png;
      polarity = "dark";

      # Fix issues with overlays: https://github.com/danth/stylix/issues/865
      targets.gnome-text-editor.enable = lib.mkForce false;

      cursor = {
        package = pkgs.simp1e-cursors;
        name = "Simp1e-Solarized-Dark";
        size = 24;
      };

      opacity = {
        applications = 0.5;
        terminal = 0.5;
      };

      icons = {
        enable = true;

        package = pkgs.fluent-icon-theme;
        dark = "Fluent-dark";
        light = "Fluent-light";
        #        package = pkgs.whitesur-icon-theme;
        #        dark = "WhiteSur-dark";
        #        light = "WhiteSur-light";
      };

      fonts = {
        serif = {
          package = pkgs.fira-sans;
          name = "Fira Sans";
        };

        sansSerif = {
          package = pkgs.fira-sans;
          name = "Fira Sans";
        };

        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrains Mono Nerd Font";
        };

        emoji = {
          package = pkgs.noto-fonts-color-emoji;
          name = "Noto Color Emoji";
        };

        sizes = {
          applications = if isLaptop then 12 else 16;
          desktop = if isLaptop then 12 else 16;
          popups = if isLaptop then 12 else 16;
          terminal = if isLaptop then 12 else 16;
        };
      };
    };
  };
}
