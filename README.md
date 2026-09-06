# Nimbus IDE — Android project

A thin native wrapper around the Nimbus IDE web app, ready to open in Android
Studio, run on a device, and publish to the Play Store — or build straight
from a phone using the included cloud workflow (see below).

## What this is

`app/src/main/assets/www/index.html` is the same single-file app as the
browser version — Monaco editor, autocomplete, on-device JS/Python execution,
a terminal, HTML/CSS live preview, and now a native "Open folder" flow.
`MainActivity.kt` loads it into a `WebView` through `WebViewAssetLoader`
(serves it on the `https://appassets.androidplatform.net` virtual origin,
which avoids `file://` quirks with Monaco's web worker and modern
`fetch()`/CORS-sensitive code).

`WebAppBridge.kt` adds a JavaScript bridge (`window.AndroidBridge`) giving the
app:
- permanent on-device key/value storage (used instead of `localStorage`)
- **Downloads-folder file export** for "Download file" / "Download project (.zip)"
- a native **"Open folder"** picker (Storage Access Framework) so you can point
  the IDE at a real folder on your phone — edits save straight back to those
  files, no import/export round-trip needed

Everything is feature-detected in the HTML, so the identical file still works
standalone in a browser (falling back to the File System Access API on
desktop Chrome/Edge, or plain import/export elsewhere) or inside the
Claude.ai artifact preview.

**Needs internet.** Monaco, JSZip, the editor font, and the Python runtime
(Pyodide, loaded lazily the first time you run a `.py` file) all load from
CDNs at runtime. JavaScript runs immediately with no download.

## Building on a computer

1. Install [Android Studio](https://developer.android.com/studio) (Iguana or
   newer).
2. **Open** this `android/` folder as a project (not the individual files).
3. Let Gradle sync — the wrapper (`gradlew`, `gradle-wrapper.jar`) is already
   included, so this should just work.
4. Press **Run ▶** with a device or emulator selected (API 29 / Android 10+).

## Building an APK from your phone

You don't need a computer or Android Studio to get an installable APK. Two
ways, from easiest to most self-contained:

### Option A — GitHub Actions (recommended)

The project already includes `.github/workflows/build.yml`, which builds a
debug APK on GitHub's servers and hands you a download link.

1. Create a free [GitHub](https://github.com) account if you don't have one.
2. Create a new **public or private repository** (the GitHub mobile app, or
   github.com in your phone's browser, both work for this).
3. Upload the contents of this `android/` folder into that repo. Easiest
   ways from a phone:
   - Use the GitHub mobile app's "Add file → Upload files" (repeat per
     folder, or use "Create file" and paste content for small tweaks), or
   - Install [Termux](https://f-droid.org/packages/com.termux/) and run
     `git init && git add . && git commit -m "Nimbus IDE" && git remote add
     origin <your-repo-url> && git push -u origin main`, or
   - From a borrowed computer, `git push` once — after that all further
     builds can be triggered entirely from your phone.
4. Open the repo on GitHub → **Actions** tab → **Build APK** → **Run
   workflow** (or just push a commit; it also runs automatically on pushes
   to `main`).
5. Wait a few minutes, open the finished run, and download the
   **nimbus-ide-debug-apk** artifact — it's a `.zip` containing
   `app-debug.apk`.
6. On your phone: unzip it (most file manager apps can), tap the `.apk`,
   allow "install unknown apps" for your browser/file manager if prompted,
   and install.

This gives you a debug build (unsigned, fine for your own testing). For a
Play-Store-ready signed release, either add signing secrets to the workflow
and switch the build step to `assembleRelease`/`bundleRelease`, or do the
signing step on a computer once you're ready to publish (see below).

### Option B — Termux, fully on-device

More self-contained, but slower and heavier (multi-GB SDK download over
mobile data/Wi-Fi):

```
pkg install openjdk-17 gradle git
git clone <your-repo-url> nimbus && cd nimbus
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"
export ANDROID_HOME=$PREFIX/share/android-sdk
./gradlew assembleDebug
```

The resulting APK lands in `app/build/outputs/apk/debug/app-debug.apk`.
Termux's package repos don't ship a full `sdkmanager`/Android SDK out of the
box, so this path needs a bit more manual setup than Option A — Option A is
the more reliable route on a phone.

## Before you publish to the Play Store

- **`applicationId`** in `app/build.gradle` is set to `com.nimbus.ide` —
  change it to your own reverse-domain id before your first upload. The Play
  Store treats this as permanent once published.
- **App icon** — `ic_launcher_foreground.xml` / `ic_launcher_background.xml`
  are a simple placeholder mark. Right-click `res` → **New → Image Asset** in
  Android Studio to generate a polished launcher icon from your own artwork.
- **Signing** — `Build → Generate Signed App Bundle`, create a keystore (keep
  it safe — losing it means you can never update the app again), and build a
  release `.aab`. This step needs a computer; the cloud/Termux paths above
  are for quick installable debug builds, not store submission.
- **Play Console** — create an app at
  [play.google.com/console](https://play.google.com/console), fill in the
  store listing, content rating questionnaire, and Data Safety form (this app
  writes files locally, to Downloads, and to folders you explicitly choose;
  it does not transmit user data anywhere), then upload the `.aab` to an
  internal testing track first.

## Version bumps

Bump `versionCode` (integer, must increase every release) and `versionName`
(the human-readable string) in `app/build.gradle` before each new upload.
