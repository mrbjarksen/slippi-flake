{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  nodejs,
  electron,
  makeDesktopItem,
  copyDesktopItems
}:

stdenvNoCC.mkDerivation rec {
  pname = "slippi-launcher";
  version = "2.11.10";
  
  src = fetchFromGitHub {
    owner = "project-slippi";
    repo = "slippi-launcher";
    tag = "v${version}";
    hash = "sha256-JrM2nm5iEAoyrGeqF1iP+kKjdiC/3mfCihzawg3Xv9s=";
  };

  patches = [ ./add-electron-builder.patch ];

  postPatch = ''
    rm package.json yarn.lock
    cp release/app/package.json release/app/yarn.lock .
  '';

  offlineCache = (fetchYarnDeps {
    yarnLock = ./yarn.lock;
    hash = "sha256-CxBPeKXuLVTwJvaK9q2TVIfsNw9I8MN0xS1+AKovyWQ=";
  }).overrideAttrs (prev: {
    preFixup = ''
      echo "Fixing paths of dependencies"
      for dep in $out/*; do
        base=$(echo $dep | awk -F "/" '{print $NF}')
        newdep=$(echo $base | awk -F "___" '{
          if ($1 ~ /^_/) {
            sub(/^_/, "@", $1); sub(/_.*/, "", $1); gsub("_", "-", $2); print $1 "-" $2
          } else {
            gsub("_", "-", $2); print $2
          }
        }')
        if [ -n "$newdep" ]; then
          cp $dep $out/$newdep
        fi
      done
      mv $out/string-decoder-1.3.0.tgz $out/string_decoder-1.3.0.tgz
      cp $out/node-abi-4.12.0.tgz $out/node-abi-3.3.0.tgz
    '';
  });

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    nodejs
    copyDesktopItems
  ];

  yarnBuildScript = "electron-builder";
  yarnBuildFlags = [
    "--dir"
    "-c.electronDist=${electron.dist}"
    "-c.electronVersion=${electron.version}"
  ];

  installPhase = ''
    runHook preInstall

    for size in 16x16 24x24 32x32 48x48 64x64 96x96 128x128 256x256 512x512; do
      install -Dm444 assets/icons/$size.png $out/share/icons/hicolor/$size/apps/slippi-launcher.png
    done

    makeWrapper '${electron}/bin/electron' "$out/bin/slippi-launcher" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}" \
      --inherit-argv0

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "slippi-launcher";
      exec = "slippi-launcher";
      icon = "slippi-launcher";
      desktopName = "Slippi Launcher";
      comment = meta.description;
      type = "Application";
      categories = [ "Game" ];
      keywords = [ "slippi" "melee" "smash" "online" ];
    })
  ];

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
