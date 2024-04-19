{ lib, stdenv, autoreconfHook
, fetchFromGitLab
, gnutls
}:

stdenv.mkDerivation rec {
  pname = "nbdkit";
  version = "1.36";
  src = fetchFromGitLab {
    owner = "nbdkit";
    repo = "nbdkit";
    rev = "stable-${version}";
    hash = lib.fakeHash;
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = [ gnutls ]

  outputs = [ "out" "dev" ];
}
