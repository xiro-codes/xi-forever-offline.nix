{
  description = "XI: Forever Offline installable package, overlay, and modules for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    xi-forever-offline = {
      url = "github:Hurami89/xi-forever-offline";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      xi-forever-offline,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      mkPackage =
        pkgs:
        pkgs.callPackage ./package.nix {
          kitSrc = xi-forever-offline;
        };
      defaultPkg = mkPackage pkgs;

      overlay = final: prev: {
        xi-forever-offline = final.callPackage ./package.nix {
          kitSrc = xi-forever-offline;
        };
      };

      mkModule =
        { isHomeManager }:
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.xi-forever-offline;
          pkg = pkgs.callPackage ./package.nix {
            kitSrc = xi-forever-offline;
            kitDir = cfg.dataDir;
          };
        in
        {
          options.programs.xi-forever-offline = {
            enable = lib.mkEnableOption "XI: Forever Offline launcher and FHS runtime";
            package = lib.mkOption {
              type = lib.types.package;
              default = pkg;
              description = "The xi-forever-offline package to install.";
            };
            dataDir = lib.mkOption {
              type = lib.types.str;
              default = "$HOME/.xi/";
              description = "Writable directory where XI: Forever Offline stores its kit, server, database, and Proton prefix.";
            };
          };

          config = lib.mkIf cfg.enable (
            if isHomeManager then
              {
                home.packages = [ cfg.package ];
              }
            else
              {
                environment.systemPackages = [ cfg.package ];
              }
          );
        };
    in
    {
      packages.${system} = {
        default = defaultPkg;
        xi-forever-offline = defaultPkg;
      };

      apps.${system} = {
        default = {
          type = "app";
          program = "${defaultPkg}/bin/xi-forever-offline";
        };
        xi-forever-offline = {
          type = "app";
          program = "${defaultPkg}/bin/xi-forever-offline";
        };
      };

      devShells.${system}.default = defaultPkg.env;

      overlays = {
        default = overlay;
        xi-forever-offline = overlay;
      };

      nixosModules = {
        default = mkModule { isHomeManager = false; };
        xi-forever-offline = mkModule { isHomeManager = false; };
      };

      homeModules = {
        default = mkModule { isHomeManager = true; };
        xi-forever-offline = mkModule { isHomeManager = true; };
      };
    };
}
