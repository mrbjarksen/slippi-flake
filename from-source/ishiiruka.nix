{
  lib,
  stdenv,
  fetchFromGitHub,
  makeDesktopItem,

  cmake,
  pkg-config,
  wrapGAppsHook3,
  rustc,
  cargo,
  rustPlatform,
  copyDesktopItems,

  alsa-lib,
  bluez,
  cubeb,
  curl,
  enet,
  ffmpeg,
  fmt_10,
  gdk-pixbuf,
  glib,
  glib-networking,
  gtk3,
  hidapi,
  jack2,
  libGLU,
  libXdmcp,
  libXext,
  libXrandr,
  libao,
  libevdev,
  libpulseaudio,
  libspng,
  libusb1,
  lz4,
  lzo,
  mbedtls_2,
  miniupnpc,
  minizip-ng,
  openal,
  pugixml,
  SDL2,
  sfml_2,
  udev,
  vulkan-loader,
  wxGTK32,
  xdg-utils,
  xxHash,
  xz,

  isPlayback ? false
}:

let
  type = if isPlayback then "playback" else "netplay";
in
  stdenv.mkDerivation rec {
    pname = "slippi-${type}";
    version = "3.5.1";

    src = fetchFromGitHub {
      owner = "project-slippi";
      repo = "Ishiiruka";
      rev = "v${version}";
      hash = "sha256-VW49r3cgMwfrukeAYglffMlkgwDAky5yumJLqnaoWAA=";
      fetchSubmodules = true;
    };

    desktopItems = [
      (makeDesktopItem {
        name = "${pname}";
        exec = "${meta.mainProgram}";
        comment = if isPlayback then "Play Melee online" else "Watch Melee replays";
        desktopName = if isPlayback then "Slippi (Playback)" else "Slippi (Netplay)";
        genericName = "Wii/GameCube Emulator";
        categories = [ "Game" "Emulator" ];
      })
    ];

    nativeBuildInputs = [
      cmake
      pkg-config
      wrapGAppsHook3
      rustc
      cargo
      rustPlatform.cargoSetupHook
      copyDesktopItems
    ];

    buildInputs = [
      alsa-lib
      bluez
      cubeb
      curl
      enet
      ffmpeg
      fmt_10
      gdk-pixbuf
      glib
      glib-networking
      gtk3
      hidapi
      jack2
      libGLU
      libXdmcp
      libXext
      libXrandr
      libao
      libevdev
      libpulseaudio
      libspng
      libusb1
      lz4
      lzo
      mbedtls_2
      miniupnpc
      minizip-ng
      openal
      pugixml
      SDL2
      sfml_2
      udev
      vulkan-loader
      wxGTK32
      xdg-utils
      xxHash
      xz
    ];

    cargoRoot = "Externals/SlippiRustExtensions";
    cargoDeps = rustPlatform.importCargoLock {
      lockFile = "${src}/${cargoRoot}/Cargo.lock";
    };

    cmakeFlags = [
      (lib.cmakeBool "LINUX_LOCAL_DEV" true)
      (lib.cmakeBool "ENABLE_LTO" true)
      (lib.cmakeBool "CMAKE_SKIP_BUILD_RPATH" true)
      (lib.cmakeFeature "GTK3_GLIBCONFIG_INCLUDE_DIR" "${glib.out}/lib/glib-2.0/include")
    ]
    ++ lib.optional isPlayback [
      (lib.cmakeBool "IS_PLAYBACK" true)
    ];

    doInstallCheck = true;

    postBuild = ''
      mkdir -p $out/bin $out/lib
      cp ./Binaries/dolphin-emu $out/bin/${meta.mainProgram}
      cp $build/build/source/build/Source/Core/DolphinWX/libslippi_rust_extensions.so $out/lib
      cp -r ../Data/Sys/ $out/
    ''
    + lib.optionalString isPlayback ''
      rm -rf $out/Sys/GameSettings
      cp -r ../Data/PlaybackGeckoCodes/ $out/Sys/GameSettings/
    '';

    installPhase = ''
      wrapProgram "$out/bin/${meta.mainProgram}" \
        --set "GDK_BACKEND" "x11" \
        --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules" \
        --prefix LD_LIBRARY_PATH : "${vulkan-loader}/lib" \
        --prefix PATH : "${xdg-utils}/bin"
    '';

    postInstall = ''
      install -D $src/Data/51-usb-device.rules $out/etc/udev/rules.d/51-usb-device.rules
    '';

    meta = {
      description = "The way to play Slippi Online and watch replays";
      homepage = https://slippi.gg;
      downloadPage = https://slippi.gg/downloads;
      license = lib.licenses.gpl2Only;
      maintainers = with lib.maintainers; [ mrbjarksen ];
      mainProgram = "slippi-${type}";
      platforms = lib.platforms.linux;
    };
  }
