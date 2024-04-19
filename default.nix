{ pkgs ? import <nixpkgs> {} }: {
  nbdkit = pkgs.callPackage ./nbdkit.nix {};
}
