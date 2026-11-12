{
   description = "compression defeater 2000";

   inputs = {
      pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
      flake-utils.url = "github:numtide/flake-utils";
   };

   outputs = { self, nixpkgs, flake-utils, ... } @ inputs:
      (flake-utils.lib.eachDefaultSystem (system: let
         pkgs = import nixpkgs { inherit system; };
      in {
         packages.default = pkgs.stdenv.mkDerivation {
            pname = "compression defeater 2000";
            version = "0.1.0";
            src = ./.;
            nativeBuildInputs = with pkgs; [ zig_0_16 ];
            buildPhase = "zig build";
            installPhase = ''
               mkdir -p "$out/bin"
               cp -r zig-out/bin/* "$out/bin"
            '';
         };
         devShells.default = pkgs.mkShell {
            packages = with pkgs; [ zig_0_16 ];
         };
      }));
}
