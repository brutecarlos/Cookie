#!/usr/bin/env bash
set -euo pipefail

# release.sh [version]
# - If version provided: set manifest.json to that version
# - Else: bump patch version

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$ROOT_DIR/manifest.json"
cd "$ROOT_DIR"

if [[ ! -f "$MANIFEST" ]]; then
  echo "manifest.json not found at $MANIFEST" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

if [[ $# -gt 0 ]]; then
  NEW_VER="$1"
else
  NEW_VER="$(python3 - <<'PY'
import json
with open('manifest.json','r',encoding='utf8') as f:
    m=json.load(f)
v=m.get('version','0.0.0').split('.')
while len(v)<3:
    v.append('0')
v[-1]=str(int(v[-1])+1)
print('.'.join(v))
PY
)"
fi

python3 - <<PY
import json
with open('manifest.json','r',encoding='utf8') as f:
    m=json.load(f)
m['version']='$NEW_VER'
with open('manifest.json','w',encoding='utf8') as f:
    json.dump(m,f,indent=2,ensure_ascii=False)
print('manifest.json set to', '$NEW_VER')
PY

PNG_DIR="$ROOT_DIR/store/screenshots/pngs"
mkdir -p "$PNG_DIR"

CONV=""
# prefer robust SVG renderers before ImageMagick
if command -v rsvg-convert >/dev/null 2>&1; then
  CONV="rsvg-convert"
elif command -v inkscape >/dev/null 2>&1; then
  CONV="inkscape"
elif command -v magick >/dev/null 2>&1; then
  CONV="magick"
elif command -v convert >/dev/null 2>&1; then
  CONV="convert"
fi

render_one() {
  local input="$1" width="$2" height="$3" output="$4"
  if [[ -z "$CONV" ]]; then
    echo "No SVG converter installed. Skipping $input"
    return 0
  fi

  echo "Rendering $input -> $output (${width}x${height}) with $CONV"
  if [[ "$CONV" == "rsvg-convert" ]]; then
    rsvg-convert -w "$width" -h "$height" "$input" -o "$output" || {
      echo "WARN: failed rendering $input" >&2
      return 0
    }
  elif [[ "$CONV" == "inkscape" ]]; then
    inkscape "$input" --export-type=png --export-filename="$output" --export-width="$width" --export-height="$height" || {
      echo "WARN: failed rendering $input" >&2
      return 0
    }
  else
    "$CONV" "$input" -background none -resize "${width}x${height}" "$output" || {
      echo "WARN: failed rendering $input" >&2
      return 0
    }
  fi
}

render_one "store/screenshots/hero-fortune-cookie.svg" 1280 720 "$PNG_DIR/hero-fortune-cookie.png"
render_one "store/screenshots/screenshot-fortune-1.svg" 640 400 "$PNG_DIR/screenshot-fortune-1.png"
render_one "store/screenshots/screenshot-fortune-2.svg" 440 280 "$PNG_DIR/screenshot-fortune-2.png"

if [[ -f ./package.sh ]]; then
  chmod +x ./package.sh
  ./package.sh
else
  echo "package.sh not found" >&2
  exit 1
fi

if command -v git >/dev/null 2>&1 && [[ -d .git ]]; then
  git add --all
  git commit -m "release: v${NEW_VER}" || echo "No changes to commit"
  git tag -f "v${NEW_VER}" || true
  echo "Created/updated local tag v${NEW_VER}"
fi

echo "Release complete: version $NEW_VER"
echo "ZIP: $ROOT_DIR/cookie-extension.zip"
exit 0
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "Release script starting in $ROOT"

# bump patch version in manifest.json using python
if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to bump manifest version. Aborting." >&2
  exit 2
fi

NEW_VER=$(python3 - <<'PY'
import json,sys
fn='manifest.json'
with open(fn,'r',encoding='utf8') as f:
    m=json.load(f)
v=m.get('version','0.1.0')
parts=v.split('.')
while len(parts)<3: parts.append('0')
parts[-1]=str(int(parts[-1])+1)
nv='.'.join(parts)
m['version']=nv
with open(fn,'w',encoding='utf8') as f:
    json.dump(m,f,indent=2,ensure_ascii=False)
print(nv)
PY
)

echo "Bumped manifest version -> ${NEW_VER}"

# render SVGs to PNGs if possible
OUTDIR="${ROOT}/store/screenshots/pngs"
mkdir -p "$OUTDIR"
CONV=""
if command -v magick >/dev/null 2>&1; then CONV=magick
elif command -v convert >/dev/null 2>&1; then CONV=convert
elif command -v rsvg-convert >/dev/null 2>&1; then CONV=rsvg-convert
elif command -v inkscape >/dev/null 2>&1; then CONV=inkscape
fi

render(){
  local in="$1"; local w="$2"; local h="$3"; local out="$4"
  if [ -z "$CONV" ]; then
    echo "No SVG converter found; skipping render for $in"
    return
  fi
  echo "Rendering $in -> $out (${w}x${h}) with $CONV"
  if [[ "$CONV" == "magick" || "$CONV" == "convert" ]]; then
    $CONV "$in" -background none -resize ${w}x${h} "$out"
  elif [[ "$CONV" == "rsvg-convert" ]]; then
    $CONV -w $w -h $h -o "$out" "$in"
  else
    # inkscape
    $CONV "$in" --export-type=png --export-filename="$out" --export-width=$w --export-height=$h
  fi
}

render "store/screenshots/hero-fortune-cookie.svg" 1280 720 "$OUTDIR/hero-fortune-cookie.png"
render "store/screenshots/screenshot-fortune-1.svg" 640 400 "$OUTDIR/screenshot-fortune-1.png"
render "store/screenshots/screenshot-fortune-2.svg" 440 280 "$OUTDIR/screenshot-fortune-2.png"

# git commit and tag
if command -v git >/dev/null 2>&1; then
  git add --all
  if git rev-parse --verify HEAD >/dev/null 2>&1; then
    git commit -m "Release v${NEW_VER}" || echo "No changes to commit"
  else
    git commit -m "Initial release v${NEW_VER}" || echo "No changes to commit"
  fi
  git tag -a "v${NEW_VER}" -m "Release v${NEW_VER}" || echo "Tag may already exist"
else
  echo "git not found; skipping commit and tag"
fi

# run package.sh to create zip
if [ -x ./package.sh ]; then
  ./package.sh
  echo "Package created: cookie-extension.zip"
else
  echo "package.sh not executable or missing; make it executable and run ./package.sh to create the zip"
fi

echo "Release script finished. Version: ${NEW_VER}"
echo "If you want to push tags/commits, run: git push origin --follow-tags"
#!/usr/bin/env bash
set -euo pipefail
# release.sh [version]
# If version is provided, set manifest.json to it. Otherwise bump patch version.
ROOT="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="$ROOT/manifest.json"
cd "$ROOT"

if [ ! -f "$MANIFEST" ]; then
  echo "manifest.json not found" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  NEW_VER="$1"
else
  # bump patch using python
  NEW_VER=$(python3 - <<PY
import json
mf='manifest.json'
with open(mf) as f:
    j=json.load(f)
v=j.get('version','0.0.0')
parts=v.split('.')
while len(parts)<3: parts.append('0')
parts[-1]=str(int(parts[-1])+1)
print('.'.join(parts))
PY
)
fi

echo "Setting manifest version -> $NEW_VER"
python3 - <<PY
import json
mf='manifest.json'
with open(mf) as f:
    j=json.load(f)
j['version']='$NEW_VER'
with open(mf,'w') as f:
    json.dump(j,f,indent=2)
print('manifest.json updated')
PY

# Git commit & tag
if ! command -v git >/dev/null 2>&1; then
  echo "git not found; skipping commit/tag" >&2
else
  if [ ! -d .git ]; then
    git init
    git checkout -b main || true
  fi
  git add manifest.json
  git commit -m "chore: bump version to $NEW_VER" || true
  git tag -f "v$NEW_VER" || true
fi

# Render SVGs to PNGs if possible
PNG_DIR="$ROOT/store/screenshots/pngs"
mkdir -p "$PNG_DIR"
convert_cmd=""
if command -v magick >/dev/null 2>&1; then
  convert_cmd="magick"
elif command -v convert >/dev/null 2>&1; then
  convert_cmd="convert"
elif command -v rsvg-convert >/dev/null 2>&1; then
  convert_cmd="rsvg-convert"
elif command -v inkscape >/dev/null 2>&1; then
  convert_cmd="inkscape"
fi

if [ -n "$convert_cmd" ]; then
  echo "Using $convert_cmd to render screenshots"
  if [ "$convert_cmd" = "rsvg-convert" ]; then
    rsvg-convert -w 1280 -h 720 store/screenshots/hero-fortune-cookie.svg -o "$PNG_DIR/hero-fortune-cookie.png" || true
    rsvg-convert -w 640 -h 400 store/screenshots/screenshot-fortune-1.svg -o "$PNG_DIR/screenshot-fortune-1.png" || true
    rsvg-convert -w 440 -h 280 store/screenshots/screenshot-fortune-2.svg -o "$PNG_DIR/screenshot-fortune-2.png" || true
  elif [ "$convert_cmd" = "inkscape" ]; then
    inkscape store/screenshots/hero-fortune-cookie.svg --export-type=png --export-filename="$PNG_DIR/hero-fortune-cookie.png" --export-width=1280 --export-height=720 || true
    inkscape store/screenshots/screenshot-fortune-1.svg --export-type=png --export-filename="$PNG_DIR/screenshot-fortune-1.png" --export-width=640 --export-height=400 || true
    inkscape store/screenshots/screenshot-fortune-2.svg --export-type=png --export-filename="$PNG_DIR/screenshot-fortune-2.png" --export-width=440 --export-height=280 || true
  else
    # ImageMagick convert/magick
    "$convert_cmd" store/screenshots/hero-fortune-cookie.svg -background none -resize 1280x720 "$PNG_DIR/hero-fortune-cookie.png" || true
    "$convert_cmd" store/screenshots/screenshot-fortune-1.svg -background none -resize 640x400 "$PNG_DIR/screenshot-fortune-1.png" || true
    "$convert_cmd" store/screenshots/screenshot-fortune-2.svg -background none -resize 440x280 "$PNG_DIR/screenshot-fortune-2.png" || true
  fi
else
  echo "No SVG->PNG converter found; skipping image rendering" >&2
fi

# Package
if [ -f ./package.sh ]; then
  chmod +x ./package.sh
  ./package.sh
  echo "Packaging complete: cookie-extension.zip"
else
  echo "package.sh missing; cannot create zip" >&2
fi

echo "Release done. Version: $NEW_VER"

#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

if ! command -v git >/dev/null 2>&1; then
  echo "git required" >&2
  exit 1
fi

# bump package: commit current changes, tag with provided tag or date
TAG=${1:-"v$(date +%Y.%m.%d)"}
git add --all
git commit -m "Release ${TAG}" || true
git tag -f "$TAG"

# create zip
if [ -x ./package.sh ]; then
  ./package.sh
  echo "Packaged extension: cookie-extension.zip"
else
  echo "package.sh not found or not executable" >&2
fi

echo "Created tag $TAG (local). Push with: git push origin --tags && git push"
#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

echo "Running package script..."
chmod +x ./package.sh || true
./package.sh

ZIP="$ROOT_DIR/cookie-extension.zip"
if [ -f "$ZIP" ]; then
  echo "Created $ZIP"
else
  echo "Packaging failed: $ZIP not found" >&2
  exit 1
fi

if command -v git >/dev/null 2>&1; then
  git add package.sh release.sh manifest.json
  git commit -m "chore(release): package extension" || true
  TAG="v$(jq -r .version manifest.json 2>/dev/null || echo 1.1.0)"
  git tag -f "$TAG" || true
  echo "Created git tag $TAG (local). Push it when ready: git push origin $TAG"
fi

echo "Release packaging complete. Upload $ZIP to Chrome Web Store." 
