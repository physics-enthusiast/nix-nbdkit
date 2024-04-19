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
    hash = "sha256-7NTxC3HmN+3tzBDtxIOuHpfF184S8RjYbbKouW5Z//k=";
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = [ gnutls ];

  autoreconfPhase = ''
    autoreconf -i
  '';
  outputs = [ "out" "dev" ];
}
