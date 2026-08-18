# PharmaPath — Android APK build script (WebView wrapper)
# Requires: JDK 11+, Android build-tools 34+, platform android-35
# Usage: set ANDROID_HOME, then run from repo root: ./android/build_apk.sh

set -e
BT="${ANDROID_HOME:?set ANDROID_HOME}/build-tools"
PLATFORM="${ANDROID_HOME}/platforms/android-35/android.jar"
KEYTOOL="keytool"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/android"
BUILD="/tmp/pharmapath-apkbuild"

rm -rf "$BUILD" && mkdir -p "$BUILD/obj" "$BUILD/dex" "$BUILD/assets"
cp "$ROOT/app/index.html" "$BUILD/assets/index.html"

echo "== 1/6 javac =="
javac -encoding UTF-8 -source 8 -target 8 -bootclasspath "$PLATFORM" -d "$BUILD/obj" \
  "$P/src/com/pharmapath/app/MainActivity.java"

echo "== 2/6 d8 =="
"$BT/d8" --lib "$PLATFORM" --release --output "$BUILD/dex" \
  "$BUILD"/obj/com/pharmapath/app/*.class

echo "== 3/6 aapt2 =="
"$BT/aapt2" compile --dir "$P/res" -o "$BUILD/res.zip"
"$BT/aapt2" link -o "$BUILD/base.apk" -I "$PLATFORM" \
  --manifest "$P/AndroidManifest.xml" -A "$BUILD/assets" "$BUILD/res.zip"

echo "== 4/6 add classes.dex =="
(cd "$BUILD" && zip -jq base.apk dex/classes.dex)

echo "== 5/6 zipalign =="
"$BT/zipalign" -f 4 "$BUILD/base.apk" "$BUILD/aligned.apk"

echo "== 6/6 sign =="
if [ ! -f "$BUILD/pharmapath.keystore" ]; then
  "$KEYTOOL" -genkeypair -keystore "$BUILD/pharmapath.keystore" -alias pharmapath \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass pharmapath123 -keypass pharmapath123 \
    -dname "CN=PharmaPath, OU=Dev, O=PharmaPath, C=IN" 2>/dev/null
fi
"$BT/apksigner" sign --ks "$BUILD/pharmapath.keystore" \
  --ks-pass pass:pharmapath123 --key-pass pass:pharmapath123 \
  --out "$BUILD/PharmaPath.apk" "$BUILD/aligned.apk"
"$BT/apksigner" verify "$BUILD/PharmaPath.apk"

mkdir -p "$ROOT/releases"
cp "$BUILD/PharmaPath.apk" "$ROOT/releases/PharmaPath.apk"
echo "✅ Done → releases/PharmaPath.apk"
