{
  bash-strict-mode,
  checkedDrv,
  fetchFromSavannah,
  meta,
  stdenv,
  ...
}: let
  name = "STUMP";
  version = "3.0.0-alpha";
in
  checkedDrv (stdenv.mkDerivation {
    inherit name version;

    src = fetchFromSavannah {
      repo = "stump";
      rev = "master";
      hash = "sha256-tjlGPWwa4ZDM08qp+iwKBDyeyrZGp0uSBNmw73cTzDQ=";
    };

    buildInputs = [bash-strict-mode];

    postUnpack = ''
      echo $src
      echo $(realpath .)
      ls $(realpath .)

      dist_dirs=(etc bin tmp data)
      for dir in "''${dist_dirs[@]}"; do
        mv "source/$dir.dist" "source/$dir"
      done
    '';

    installPhase = ''
      mkdir -p "$out"
      cp -r etc bin tmp data "$out/"
    '';

    meta =
      meta // {description = "Secure Team-based Usenet Moderation Program";};
  })
