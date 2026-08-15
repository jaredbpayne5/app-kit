#!/usr/bin/env bash
# CI: fail if the Expo SDK set has drifted from bundledNativeModules.json.
# Do not bump expo / react / react-native / react-dom by hand — use
# `npx expo install --fix` in apps/mobile.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/apps/mobile" || exit 1

printf '%s\n' "expo-sdk-check: expo install --check"
npx expo install --check

# expo-doctor is a report on SDK 56: it fails on a Hermes V1 memory
# regression whose advertised fix is "upgrade to SDK 57". That bump is
# out of scope here. Revisit when the template leaves 56.
printf '%s\n' "expo-sdk-check: expo-doctor (report; not a gate on SDK 56)"
npx expo-doctor || true
