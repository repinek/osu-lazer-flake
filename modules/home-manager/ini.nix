{ lib, pkgs }:
rec {
  formatValue =
    value: if builtins.isBool value then if value then "True" else "False" else builtins.toString value;

  renderSettings =
    settings:
    builtins.concatStringsSep "\n" (
      lib.mapAttrsToList (name: value: "${name} = ${formatValue value}") settings
    )
    + "\n";

  writeSettingsFile = name: settings: pkgs.writeText name (renderSettings settings);

  mergeIniFile =
    target: settings:
    let
      source = writeSettingsFile "osu-lazer-settings.ini" settings;
    in
    ''
      run mkdir -p ${lib.escapeShellArg (builtins.dirOf target)}
      run touch ${lib.escapeShellArg target}
      run ${lib.getExe pkgs.crudini} --merge \
        ${lib.escapeShellArg target} \
        "" \
        < ${lib.escapeShellArg source}
    '';
}
