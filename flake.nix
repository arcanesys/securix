# SPDX-FileCopyrightText: 2025 s33d <abstract.s33d@gmail.com>
#
# SPDX-License-Identifier: MIT
{
  description = "Sécurix — NixOS-based hardened endpoint OS (flake wrapper)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    let
      # Re-use Sécurix's own default.nix. We pass `sources = inputs // npins`
      # so flake inputs override npins defaults where present, and npins is
      # the fallback for any source the flake doesn't provide (e.g. git-hooks).
      securixFor =
        system:
        let
          pkgs = import inputs.nixpkgs { inherit system; };
          npins = import ./npins;
        in
        import ./. {
          inherit pkgs;
          sources = inputs // npins;
        };

      # Hardware SKUs exposed as individual modules
      hardwareSKUs = [
        "x280"
        "elitebook645g11"
        "elitebook850g8"
        "latitude5340"
        "t14g6"
        "x9-15"
        "e14-g7"
      ];
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        sx = securixFor system;
      in
      {
        packages = {
          inherit (sx) shell;
        };

        devShells.default = sx.shell;

        # Re-expose the full Sécurix toolkit output (lib, pkgs, modules,
        # tests, shell) indexed by system for consumers that need it.
        legacyPackages.sx = sx;
      }
    )
    // {
      # NixOS modules available to any flake consumer (e.g. nixfleet mkHost)
      nixosModules = {
        # Sécurix base: all ANSSI hardening + user model + VPN + PAM + etc.
        securix-base = ./modules;

        # Hardware profiles keyed by SKU (must match securix.self.machine.hardwareSKU)
        securix-hardware = builtins.listToAttrs (
          map (sku: {
            name = sku;
            value = ./hardware/${sku}.nix;
          }) hardwareSKUs
        );

        # Aggregate: all hardware profiles
        securix-hardware-all = ./hardware;
      };

      # Package overlay (custom Sécurix packages)
      overlays.default = import ./pkgs/overlay.nix;

      # System-indexed lib accessor (Sécurix's lib depends on pkgs)
      lib = {
        forSystem = system: (securixFor system).lib;
      };
    };
}
