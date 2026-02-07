{
  description = "lang_chk";
  inputs = {
    # nixpkgs unstable for latest versions
    pkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # somehow Zig is still "unstable" and every update has breaking changes
    zig_overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, zig_overlay, ... } @ inputs: 
    let
      # system version (you may need to change this)
      system = "x86_64-linux";

      repo_root = builtins.toString ./.;

      # the server only compiles on one Zig version 
      zigVersion = "0.15.2";

      # selected Zig package
      zig = zig_overlay.packages.${system}.${zigVersion};

      # add the Zig overlay pkgs
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ zig_overlay.overlays.default ];
      };
    in {
      # Nix shell
      devShells.${system}.default = pkgs.mkShell {
        # install packages
        packages = (with pkgs; [
          github-linguist
        ]) ++ [ zig ];
      }
    }
}
