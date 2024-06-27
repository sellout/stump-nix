{
  description = "Nix packaging for the STUMP USENET robomoderator";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    ## Isolate the build.
    registries = false;
    sandbox = "relaxed";
  };

  outputs = {
    bash-strict-mode,
    flake-utils,
    flaky,
    nixpkgs,
    self,
  }: let
    pname = "stump";

    supportedSystems = flaky.lib.defaultSystems;

    localPackages = pkgs: let
      stump = let
        name = "STUMP";
        version = "2.5";
      in
        bash-strict-mode.lib.checkedDrv pkgs (pkgs.stdenv.mkDerivation {
          inherit name version;
          src = pkgs.fetchzip {
            url = "https://www.algebra.com/~ichudov/stump/download/${name}_${builtins.replaceStrings ["."] ["_"] version}.tar.gz";
            hash = "sha256-+mZpvzHx8FSJfSP3IP/le/MGiipS92EwHtZgMuHB8BA=";
          };

          buildInputs = [pkgs.bash-strict-mode];

          postUnpack = ''
            echo $src
            echo $(realpath .)
            ls $(realpath .)

            dist_dirs=(etc bin tmp data)
            for dir in "''${dist_dirs[@]}"; do
              mv "source/$dir.dist" "source/$dir"
            done
          '';

          postPatch = ''
            ## The compile script doesn’t error on failure.
            substituteInPlace c/compile \
              --replace "CC=cc" "CC=\"cc $CFLAGS\"" \
              --replace "echo \"\"" "exit 1"
          '';

          CFLAGS = [
            "-Wno-aggressive-loop-optimizations"
            "-Wno-builtin-declaration-mismatch"
            "-Wno-implicit-function-declaration"
            "-Wno-implicit-int"
            "-Wno-stringop-overflow"
          ];

          buildPhase = ''
            ( cd c
              ./compile
            )
          '';

          installPhase = ''
            mkdir -p "$out"
            cp -r etc bin tmp data "$out/"
          '';

          meta = {
            description = "Secure Team-based Usenet Moderation Program";
            homepage = "https://www.algebra.com/~ichudov/stump/";
            license = pkgs.lib.licenses.gpl2;
            maintainers = with pkgs.lib.maintainers; [sellout];
            platforms = pkgs.lib.platforms.unix;
          };
        });
    in {
      inherit stump;

      webstump = let
        name = "webstump";
      in
        bash-strict-mode.lib.checkedDrv pkgs (pkgs.stdenv.mkDerivation {
          inherit name;
          version = "2016-04-21";
          src = pkgs.fetchzip {
            url = "https://www.algebra.com/~ichudov/stump/download/${name}.tar.gz";
            ## NB: If this hash breaks, make sure to update the `version` with
            ##     the new publication date.
            hash = "sha256-NmMQAFij5Le4nj5vvjPRCk+GcDyITTzK1lkSW449nqA=";
          };

          nativeBuildInputs = [stump];

          CFLAGS = ["-Wno-implicit-function-declaration"];

          preBuild = ''
            substituteInPlace ./Makefile \
              --replace "/home/ichudov/public_html/stump/webstump" "$(realpath .)"

            substituteInPlace ./src/Makefile \
              --replace '$(CC) -o' '$(CC) $(CFLAGS) -o' \
              --replace '	chmod 755 $@' "" \
              --replace '	chmod u+s $@' ""
          '';

          installPhase = ''
            mkdir -p "$out"
            ## TODO: Figure out exactly what needs to be copied over (maybe add
            ##       an `install` target upstream).
            cp -r bin config images index.html scripts "$out/"
          '';

          meta = {
            description = "Web interface for STUMP";
            homepage = "https://www.algebra.com/~ichudov/stump/";
            license = pkgs.lib.licenses.gpl2;
            maintainers = with pkgs.lib.maintainers; [sellout];
            platforms = pkgs.lib.platforms.unix;
          };
        });
    };
  in
    {
      schemas = {
        inherit
          (flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      overlays = {
        default =
          nixpkgs.lib.composeExtensions
          bash-strict-mode.overlays.default
          self.overlays.local;
        local = final: prev: localPackages final;
      };

      lib = {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example pname self [
            ({pkgs, ...}: {
              home.packages = [
                pkgs.${pname}
                pkgs."web${pname}"
              ];
            })
          ])
          supportedSystems);
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [bash-strict-mode.overlays.default];
      };

      src = pkgs.lib.cleanSource ./.;
    in {
      packages =
        {
          default = self.packages.${system}.${pname};
        }
        // localPackages pkgs;

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";};

      checks = self.projectConfigurations.${system}.checks;
      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    bash-strict-mode = {
      inputs = {
        flake-utils.follows = "flake-utils";
        flaky.follows = "flaky";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    flaky = {
      inputs = {
        bash-strict-mode.follows = "bash-strict-mode";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
      url = "github:sellout/flaky";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-24.05";
  };
}
