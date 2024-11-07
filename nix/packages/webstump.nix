{
  checkedDrv,
  fetchFromSavannah,
  lib,
  meta,
  msmtp,
  perl,
  perlPackages,
  procmail,
  stdenv,
  stump,
  ## Whether to allow images & other binaries to be treated as such.
  enableMIME ? true,
  ...
}:
checkedDrv (stdenv.mkDerivation {
  name = "webstump";
  version = "3.0.0-alpha";

  src = fetchFromSavannah {
    repo = "webstump";
    rev = "master";
    hash = "sha256-J9n1ROJmUq9AfVMPN5uTVo2x+gRm5gMztw75oxiZ4cM=";
  };

  nativeBuildInputs =
    [
      perl
      procmail
      stump
    ]
    ++ lib.optionals enableMIME [
      perlPackages.ConvertUU
      perlPackages.MIMEtools
    ];

  nativeCheckInputs = with perlPackages; [
    HTMLEscape
    TestMockModule
    TestTrap
  ];

  preBuild =
    ''
      ## FIXME: Nix is not allowed to enable the setuid bit.
      substituteInPlace ./src/Makefile \
        --replace-fail '	chmod u+s $@' ""

      substituteInPlace ./config/webstump.cfg \
        --replace-fail \
          '@sendmail = ("/usr/lib/sendmail", "/usr/bin/sendmail", "/usr/sbin/sendmail" );' \
          '@sendmail = ("${lib.getExe msmtp}");'
    ''
    + (
      if enableMIME
      then ""
      else ''
        substituteInPlace ./config/webstump.cfg \
          --replace-fail '$use_mime = "yes";' '$use_mime = "no";'
      ''
    );

  ## `perlPackages.HTMLEscape` is currently marked `broken` on darwin.
  doCheck = !stdenv.hostPlatform.isDarwin;

  installPhase = ''
    mkdir -p "$out"
    ## TODO: Figure out exactly what needs to be copied over (maybe add
    ##       an `install` target upstream).
    cp -r bin config demo images index.html scripts "$out/"
    (
      set +o nounset
      patchShebangs "$out/scripts"
    )
  '';

  meta = meta // {description = "Web interface for STUMP";};
})
