{
  lib,
  appimageTools,
  fetchurl
}:

let
  pname = "slippi-netplay";
  version = "3.5.2";

  src = fetchurl {
    url = "https://github.com/project-slippi/Ishiiruka/releases/download/v${version}/Slippi_Online-x86_64.AppImage";
    hash = "sha256-wIW1mpG900P3KJn18mMY8IkU/4VlCoSONAbAFhF2YGQ=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
  };
in
appimageTools.wrapType2 rec {
  inherit pname version src;
  extraPkgs = pkgs: [ pkgs.curl ];

  meta = {
    description = "The way to play Slippi Online";
    homepage = https://slippi.gg;
    downloadPage = https://slippi.gg/downloads;
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ mrbjarksen ];
    mainProgram = "slippi-netplay";
    platforms = lib.platforms.linux;
  };
}
