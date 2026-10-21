#!/usr/bin/env bash
set -eu
# Configure the disposable macOS runner using Godot's standard settings path.
GODOT_BIN_DIR=/tmp/ishaq-android-godot/Godot.app/Contents/MacOS
GODOT_DATA_DIR="$HOME/Library/Application Support/Godot"
if [ "${1:-}" != setup ] && [ "${1:-}" != check-sdk ]; then
  echo "Usage: bash tools/ci-android.sh setup|check-sdk" >&2
  exit 2
fi
TASK_ANDROID_SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [ -z "$TASK_ANDROID_SDK" ]; then
  echo "Codemagic Android SDK was not found" >&2
  exit 1
fi
TASK_SDKMANAGER=""
if command -v sdkmanager >/dev/null 2>&1; then
  TASK_SDKMANAGER="$(command -v sdkmanager)"
else
  # Codemagic may provide command-line tools without adding them to PATH.
  for candidate in "$TASK_ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager" "$TASK_ANDROID_SDK"/cmdline-tools/*/bin/sdkmanager "$TASK_ANDROID_SDK/tools/bin/sdkmanager"; do
    if [ -x "$candidate" ]; then
      TASK_SDKMANAGER="$candidate"
      break
    fi
  done
fi
if [ -z "$TASK_SDKMANAGER" ]; then
  echo "Android SDK found at $TASK_ANDROID_SDK, but sdkmanager is missing from PATH and its command-line tools folders." >&2
  exit 1
fi
if [ "${1:-}" = check-sdk ]; then
  echo "Android sdkmanager: $TASK_SDKMANAGER"
  exit 0
fi
: "${JAVA_HOME:?Codemagic Java 17 must be configured}"
"$TASK_SDKMANAGER" --sdk_root="$TASK_ANDROID_SDK" "platform-tools" "build-tools;35.0.0" "platforms;android-35"
mkdir -p "$GODOT_DATA_DIR/export_templates/${GODOT_VERSION}.stable"
unzip -p /tmp/ishaq-templates.zip templates/android_debug.apk > "$GODOT_DATA_DIR/export_templates/${GODOT_VERSION}.stable/android_debug.apk"
# Debug-only key. Reuse Codemagic's existing debug key when available.
TASK_DEBUG_KEY="$HOME/.android/debug.keystore"
mkdir -p "$HOME/.android"
if [ ! -f "$TASK_DEBUG_KEY" ]; then
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$TASK_DEBUG_KEY" -storepass android -alias androiddebugkey -keypass android -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
fi
cat > "$GODOT_DATA_DIR/editor_settings-4.5.tres" <<SETTINGS
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$TASK_ANDROID_SDK"
export/android/debug_keystore = "$TASK_DEBUG_KEY"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
SETTINGS
