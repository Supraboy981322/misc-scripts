{
  description = "random";

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
        repo_root = builtins.toString ./.;
        zigVersion = "0.16.0";
        zig = zig_overlay.packages.${system}.${zigVersion};
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ zig_overlay.overlays.default ];
        };
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "random";
          version = "0.1.0";
          src = ./.;
          nativeBuildInputs = [ zig.hook ];
          buildPhase = ''
            zig build-exe \
              "main.zig" \
              -femit-bin="random" \
              -O ReleaseSmall \
              --cache-dir "$TMPDIR/zig-cache" \
              --global-cache-dir "$TMPDIR/zig-global-cache"
          '';
          installPhase = ''
            mkdir -p "$out/bin"
            cp -r random "$out/bin/"
          '';
        };
        devShells.default = pkgs.mkShell {
          packages = [ zig ];
        };
      })
    );
}
