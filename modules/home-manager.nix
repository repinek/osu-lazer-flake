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

  # osu's INI files only accepts these types
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
    };

    storagePath = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    gameSettings = mkOption {
      type = iniSettingsType;
      default = { };
    };

    frameworkSettings = mkOption {
      type = iniSettingsType;
      default = { };
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
    };
  };

  imports = [ ./home-manager/activation.nix ];

  config = mkIf cfg.enable {
    # TODO assertions
    home.packages = optional (cfg.package != null) (
      cfg.package.override {
        inherit (cfg) channel nativeWayland;
      }
    );
  };
}
