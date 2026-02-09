{
  lib,
  appimageTools,
  fetchurl
}:

let
  pname = "slippi-launcher";
  version = "2.13.3";

  src = fetchurl {
    url = "https://github.com/project-slippi/slippi-launcher/releases/download/v${version}/Slippi-Launcher-${version}-x86_64.AppImage";
    hash = "sha256-5tFl0ezk/yMkfd59kUKxGZBvt5MqnoCvxRSepy7O8BQ=";
  };

  appimageContents = appimageTools.extract {
    inherit pname version src;
    postExtract = ''
      substituteInPlace $out/slippi-launcher.desktop --replace-fail 'Exec=AppRun' 'Exec=${pname}'
    '';
  };
in
appimageTools.wrapType2 rec {
  inherit pname version src;

  extraInstallCommands = ''
    cp -r ${appimageContents}/usr/lib $out/lib
    install -m 444 -D ${appimageContents}/slippi-launcher.desktop $out/share/applications/slippi-launcher.desktop
    for size in 16x16 24x24 32x32 48x48 64x64 96x96 128x128 256x256 512x512; do
      install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/$size/apps/slippi-launcher.png \
        $out/share/icons/hicolor/$size/apps/slippi-launcher.png
    done
  '';

  meta = {
    description = "The way to play Slippi Online and watch replays";
    homepage = https://slippi.gg;
    downloadPage = https://slippi.gg/downloads;
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ mrbjarksen ];
    mainProgram = "slippi-launcher";
    platforms = lib.platforms.linux;
  };
}
