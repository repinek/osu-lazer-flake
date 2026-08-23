{
  lib,
  stdenvNoCC,
  fetchurl,
  makeWrapper,
  appimageTools,
  nativeWayland ? true,
}:
let
  pname = "osu-lazer-tachyon-bin";
  version = "2026.821.0";

  src =
    {
      x86_64-linux = fetchurl {
        url = "https://github.com/ppy/osu/releases/download/${version}-tachyon/osu.AppImage";
        hash = "sha256-JOcYz0gARrJziJDkNMweWC1AloToDGC+84Suwe311/U=";
      };
    }
    .${stdenvNoCC.system} or (throw "osu-lazer-tachyon-bin: ${stdenvNoCC.system} is unsupported.");

  meta = {
    description = "Tachyon pre-release channel of the future of osu! and the beginning of an open era! Commonly known by the codename osu!lazer. Pew pew.";
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
      ${lib.optionalString nativeWayland "--set SDL_VIDEODRIVER wayland"} \
      --set OSU_EXTERNAL_UPDATE_PROVIDER 1

    install -Dm444 ${finalAttrs.contents}/osu!.desktop $out/share/applications/osu!.desktop
    substituteInPlace $out/share/applications/osu!.desktop --replace-fail "Exec=osu! %u" "Exec=$out/bin/osu! %u"
    install -Dm444 ${finalAttrs.contents}/osu.png $out/share/icons/hicolor/256x256/apps/osu.png
  '';
})
