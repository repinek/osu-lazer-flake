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

  # osu's game.ini accepts only these types
  settingsType =
    with types;
    attrsOf (oneOf [
      bool
      int
      float
      str
    ]);

  # isValid checks
  # I wrote these comments for myself, since I am not very good in Nix syntax, and it's looks weird for me
  isValidRelativePath =
    path:
    path != "" # Path is not empty
    && !hasPrefix "/" path # Path does not start with "/"
    && !hasInfix "\n" path # Path does not have "\n"
    && !(any (part: part == "..") (splitString "/" path)); # Path does not have ".."

  isValidSettingName = name: !hasInfix "\n" name && !hasInfix "=" name; # Setting Name does not have "\n" or "="
  isValidSettingValue = value: !builtins.isString value || !hasInfix "\n" value; # Setting Value (strings) does not have "\n"

  isValidSettings =
    settings:
    all (name: isValidSettingName name && isValidSettingValue settings.${name}) (attrNames settings);

  # Settings and files utils
  osuDataDirectory = "${config.xdg.dataHome}/osu";
  customStoragePath = "${config.home.homeDirectory}/${cfg.storagePath}";

  # osu's game.ini require boolean UpperCase
  formatValue =
    value: if builtins.isBool value then if value then "True" else "False" else toString value;

  # Format and render osu's settings
  renderSettings =
    settings:
    concatStringsSep "\n" (mapAttrsToList (name: value: "${name} = ${formatValue value}") settings)
    + "\n";

  # Create nix store file with written settings
  writeSettingsFile = name: settings: pkgs.writeText name (renderSettings settings);
  defaultSettingsSource = writeSettingsFile "osu-lazer-default-settings.ini" cfg.defaultSettings;

  configuredFiles = filterAttrs (_: file: file.settings != { }) cfg.files;

  # Generate activation commands for each data directory (files)
  filesSettingsScript = concatStringsSep "\n" (
    mapAttrsToList (
      path: file:
      let
        target = "${config.home.homeDirectory}/${path}/game.ini";
        settingsSource = writeSettingsFile "osu-lazer-file-settings-${builtins.hashString "sha256" path}.ini" file.settings;
      in
      ''
        run ${mergeIni} ${escapeShellArg target} ${escapeShellArg (toString settingsSource)}
      ''
    ) configuredFiles
  );

  # Merge managed settings from the Nix store into a mutable game.ini file
  # Configured keys override existing values and duplicates are removed
  # Unmanaged settings are preserved
  #
  # This is working like that, because Token, leaderboard status, skin, and
  # other mutable values cannot be stored in immutable Nix store
  # Game will be just unplayable then
  mergeIni = pkgs.writeShellScript "osu-lazer-merge-ini" ''
    set -eu

    target="$1"
    managed="$2"
    targetDirectory="$(${pkgs.coreutils}/bin/dirname -- "$target")"

    ${pkgs.coreutils}/bin/mkdir -p -- "$targetDirectory"
    ${pkgs.coreutils}/bin/touch -- "$target"

    temporaryFile="$(${pkgs.coreutils}/bin/mktemp "$targetDirectory/.osu-lazer-merge.XXXXXX")"
    trap '${pkgs.coreutils}/bin/rm -f -- "$temporaryFile"' EXIT

    ${pkgs.gawk}/bin/awk -v output="$temporaryFile" '
      NR == FNR {
        separator = index($0, " = ")
        key = substr($0, 1, separator - 1)
        value = substr($0, separator + 3)
        wanted[key] = value
        order[++count] = key
        next
      }

      {
        separator = index($0, " = ")
        key = separator == 0 ? "" : substr($0, 1, separator - 1)

        if (key in wanted) {
          if (!(key in written)) {
            print key " = " wanted[key] > output
            written[key] = 1
          }
          next
        }

        print $0 > output
      }

      END {
        for (i = 1; i <= count; i++) {
          key = order[i]
          if (!(key in written)) {
            print key " = " wanted[key] > output
          }
        }
      }
    ' "$managed" "$target"

    ${pkgs.coreutils}/bin/chmod --reference="$target" -- "$temporaryFile"
    ${pkgs.coreutils}/bin/mv -f -- "$temporaryFile" "$target"
    trap - EXIT
  '';
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

    storagePath = mkOption {
      type = types.nullOr types.str;
      default = null;
    };

    defaultSettings = mkOption {
      type = settingsType;
      default = { };
    };

    files = mkOption {
      type = types.attrsOf (
        types.submodule (
          { ... }:
          {
            options.settings = mkOption {
              type = settingsType;
              default = { };
            };
          }
        )
      );
      default = { };
    };
  };

  config = mkIf cfg.enable {
    # messages are very self-explanatory here
    assertions = [
      {
        assertion = cfg.storagePath == null || isValidRelativePath cfg.storagePath;
        message = "programs.osu-lazer.storagePath must be a non-empty relative path without '..'";
      }
      {
        assertion = all isValidRelativePath (attrNames cfg.files);
        message = "programs.osu-lazer.files keys must be non-empty relative paths without '..'";
      }
      {
        assertion = isValidSettings cfg.defaultSettings;
        message = "programs.osu-lazer.defaultSettings keys cannot contain '=' or newlines, and string values cannot contain newlines";
      }
      {
        assertion = all (file: isValidSettings file.settings) (attrValues cfg.files);
        message = "programs.osu-lazer.files.<path>.settings keys cannot contain '=' or newlines, and string values cannot contain newlines";
      }
    ];

    home.packages = optional (cfg.package != null) (
      cfg.package.override {
        inherit (cfg) nativeWayland;
      }
    );

    home.activation = mkMerge [
      (mkIf (cfg.storagePath != null) {
        osuLazerStoragePath = hm.dag.entryAfter [ "writeBoundary" ] ''
          storageFile=${escapeShellArg "${osuDataDirectory}/storage.ini"}

          run mkdir -p ${escapeShellArg osuDataDirectory}
          run printf '%s\n' ${escapeShellArg "FullPath = ${customStoragePath}"} > "$storageFile"
        '';
      })

      (mkIf (cfg.defaultSettings != { }) {
        osuLazerDefaultSettings = hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${mergeIni} ${escapeShellArg "${osuDataDirectory}/game.ini"} ${escapeShellArg (toString defaultSettingsSource)}
        '';
      })

      (mkIf (configuredFiles != { }) {
        osuLazerFileSettings = hm.dag.entryAfter [ "writeBoundary" ] ''
          ${filesSettingsScript}
        '';
      })
    ];
  };
}
