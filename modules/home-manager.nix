{ self }:
{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.osu-lazer;

  osuPackages = self.packages.${pkgs.stdenv.hostPlatform.system};

  # osu!'s INI files accept only these value types
  iniSettingsType =
    with types;
    attrsOf (oneOf [
      bool
      int
      float
      str
    ]);
in
{
  options.programs.osu-lazer = {
    enable = mkEnableOption "osu-lazer";

    package = mkPackageOption osuPackages "osu-lazer-bin" {
      nullable = true;
      pkgsText = "inputs.osu-lazer.packages.\${pkgs.stdenv.hostPlatform.system}";
    };

    nativeWayland = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable native Wayland support.";
    };

    channel = mkOption {
      type = types.enum [
        "lazer"
        "tachyon"
      ];
      default = "lazer";
      description = "Release channel to use, selecting tachyon only while it is newer than lazer";
    };

    extraShellArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = lib.literalExpression ''
        # Enables double buffering and sets PipeWire latency to 256/48000 for osu!
        [
          "--set" "SDL_VIDEO_DOUBLE_BUFFER" "1"
          "--set" "PIPEWIRE_LATENCY" "256/48000"
        ];
      '';
      description = "Additional arguments passed to the osu! wrapper.";
    };

    storagePath = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = lib.literalExpression ''
        "/home/alice/Games/osu"
      '';
      description = "Absolute path to the osu! game data directory.";
    };

    gameSettings = mkOption {
      type = iniSettingsType;
      default = { };
      example = lib.literalExpression ''
        {
          DimLevel = 1.0;
          KeyOverlay = true;
          IntroSequence = "Random";
          ReleaseStream = "Tachyon"; # Select Tachyon as release stream, effects only notification in game
        }
      '';
      description = "Settings to write to game.ini.";
    };

    frameworkSettings = mkOption {
      type = iniSettingsType;
      default = { };
      example = lib.literalExpression ''
        {
          Locale = "en";
          VolumeMusic = 0.42;
        }
      '';
      description = "Settings to write to framework.ini.";
    };

    files = mkOption {
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options.gameSettings = mkOption {
              type = iniSettingsType;
              default = { };
            };

            options.frameworkSettings = mkOption {
              type = iniSettingsType;
              default = { };
            };
          }
        )
      );
      default = { };
      example = lib.literalExpression ''
        "/home/alice/Games/osu" = {
          gameSettings = { };
          frameworkSettings = { };
        };
      '';
      description = "Independent osu! game data directories. Use absolute path.";
    };
  };

  imports = [ ./home-manager/activation.nix ];

  config = mkIf cfg.enable {
    home.packages = optional (cfg.package != null) (
      cfg.package.override {
        inherit (cfg) channel nativeWayland extraShellArgs;
      }
    );
  };
}
