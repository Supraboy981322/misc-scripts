{
  description = "battery_prog";

  inputs = {
    pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    zig_overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zig_overlay, flake-utils, ... } @ inputs:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        zig_version = "0.16.0";
        zig = zig_overlay.packages.${system}.${zig_version};
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig_overlay.overlays.default ];
        };
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "battery_prog";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ zig.hook ];
          buildPhase = ''
            zig build-exe \
              main.zig \
              -Doptimize="ReleaseSmall" \
              --cache-dir "$TMPDIR/zig-cache" \
              --global-cache-dir "$TMPDIR/zig-global-cache" \
              -femit-bin="battery_prog"
          '';
          installPhase = ''
            mkdir -p "$out/bin"
            cp -r "battery_prog" "$out/bin/"
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = [ zig ];
        };
      })
    );
}
