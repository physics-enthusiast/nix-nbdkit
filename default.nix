{ pkgs ? import <nixpkgs> {} }: rec {
  nbdkit = pkgs.callPackage ./nbdkit.nix {};
}
