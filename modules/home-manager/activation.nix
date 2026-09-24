{
  lib,
  pkgs,
  config,
  ...
}:
with lib;
let
  cfg = config.programs.osu-lazer;

  ini = import ./ini.nix { inherit pkgs lib; };

  osuDataDirectory = "${config.xdg.dataHome}/osu";
  customStoragePath = "${config.home.homeDirectory}/${cfg.storagePath}";

  hasFileSettings = file: file.gameSettings != { } || file.frameworkSettings != { };

  hasAnySettings =
    cfg.gameSettings != { }
    || cfg.frameworkSettings != { }
    || any hasFileSettings (attrValues cfg.files);

  filesIniSettingsScript = concatStringsSep "\n" (
    mapAttrsToList (
      path: file:
      let
        directory = "${config.home.homeDirectory}/${path}";
      in
      ''
        ${optionalString (file.gameSettings != { }) (
          ini.mergeIniFile "${directory}/game.ini" file.gameSettings
        )}

        ${optionalString (file.frameworkSettings != { }) (
          ini.mergeIniFile "${directory}/framework.ini" file.frameworkSettings
        )}
      ''
    ) (filterAttrs (_: file: hasFileSettings file) cfg.files)
  );
in
{
  config = mkIf cfg.enable {
    home.activation = mkMerge [
      (mkIf (cfg.storagePath != null) {
        osuLazerStoragePath = hm.dag.entryAfter [ "writeBoundary" ] ''
          storageFile=${escapeShellArg "${osuDataDirectory}/storage.ini"}

          run mkdir -p ${escapeShellArg osuDataDirectory}
            run printf '%s\n' ${escapeShellArg "FullPath = ${customStoragePath}"} > "$storageFile"
        '';
      })

      (mkIf hasAnySettings {
        osuLazerSettings = hm.dag.entryAfter [ "writeBoundary" ] ''
          ${optionalString (cfg.gameSettings != { }) (
            ini.mergeIniFile "${osuDataDirectory}/game.ini" cfg.gameSettings
          )}
          ${optionalString (cfg.frameworkSettings != { }) (
            ini.mergeIniFile "${osuDataDirectory}/framework.ini" cfg.frameworkSettings
          )}

          ${filesIniSettingsScript}
        '';
      })
    ];
  };
}
