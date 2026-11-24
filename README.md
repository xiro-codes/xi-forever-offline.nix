# XI: Forever Offline (Nix Flake)

Nix flake providing a self-contained package, desktop entry, FHS runtime (32/64-bit OpenGL/Vulkan, Proton/UMU, MariaDB, and server dependencies), overlay, and NixOS / Home Manager modules for [XI: Forever Offline](https://github.com/Hurami89/xi-forever-offline).

On first launch, kit files from the locked `xi-forever-offline` flake input are seeded into your writable data directory (`~/.xicore/XI Forever Offline` by default, or `$XIFO_HOME`).

---

## Quick Run

Run directly without installing:

```bash
nix run /path/to/xi-forever-offline
```

Pass launcher arguments (e.g. headless world commands or scripts):

```bash
nix run /path/to/xi-forever-offline -- --run launcher_world.py status
```

---

## Setup Guide

### 1. Add the Flake Input

In your system or Home Manager `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    xi-forever-offline = {
      url = "git+file:///home/tod/Desktop/xi-forever-offline"; # or github:<you>/xi-forever-offline-nix
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### 2A. NixOS Configuration

Import `xi-forever-offline.nixosModules.default` in your NixOS configuration:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.xi-forever-offline.nixosModules.default
  ];

  programs.xi-forever-offline = {
    enable = true;
    # Optional: override where the game kit, MariaDB, server, and Proton prefix live
    # dataDir = "$HOME/.xicore/XI Forever Offline";
  };
}
```

### 2B. Home Manager Configuration

Import `xi-forever-offline.homeModules.default` in your Home Manager configuration:

```nix
{ inputs, ... }:
{
  imports = [
    inputs.xi-forever-offline.homeModules.default
  ];

  programs.xi-forever-offline = {
    enable = true;
    # dataDir = "$HOME/.xicore/XI Forever Offline";
  };
}
```

### 2C. Overlay / Direct Package

If you prefer adding the package directly to `environment.systemPackages` or `home.packages`:

```nix
# Via flake packages:
environment.systemPackages = [
  inputs.xi-forever-offline.packages.${pkgs.system}.default
];

# Or via overlay:
nixpkgs.overlays = [ inputs.xi-forever-offline.overlays.default ];
environment.systemPackages = [ pkgs.xi-forever-offline ];
```

---

## First-Time Game Setup

1. Launch **XI: Forever Offline** from your application launcher or run `xi-forever-offline` in a terminal.
2. Complete the first-run setup wizard inside the launcher (downloads/configures portable MariaDB, server binaries, Proton/UMU, and patches client DATs).
3. Click **PLAY** to start MariaDB, the 5 world server processes, sidecars, and Ashita.

---

## Updating Upstream Kit Source

To pull the latest commit from `github:Hurami89/xi-forever-offline`:

```bash
nix flake update xi-forever-offline
```
