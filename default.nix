{ pkgs ? import <nixpkgs> {} }: rec {
  nbdkit = pkgs.callPackage ./nbdkit.nix {};
  nbdkit_dev = pkgs.runCommand "dev" ''
    ls ${nbdkit.dev}
  '';
}
