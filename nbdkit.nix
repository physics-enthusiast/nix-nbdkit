{ lib, stdenv, autoreconfHook, pkg-config
, fetchFromGitLab
, runCommand
, selinuxSupport ? stdenv.isLinux, libselinux
, tlsSupport ? true, gnutls
, luaPluginSupport ? true, lua
, ocamlPluginSupport? true, ocaml
, perlPluginSupport ? true, perl, libxcrypt
, pythonPluginSupport ? true, python3
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
  srcGetSubdir = path: runCommand "" {} ''
    mkdir -p $out
    cp -r ${src}/${path}/. $out/
  '';
in
stdenv.mkDerivation {
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
    ++ lib.optionals tclPluginSupport [ tcl ];

  buildInputs = []
    ++ lib.optionals enableManpages [ (perl.withPackages (p: [ p.PodSimple ])) ]
    ++ lib.optionals selinuxSupport [ libselinux ]
    ++ lib.optionals tlsSupport [ gnutls ];

  postPatch = ''
    sed -i plugins/ocaml/Makefile.am -e 's|HAVE_OCAML$|FALSE|g'
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
}
// lib.optionalAttrs ocamlPluginSupport {
  ocamlPackage = stdenv.mkDerivation {
    pname = "nbdkit-ocaml";
    inherit version;
    src = srcGetSubdir "plugins/ocaml";
    postPatch = ''
      ls
    '';
  };
}
