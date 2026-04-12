#!/bin/bash
set -euo pipefail

EXTENSIONS_DIR="${EXTENSIONS_DIR:-/opt/extensions}"
MARKETPLACE_API_URL="https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery?api-version=3.0-preview.1"
MARKETPLACE_QUERY_FLAGS=103

MANAGED_EXTENSIONS=(
  "antfu.iconify"
  "antfu.icons-carbon"
  "antfu.open-in-github-button"
  "antfu.theme-vitesse"
  "antfu.unocss"
  "dbaeumer.vscode-eslint"
  "johnsoncodehk.vscode-tsconfig-helper"
  "ms-vscode.vscode-typescript-next"
  "MS-CEINTL.vscode-language-pack-zh-hans"
  "npmx-dev.vscode-npmx"
  "VoidZero.vite-plus-extension-pack"
  "usernamehw.errorlens"
  "vue.volar"
  "yoavbls.pretty-ts-errors"
)

mkdir -p "$EXTENSIONS_DIR"

query_extension() {
  local extension_id="$1"

  curl -fsSL \
    -H "accept: application/json;api-version=3.0-preview.1;excludeUrls=false" \
    -H "content-type: application/json" \
    -H "user-agent: code-server-extension-updater" \
    -H "x-market-client-id: code-server-extension-updater" \
    -X POST \
    -d "$(cat <<EOF
{
  "filters": [
    {
      "criteria": [
        {
          "filterType": 7,
          "value": "$extension_id"
        }
      ],
      "direction": 2,
      "pageNumber": 1,
      "pageSize": 1,
      "sortBy": 0,
      "sortOrder": 0
    }
  ],
  "assetTypes": [],
  "flags": $MARKETPLACE_QUERY_FLAGS
}
EOF
)" \
    "$MARKETPLACE_API_URL"
}

resolve_latest_version() {
  printf '%s' "$1" | node -e '
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", chunk => input += chunk);
process.stdin.on("end", () => {
const payload = JSON.parse(input);
const extension = payload.results?.[0]?.extensions?.[0];
if (!extension) process.exit(2);
const stable = extension.versions.find(version => version.targetPlatform === "undefined" || version.targetPlatform === undefined);
const latest = stable ?? extension.versions?.[0];
if (!latest) process.exit(3);
const packageFile = latest.files?.find(file => file.assetType === "Microsoft.VisualStudio.Services.VSIXPackage");
const url = packageFile?.source
  ?? (latest.assetUri ? `${latest.assetUri}/Microsoft.VisualStudio.Services.VSIXPackage` : undefined)
  ?? (latest.fallbackAssetUri ? `${latest.fallbackAssetUri}/Microsoft.VisualStudio.Services.VSIXPackage` : undefined);
if (!url) process.exit(4);
process.stdout.write(JSON.stringify({ version: latest.version, url }));
});
'
}

cleanup_old_versions() {
  local extension_id="$1"
  local keep_file="$2"

  find "$EXTENSIONS_DIR" -maxdepth 1 -type f -name "${extension_id}-*.vsix" ! -name "$keep_file" -delete
}

download_extension() {
  local extension_id="$1"
  local payload resolved version url file_name destination tmp_file

  echo "[info] Checking $extension_id"
  payload="$(query_extension "$extension_id")"
  resolved="$(resolve_latest_version "$payload")"
  version="$(printf '%s' "$resolved" | node -e 'let input = ""; process.stdin.setEncoding("utf8"); process.stdin.on("data", chunk => input += chunk); process.stdin.on("end", () => process.stdout.write(JSON.parse(input).version));')"
  url="$(printf '%s' "$resolved" | node -e 'let input = ""; process.stdin.setEncoding("utf8"); process.stdin.on("data", chunk => input += chunk); process.stdin.on("end", () => process.stdout.write(JSON.parse(input).url));')"

  file_name="${extension_id}-${version}.vsix"
  destination="$EXTENSIONS_DIR/$file_name"
  tmp_file="${destination}.download"

  if [ -f "$destination" ]; then
    echo "[skip] $extension_id already at $version"
    cleanup_old_versions "$extension_id" "$file_name"
    return 0
  fi

  echo "[done] Downloading $extension_id@$version"
  curl -fsSL -H "user-agent: code-server-extension-updater" "$url" -o "$tmp_file"
  mv "$tmp_file" "$destination"
  cleanup_old_versions "$extension_id" "$file_name"
}

for extension_id in "${MANAGED_EXTENSIONS[@]}"; do
  download_extension "$extension_id"
done
