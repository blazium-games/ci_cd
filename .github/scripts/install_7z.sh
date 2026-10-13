#!/usr/bin/env bash
# Put 7z on PATH for the rest of the job.
# GitHub-hosted runners can apt-install p7zip-full. The release-builder
# runners have no passwordless sudo, so those get a user-local 7-Zip.
set -euo pipefail

if command -v 7z >/dev/null 2>&1 || command -v 7za >/dev/null 2>&1 || command -v 7zz >/dev/null 2>&1; then
  echo "7-Zip already on PATH: $(command -v 7z || command -v 7za || command -v 7zz)"
  exit 0
fi

if sudo -n true >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y p7zip-full
  exit 0
fi

echo "sudo needs a password; installing a user-local 7-Zip."
case "$(uname -m)" in
  x86_64) asset="7z2501-linux-x64.tar.xz" ;;
  aarch64 | arm64) asset="7z2501-linux-arm64.tar.xz" ;;
  *)
    echo "No 7-Zip build for $(uname -m)." >&2
    exit 1
    ;;
esac

dest="${RUNNER_TEMP:-/tmp}/7zip"
mkdir -p "$dest/bin"
curl -fsSL "https://www.7-zip.org/a/${asset}" -o "$dest/7z.tar.xz"
tar -xJf "$dest/7z.tar.xz" -C "$dest"
if [ -f "$dest/7zzs" ]; then
  src="$dest/7zzs"
elif [ -f "$dest/7zz" ]; then
  src="$dest/7zz"
else
  echo "7-Zip archive did not contain 7zzs or 7zz." >&2
  exit 1
fi
cp "$src" "$dest/bin/7z"
chmod +x "$dest/bin/7z"
if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$dest/bin" >>"$GITHUB_PATH"
fi
"$dest/bin/7z" i | head -n 3
