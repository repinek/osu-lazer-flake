# osu!lazer for Nix

> [!IMPORTANT]
> This is an unofficial, community Nix flake. 

<a href="https://github.com/ppy/osu/releases/tag/2026.921.0-lazer">
  <img src="https://img.shields.io/badge/lazer-2026.921.0-ff66aa" alt="lazer version" />
</a>
<a href="https://github.com/ppy/osu/releases/tag/2026.921.0-lazer">
  <img src="https://img.shields.io/badge/tachyon-2026.921.0-8866ee" alt="Tachyon version" />
</a>

## What is this?

The `osu-lazer-bin` package in nixpkgs may not have the latest version and there is no package for the Tachyon branch.

This flake packages the official AppImages for both:

- `osu-lazer-bin` - the regular lazer release
- `osu-lazer-tachyon-bin` - the Tachyon pre-release

> [!NOTE]
> The official AppImages include osu!'s proprietary anti-cheat required for
> score submission and multiplayer, making them `unfreeRedistributable`.

Only `x86_64-linux` is supported. Both packages install the same `osu!` executable, so pick one.

## Installation

### Run temporarily 

```bash
# For lazer
nix run github:repinek/osu-lazer-flake#osu-lazer-bin

# For tachyon
nix run github:repinek/osu-lazer-flake#osu-lazer-tachyon-bin
```

### System package

Add the flake to your inputs:

```nix
# flake.nix
{
  inputs.osu-lazer = {
    url = "github:repinek/osu-lazer-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Pass `inputs` to your NixOS modules:

```nix
# flake.nix
nixosConfigurations.your-host = nixpkgs.lib.nixosSystem {
  specialArgs = { inherit inputs; };
  modules = [ ./configuration.nix ];
};
```

Then add one of the packages to your system:

```nix
# configuration.nix
{ inputs, pkgs, ... }:
{
  # or home.packages
  environment.systemPackages = [
    inputs.osu-lazer.packages.${pkgs.stdenv.hostPlatform.system}.osu-lazer-bin
  ];
}
```

### Native Wayland

The package can be forced to use Wayland instead of XWayland:

```nix
environment.systemPackages = [
  (inputs.osu-lazer.packages.${pkgs.stdenv.hostPlatform.system}.osu-lazer-bin.override {
    nativeWayland = true;
  })
];
```

## TODO

- [ ] Automatic update workflow
- [ ] Source-built packages

## License

This project is licensed under the **MIT License**.  
See the [LICENSE](LICENSE) file for details.

## Disclaimer
This project is **NOT** affiliated with or endorsed by ppy or osu!.

**osu!** is a trademark of **ppy**.

## Acknowledgements

Based on the [`osu-lazer-bin` package from nixpkgs](https://github.com/NixOS/nixpkgs/blob/69749a48216c60ec366616baa7c78d75b1b88038/pkgs/by-name/os/osu-lazer-bin/package.nix).
