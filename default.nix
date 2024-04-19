{ pkgs ? import <nixpkgs> { system = builtins.currentSystem } }: {
  nbdkit = pkgs.callPackage ./nbdkit.nix {};
}
