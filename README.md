# osu!lazer for Nix

> [!IMPORTANT]
> This is an unofficial, community Nix flake. 

<a href="https://github.com/ppy/osu/releases/tag/2026.921.0-lazer">
  <img src="https://img.shields.io/badge/lazer-2026.921.0-ff66aa" alt="lazer version" />
</a>
<a href="https://github.com/ppy/osu/releases/tag/2026.918.0-tachyon">
  <img src="https://img.shields.io/badge/tachyon-2026.918.0-8866ee" alt="Tachyon version" />
</a>

## What is this?

The `osu-lazer-bin` package in nixpkgs may not have the latest version and does not support the Tachyon release stream.

This flake packages the official AppImage and provides configuration for Home Manager and plain NixOS setups.

> [!NOTE]
> The official AppImages include osu!'s proprietary anti-cheat required for
> score submission and multiplayer, making them `unfreeRedistributable`.

Only `x86_64-linux` is supported.

## Installation

### Run temporarily

```bash
nix run github:repinek/osu-lazer-flake#osu-lazer-bin
```

### Without Home Manager

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

Then add the package to your system:

```nix
# configuration.nix
{ inputs, pkgs, ... }:
{
  # Or home.packages
  environment.systemPackages = [
    inputs.osu-lazer.packages.${pkgs.stdenv.hostPlatform.system}.osu-lazer-bin

    # You also can override arguments
    (inputs.osu-lazer.packages.${pkgs.stdenv.hostPlatform.system}.osu-lazer-bin.override {
      nativeWayland = true;
      channel = "tachyon";
      extraShellArgs = [ ];
    })
  ];
}
```

### Home Manager

Import the module:

```nix
# configuration.nix
{ inputs, ... }:
{
  home-manager.users.your-user.imports = [
    inputs.osu-lazer.homeManagerModules.osu-lazer
  ];
}
```

Configure osu!:

```nix
# home.nix
programs.osu-lazer = {
  enable = true;
  nativeWayland = true;
  channel = "tachyon"; # Or lazer
  extraShellArgs = [
    "--set" "SDL_VIDEO_DOUBLE_BUFFER" "1"
    "--set" "PIPEWIRE_LATENCY" "256/48000"
  ];

  # Available keys: https://github.com/ppy/osu/blob/master/osu.Game/Configuration/OsuConfigManager.cs
  gameSettings = {
    DimLevel = 1.0;
    KeyOverlay = true;
    IntroSequence = "Random";
    ReleaseStream = "Tachyon"; # Select Tachyon as release stream, effects only notification in game
  };

  # Available keys: https://github.com/ppy/osu-framework/blob/master/osu.Framework/Configuration/FrameworkConfigManager.cs
  frameworkSettings = {
    Locale = "en";
    VolumeMusic = 0.42;
  };

  # Or if you want to specify location
  storagePath = "/home/alice/Games/osu";

  files."/home/alice/Games/osu" = {
    # gameSettings...
    # frameworkSettings...
  };
};
```

## License

This project is licensed under the **MIT License**.  
See the [LICENSE](LICENSE) file for details.

## Disclaimer
This project is **NOT** affiliated with or endorsed by ppy or osu!.

**osu!** is a trademark of **ppy**.

## Acknowledgements

Based on the [`osu-lazer-bin` package from nixpkgs](https://github.com/NixOS/nixpkgs/blob/69749a48216c60ec366616baa7c78d75b1b88038/pkgs/by-name/os/osu-lazer-bin/package.nix).
