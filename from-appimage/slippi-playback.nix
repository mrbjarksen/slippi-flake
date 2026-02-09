{
  lib,
  appimageTools,
  fetchzip
}:

let
  pname = "slippi-playback";
  version = "3.5.2";

  archive = fetchzip {
    url = "https://github.com/project-slippi/Ishiiruka-Playback/releases/download/v${version}/playback-${version}-Linux.zip";
    hash = "sha256-LWo5gIXQck4dq9uKOYWElPsIUw2/GcMboteQsAx549k=";
    stripRoot = false;
  };

  src = "${archive}/Slippi_Playback-x86_64.AppImage";
in
appimageTools.wrapType2 rec {
  inherit pname version src;
  extraPkgs = pkgs: [ pkgs.curl ];

  meta = {
    description = "The way to watch replays from Slippi";
    homepage = https://slippi.gg;
    downloadPage = https://slippi.gg/downloads;
    license = lib.licenses.gpl2Only;
    maintainers = with lib.maintainers; [ mrbjarksen ];
    mainProgram = "slippi-playback";
    platforms = lib.platforms.linux;
  };
}
