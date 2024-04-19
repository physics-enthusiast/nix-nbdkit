{ lib, stdenv, autoreconfHook, pkg-config
, fetchFromGitLab
, gnutls
, perlPluginSupport ? false
, enableDocs ? true, perl
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

  nativeBuildInputs = [ 
    autoreconfHook pkg-config 
  ]
    ++ lib.optional enableDocs [ (perl.withPackages (p: [ p.PodSimple ])) ];
  buildInputs = [ gnutls ];

  # Shell scripts with shebangs are ran during build
  # so we patchShebang everything. Anything that ends 
  # up in the outputs will be patched again anyway. 
  # For some reason patching the sources themselves
  # seems to miss a few.
  postConfigure = ''
    patchShebangs --build /build
  '';

  # Most language plugins are automatically turned on or off based on the
  # presence of relevant dependencies and headers. However, to build the
  # docs perl has to be a nativeBuildInput. Hence, explicitly disable
  # perl plugins if perlPluginSupport is false but enableDocs is true
  configureFlags = [
    # Diagnostic info requested by upstream
    "--with-extra='Nixpkgs'"
  ] ++ lib.optional (!perlPluginSupport && enableDocs) "-disable-perl";

  doCheck = true;

  outputs = [ "out" "dev" "man" ];
}
