{
  description = "osu!lazer client on Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [ "x86_64-linux" ];

      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfreePredicate =
                pkg:
                builtins.elem (nixpkgs.lib.getName pkg) [
                  "osu-lazer-bin"
                  "osu-lazer-tachyon-bin"
                ];
            };
          }
        );
    in
    {
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-tree);

      packages = forEachSupportedSystem (
        { pkgs }: {
          osu-lazer-bin = pkgs.callPackage ./osu-lazer-bin { };
          osu-lazer-tachyon-bin = pkgs.callPackage ./osu-lazer-tachyon-bin { };
        }
      );
    };
}
