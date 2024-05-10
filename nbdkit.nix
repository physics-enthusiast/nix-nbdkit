{ lib, stdenv, autoreconfHook, pkg-config
, fetchFromGitLab
, runCommand
, selinuxSupport ? stdenv.isLinux, libselinux
, tlsSupport ? true, gnutls
, luaPluginSupport ? true, lua
, ocamlPluginSupport ? true, ocaml
, perlPluginSupport ? true, perl, libxcrypt
, pythonPluginSupport ? true, python3
, rustPluginSupport ? true, rustPlatform
, tclPluginSupport ? true, tcl
, enableManpages ? true
}: 
let
  version = "1.39.4";
  src = fetchFromGitLab {
    owner = "nbdkit";
    repo = "nbdkit";
    rev = "v${version}";
    hash = "sha256-jJWknok8Mnd0+MDXzEoN/hNpgxDKeXMaGzZclQdDpuQ=";
  };
  cargoDeps = rustPlatform.fetchCargoTarball { 
    src = runCommand "" {} ''
      mkdir -p $out
      cp -r ${src}/plugins/rust/. $out/
      mv $out/Cargo.lock.msrv $out/Cargo.lock
    '';
    hash = "sha256-3hnA0Ot6Q9lTnH+O5fmh2v2q7YMhmU5u75BlLwmF2Kk="; 
  };
in
stdenv.mkDerivation ({
  pname = "nbdkit";
  inherit version src;

  enableParallelBuilding = true;

  nativeBuildInputs = [ 
    autoreconfHook pkg-config 
  ]
    ++ lib.optionals ocamlPluginSupport [ ocaml ]
    ++ lib.optionals luaPluginSupport [ lua ]
    ++ lib.optionals perlPluginSupport [ libxcrypt perl ]
    ++ lib.optionals pythonPluginSupport [ (python3.withPackages (p: [ p.boto3 p.google-cloud-storage ])) ]
    ++ lib.optionals rustPluginSupport [ rustPlatform.cargoSetupHook ]
    ++ lib.optionals tclPluginSupport [ tcl ];

  buildInputs = []
    ++ lib.optionals enableManpages [ (perl.withPackages (p: [ p.PodSimple ])) ]
    ++ lib.optionals selinuxSupport [ libselinux ]
    ++ lib.optionals tlsSupport [ gnutls ];

  postPatch = lib.optionals ocamlPluginSupport ''
    sed -i plugins/ocaml/Makefile.am -e "s|\$(OCAMLLIB)|\"$out/lib/ocaml/${ocaml.version}/site-lib/\"|g"
  '';

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
  # docs, perl has to be a nativeBuildInput. Hence, explicitly disable
  # perl plugins if perlPluginSupport is false but enableManpages is true
  configureFlags = [
    # Diagnostic info requested by upstream
    "--with-extra='Nixpkgs'"
  ] ++ lib.optional (!perlPluginSupport && enableManpages) "-disable-perl";

  doCheck = true;

  outputs = [
    "out" "dev"
  ] ++ lib.optionals enableManpages [
    "man"
  ];
} // lib.optionalAttrs rustPluginSupport {
  inherit cargoDeps;
  cargoSetupPostPatchHook = "";
})
