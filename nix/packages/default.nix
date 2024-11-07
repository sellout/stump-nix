{
  bash-strict-mode,
  pkgs,
}: let
  checkedDrv = bash-strict-mode.lib.checkedDrv pkgs;

  meta = {
    homepage = "https://www.algebra.com/~ichudov/stump/";
    license = pkgs.lib.licenses.gpl3;
    maintainers = with pkgs.lib.maintainers; [sellout];
    platforms = pkgs.lib.platforms.unix;
  };

  stump = pkgs.callPackage ./stump.nix {inherit checkedDrv meta;};
in {
  inherit stump;

  webstump = pkgs.callPackage ./webstump.nix {inherit checkedDrv meta stump;};
}
