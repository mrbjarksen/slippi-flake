{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      mkPkgs = pkgs: rec {
        slippi-launcher = pkgs.callPackage ./slippi-launcher.nix { };
        slippi-netplay = pkgs.callPackage ./ishiiruka.nix { isPlayback = false; };
        slippi-playback = pkgs.callPackage ./ishiiruka.nix { isPlayback = true; };
      };
    in
    {
      overlays.slippi-flake = final: prev: mkPkgs final;

      packages = forAllSystems (system: mkPkgs nixpkgs.legacyPackages.${system});

      apps = forAllSystems (system:
        (builtins.mapAttrs
          (name: package: {
            type = "app";
            program = nixpkgs.lib.getExe package;
          })
          (mkPkgs nixpkgs.legacyPackages.${system}))
        // {
          default = self.apps.${system}.slippi-launcher;
        }
      );

      homeModules.slippi = { pkgs, config, lib, ... }:
        let
          cfg = config.slippi;
        in
        with lib; {
          options.slippi = {
            launcher = {
              enable = mkEnableOption "Install Slippi Launcher";
              package = mkOption {
                default = pkgs.slippi-launcher;
                type = types.package;
                description = "The package to use for Slippi Launcher";
              };
              # Game settings
              isoPath = mkOption {
                default = "";
                type = types.str;
                description = "The path to an NTSC Melee ISO.";
              };
              launchMeleeOnPlay = mkEnableOption "Launch Melee in Dolphin when the Play button is pressed." // { default = true; };
              enableJukebox = mkEnableOption "Enable in-game music via Slippi Jukebox. Incompatible with WASAPI." // { default = true; };
              # Replay settings
              rootSlpPath = mkOption {
                default = "${config.home.homeDirectory}/Slippi";
                type = types.str;
                description = "The folder where your SLP replays should be saved.";
              };
              useMonthlySubfolders = mkEnableOption "Save replays to monthly subfolders";
              spectateSlpPath = mkOption {
                default = "${cfg.slippi.launcher.rootSlpPath}/Spectate";
                type = types.nullOr types.str;
                description = "The folder where spectated games should be saved.";
              };
              extraSlpPaths = mkOption {
                default = [ ];
                type = types.listOf types.str;
                description = "Choose any additional SLP directories that should show up in the replay browser.";
              };
            };
            netplay = {
              enable = mkEnableOption "Install Slippi Netplay";
              package = mkOption {
                default = pkgs.slippi-netplay;
                type = types.package;
                description = "The package to use for Slippi Netplay";
              };
            };
            # Playback
            playback = {
              enable = mkEnableOption "Install Slippi Playback";
              package = mkOption {
                default = pkgs.slippi-playback;
                type = types.package;
                description = "The package to use for Slippi Playback";
              };
            };
          };
          config = {
            home.packages = [
              (mkIf cfg.launcher.enable cfg.launcher.package)
              (mkIf cfg.netplay.enable cfg.netplay.package)
              (mkIf cfg.playback.enable cfg.playback.package)
            ];
            xdg.configFile."Slippi Launcher/netplay/dolphin-emu".source = "${lib.getExe cfg.netplay.package}";
            xdg.configFile."Slippi Launcher/playback/dolphin-emu".source = "${lib.getExe cfg.playback.package}";
            xdg.configFile."Slippi Launcher/Settings".source =
              let
                jsonFormat = pkgs.formats.json { };
              in
              jsonFormat.generate "slippi-config" {
                settings = {
                  isoPath = cfg.launcher.isoPath;
                  launchMeleeOnPlay = cfg.launcher.launchMeleeOnPlay;
                  enableJukebox = cfg.launcher.enableJukebox;
                  # Replay settings
                  rootSlpPath = cfg.launcher.rootSlpPath;
                  useMonthlySubfolders = cfg.launcher.useMonthlySubfolders;
                  spectateSlpPath = cfg.launcher.spectateSlpPath;
                  extraSlpPaths = cfg.launcher.extraSlpPaths;
                  # Netplay
                  netplayDolphinPath = cfg.launcher.netplayDolphinPath;
                  # Playback
                  playbackDolphinPath = cfg.launcher.playbackDolphinPath;
                  # Advanced settings
                  autoUpdateLauncher = false;
                };
              };
          };
        };
    };
}
