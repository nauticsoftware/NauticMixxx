# Integrated updates in NauticMixxx 1.9.1

The first installation of 1.9.1 is manual because 1.9.0 only opens its download
page. Later releases can update inside NauticMixxx.

Choose **Download and Install** to download, verify, close and relaunch, or
**Download in Background** to keep using the app and install on quit. If
playback or Auto DJ begins during the download, an immediate restart is deferred
until you stop playback and press Install and Restart. Stopping playback alone
does not unexpectedly close the app.

Automatically downloading future updates is optional and disabled by default.
Enable or disable it in the Updates menu. Update Status shows a pending download
or a prepared installation. Closing the progress window keeps the download
running. If an update has not finished downloading and verifying when you quit,
the installed app remains unchanged.

The macOS installer is Sparkle 2.10.0 under its permissive open-source license.
It verifies the signed feed and archive and replaces the app after termination.
Windows verifies the Ed25519-signed manifest, size, SHA-256 and installer
signature, then a separate helper waits for shutdown and verifies again before
running NSIS. The Windows installer preserves an existing mixxx.cfg and
effects.xml on integrated upgrades. Libraries, audio routing and controller
settings remain in the user's profile.

The release key is in the maintainer's macOS Keychain under the account
`nauticmixxx-release-updates`; only its public key is in the repository. No paid
service, Apple Developer ID, notarization subscription or purchased signing
certificate is required. OS origin/security warnings can still appear.

## Preparing a release

Fetch the pinned free SDK with scripts/sparkle-sdk.py. Package the app using
configure-updater-macos.py; do not use codesign --deep to sign Sparkle's nested
installer services. After creating each final DMG or Windows Setup EXE, run:

```sh
python3 scripts/generate-update-feeds.py --release-dir build/release-candidate/1.9.1 --sdk /path/to/sparkle --platform macos
python3 scripts/generate-update-feeds.py --release-dir build/release-candidate/1.9.1 --sdk /path/to/sparkle --platform windows
```

The command fails if the Keychain public key does not match the embedded key.
Upload appcast-macos.xml and UPDATE_WINDOWS.json alongside the final artifacts.
Do not modify signed feeds or packages after signing. Never export a private
key into source, logs, CI artifacts or the public repository. Keep 1.9.0 intact
as the stable fallback while 1.9.1 is being validated.
