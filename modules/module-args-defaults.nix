# SPDX-FileCopyrightText: 2025-present arcanesys contributors
#
# SPDX-License-Identifier: MIT
#
# Safe defaults for module arguments that are normally injected by
# lib.mkTerminal. Consumers who compose securix modules directly
# (without mkTerminal) get empty defaults instead of eval errors.
{ lib, ... }:
{
  _module.args.operators = lib.mkDefault { };
  _module.args.vpnProfiles = lib.mkDefault { };
}
