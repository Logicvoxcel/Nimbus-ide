# Nimbus IDE — Flutter app

A native Flutter rewrite of Nimbus IDE, replacing the earlier single-file
HTML app wrapped in an Android WebView.

## Why the rewrite

The WebView version depended on loading Monaco, JSZip, and a web font from
CDNs at runtime — any of that failing to load (no connection, a blocked
domain, a WebView quirk) meant a blank, broken app. This version has **no
network dependency at all**: the editor, syntax highlighting, file access,
and JavaScript execution all run natively on-device. There's deliberately no
`INTERNET` permission in the manifest.

## What works right now

- Syntax highlighting for 25+ languages (`lib/services/language_map.dart`
  is the single place to add more).
- Auto-indent on Enter (matches the previous line, plus one level deeper
  after an opening bracket/colon) — built on plain `TextEditingController`
  APIs rather than relying on an editor package's undocumented internals.
- Real files: everything lives directly on your device's storage via normal
  file I/O — no more serializing a virtual filesystem into a storage blob.
- **Open folder (device)** — uses Android's Storage Access Framework
  (via `file_picker`) to load a real folder from your phone. Edits save
  straight back to those exact files.
- Import loose files or a whole `.zip` project; export a file or the whole
  project as a `.zip` through the native share sheet.
- **Run** executes JavaScript instantly on-device via an embedded engine
  (`flutter_js`, zero setup needed), and everything else —
  **Python, C, C++, Java, Go, Ruby, PHP, Rust, Bash, Perl, Lua** — through
  [Termux](https://github.com/termux/termux-app), a free, open-source
  terminal app. See "Running non-JS languages" below.
- Dark/light theme toggle, adjustable font size, a symbol row above the
  keyboard for characters mobile keyboards bury.

## Running non-JS languages (Termux)

Rather than bundle a separate paid SDK per language (the realistic option
for embedded Python, Chaquopy, needs a commercial license for closed-source
apps), Nimbus talks to [Termux](https://github.com/termux/termux-app) —
GPL-3.0, free, and since we only communicate with it over Android's normal
inter-app Intent messaging (never linking its code into our binary), that
doesn't pull this app under GPL either. One integration gets us every
language Termux can install, instead of one engine per language.

**How it works:** `android/app/src/main/kotlin/com/nimbus/ide/MainActivity.kt`
implements Termux's documented
[RUN_COMMAND intent API](https://github.com/termux/termux-app/wiki/RUN_COMMAND-Intent).
Files inside an **opened folder** run at their real, existing path directly.
Files in the app's own private project folder get staged first into the
public `Download/NimbusIDE/run/` folder via MediaStore (deliberately not
using the broader `MANAGE_EXTERNAL_STORAGE` permission — that one draws
heavy Play Store scrutiny for apps that aren't file managers).

**What the user needs to do once:** install Termux from F-Droid (not the
Play Store listing — it's been discontinued for years), grant this app's
"Termux status" button the RUN_COMMAND permission when prompted, then run
`termux-setup-storage` and `pkg install <whatever languages you want>`
inside Termux itself. The in-app Termux status sheet (terminal icon in the
top bar) walks through all of this and shows exactly which step is next.

**Honest limitation:** RUN_COMMAND's result comes back as one bundle after
the whole process exits — there's no live-streaming output or interactive
stdin mid-run yet. Fine for scripts and short programs; a long-running or
interactive program will show nothing until it finishes.

## Not built yet

- **Autocomplete / IntelliSense-style suggestions.** Queued as the next
  focused piece — it touches cursor-position tracking and overlay
  rendering, real surface area on its own, so it's deliberately not bolted
  onto this same pass alongside the Termux integration above.
- **Find & replace** and **HTML/CSS live preview** from the earlier web
  version.


## Package versions

Pinned with caret ranges in `pubspec.yaml` based on each package's
documented API at the time this was written. Since this was authored
without a local Flutter/Dart toolchain to run `flutter pub get` against,
**the very first thing to do is run it** and fix up any version conflicts
Pub reports -- particularly `file_picker`, which had a breaking API change
around its v12 release (this code targets the pre-v12, `FilePickerResult?`
style API, matching the `^8.1.2` constraint in `pubspec.yaml`).

## Gradle / AGP / Kotlin versions

If you're picking this project back up after a build failure: the
`android/` files now pin **Gradle 8.14.1, Android Gradle Plugin 8.11.1, and
Kotlin 2.2.20** (`android/gradle/wrapper/gradle-wrapper.properties` and
`android/settings.gradle`). The original version of this project pinned much
older versions (Gradle 8.7, AGP 8.3.0, Kotlin 1.9.22) that predate Flutter
3.44's requirement of Kotlin Gradle Plugin 2.0.0+ -- bumping only the Gradle
wrapper without also bumping AGP and Kotlin together (they have to move as a
compatible set) is why that didn't fix it.

If a future Flutter upgrade breaks this again, the most reliable fix isn't
to hand-guess new numbers -- run `flutter create --platforms=android .` in
the project root with your current Flutter SDK. It regenerates `android/`'s
Gradle files to match whatever version you actually have installed (this is
Flutter's own documented recommendation for stale build scripts), though
you'll need to re-apply the custom launcher icon and dark launch background
afterward since that step overwrites them with Flutter's defaults.


## Building on a computer

1. Install [Flutter](https://docs.flutter.dev/get-started/install) and
   Android Studio.
2. `flutter pub get`
3. `flutter run` (device or emulator selected), or open `android/` in
   Android Studio if you prefer its UI.

## Building an APK from your phone

Same cloud-build approach as before -- `.github/workflows/build.yml` is
already included.

1. Push this project to a GitHub repo (GitHub mobile app's file upload, or
   `git push` from a computer or Termux).
2. Repo → **Actions** tab → **Build APK** → **Run workflow** (or just push
   to `main`).
3. Download the **nimbus-ide-debug-apk** artifact once the run finishes,
   unzip it on your phone, and tap the `.apk` to install (allow "install
   unknown apps" if prompted).

## Before you publish to the Play Store

- Change `applicationId` in `android/app/build.gradle` from `com.nimbus.ide`
  to your own reverse-domain id -- permanent once you upload.
- Regenerate the launcher icon from your own artwork (the current one is a
  simple placeholder mark) -- Android Studio's **Image Asset** tool, or
  `flutter pub run flutter_launcher_icons` if you add that package.
- Set up real release signing (`android/app/build.gradle` currently signs
  release builds with the debug key so `flutter build apk --release` works
  out of the box for testing -- replace `signingConfigs.debug` with your own
  keystore config before shipping).
- Build the actual release artifact Google wants: `flutter build appbundle`.
- Fill in the Play Console's store listing, content rating, and Data Safety
  form (this app writes files locally, to Downloads/shared locations via
  the share sheet, and to folders you explicitly open -- it does not
  transmit anything over the network).
