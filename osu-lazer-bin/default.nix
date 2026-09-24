{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  appimageTools,
  channel ? "lazer",
  nativeWayland ? false,
  extraShellArgs ? [ ],
}:
let
  pname = "osu-lazer-bin";

  releases = {
    lazer = {
      version = "2026.921.0";
      tag = "lazer";
      hash = "sha256-3O2UY7UBAJyV2+2JGr0vCswu+4TuQzb1scw7fASl/H0=";
    };

    tachyon = {
      version = "2026.918.0";
      tag = "tachyon";
      hash = "sha256-4wwtNWDqghwuJyvKz8pXuy0UfKAlwamV7UW82im6CFQ=";
    };
  };

  release =
    if channel == "lazer" then
      releases.lazer
    else if channel == "tachyon" then
      if lib.versionOlder releases.lazer.version releases.tachyon.version then
        releases.tachyon
      else
        releases.lazer
    else
      throw "osu-lazer-bin: channel must be \"lazer\" or \"tachyon\"";

  inherit (release) version tag hash;

  src =
    {
      x86_64-linux = fetchurl {
        url = "https://github.com/ppy/osu/releases/download/${version}-${tag}/osu.AppImage";
        inherit hash;
      };
    }
    .${stdenvNoCC.system} or (throw "osu-lazer-bin: ${stdenvNoCC.system} is unsupported.");

  meta = {
    description = "The future of osu! and the beginning of an open era! Commonly known by the codename osu!lazer. Pew pew.";
    homepage = "https://osu.ppy.sh";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = with lib.licenses; [
      mit
      cc-by-nc-40
      unfreeRedistributable
    ];
    mainProgram = "osu!";
    platforms = [
      "x86_64-linux"
    ];
  };

in
appimageTools.wrapType2 (finalAttrs: {
  inherit
    pname
    version
    src
    meta
    ;

  extraPkgs = pkgs: [ pkgs.icu ];

  extraBwrapArgs = [
    "--ro-bind-try /etc/egl/egl_external_platform.d /etc/egl/egl_external_platform.d"
  ];

  extraInstallCommands = ''
    . ${makeWrapper}/nix-support/setup-hook
    mv -v $out/bin/${pname} $out/bin/osu!

    wrapProgram $out/bin/osu! \
      ${lib.escapeShellArgs extraShellArgs} \
      ${lib.optionalString nativeWayland "--set SDL_VIDEODRIVER wayland"} \
      --set OSU_EXTERNAL_UPDATE_PROVIDER 1

    install -Dm444 ${finalAttrs.contents}/osu!.desktop $out/share/applications/osu!.desktop
    substituteInPlace $out/share/applications/osu!.desktop --replace-fail "Exec=osu! %u" "Exec=$out/bin/osu! %u"
    install -Dm444 ${finalAttrs.contents}/osu.png $out/share/icons/hicolor/256x256/apps/osu.png
  '';
})
