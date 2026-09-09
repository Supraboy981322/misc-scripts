# TODO: a name (for some dumb historical reason 'view' is taken by Vim)

{
  description = "view (just a crappy clone of cat and ls in one program)";

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
          pname = "view";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ zig.hook ];
          buildPhase = ''
            zig build-exe \
              -O ReleaseSafe \
              main.zig \
              --cache-dir $TMPDIR/zig-cache \
              --global-cache-dir $TMPDIR/zig-global-cache \
              -femit-bin=view
          '';
          installPhase = ''
            mkdir -p "$out/bin"
            cp -r view "$out/bin/"
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = [ zig ];
        };
      })
    );
}
