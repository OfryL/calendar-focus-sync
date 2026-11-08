# Releasing Calendar Focus Sync

Releases are produced by the [`Release` workflow](.github/workflows/release.yml). Pushing a tag `vX.Y.Z` runs two jobs on a macOS runner:

| Job | What it produces | Where it ends up |
| --- | --- | --- |
| `dmg` | Universal app signed with **Developer ID Application**, hardened runtime, notarized and stapled, packaged in a signed + notarized DMG | Attached to the GitHub Release for the tag |
| `app-store` | App signed with **Apple Distribution**, packaged with **Mac Installer Distribution**, uploaded with the App Store Connect API | A new build in App Store Connect, ready to submit for review |

Both jobs can also be run by hand from the Actions tab (**Release → Run workflow**), choosing `all`, `dmg` or `app-store`. A manual run does not create a GitHub Release; it uploads the DMG as a workflow artifact.

The notarized DMG is what fixes the "Apple could not verify this app is free of malware" message that the original unsigned downloads produced on macOS Sequoia.

## 1. One-time Apple setup

You need a paid [Apple Developer Program](https://developer.apple.com/programs/) membership.

### 1.1 Pick your bundle identifier

The upstream identifier `com.andrewglago.Calendar-Focus-Sync` belongs to the original author's team and cannot be registered again. This fork uses the value of `APP_BUNDLE_IDENTIFIER` in [`Config/Shared.xcconfig`](Config/Shared.xcconfig). Change it there if you want a different one, then register it:

1. [Certificates, Identifiers & Profiles → Identifiers](https://developer.apple.com/account/resources/identifiers/list) → **+** → **App IDs** → **App**.
2. Platform **macOS**, Bundle ID **Explicit**, paste the identifier. No capabilities need to be enabled (App Sandbox and calendar access are plain entitlements).

### 1.2 Certificates

Create these in [Certificates](https://developer.apple.com/account/resources/certificates/list) (or let Xcode create them under **Settings → Accounts → Manage Certificates**), then export each one from Keychain Access as a `.p12` with the same password:

| Certificate | Used by |
| --- | --- |
| **Developer ID Application** | `dmg` job (signing the app and the DMG) |
| **Apple Distribution** | `app-store` job (signing the app) |
| **Mac Installer Distribution** | `app-store` job (signing the `.pkg` that is uploaded) |

Only the team's Account Holder can create a Developer ID certificate.

### 1.3 App Store Connect API key

[App Store Connect → Users and Access → Integrations → Team Keys](https://appstoreconnect.apple.com/access/integrations/api) → **+**. Role **App Manager**. Download the `.p8` once (it cannot be downloaded again) and note the **Key ID** and **Issuer ID**. The same key is used for notarization and for uploading to App Store Connect.

### 1.4 Mac App Store provisioning profile

[Profiles](https://developer.apple.com/account/resources/profiles/list) → **+** → **Distribution → Mac App Store Connect** → select your App ID → select the **Apple Distribution** certificate → name it, e.g. `Calendar Focus Sync App Store`. Download the `.provisionprofile`.

### 1.5 App Store Connect app record

[App Store Connect → Apps](https://appstoreconnect.apple.com/apps) → **+** → **New App**, platform **macOS**, pick your bundle ID.

Things to know:

- **The name "Calendar Focus Sync" is already used by the original author's listing** (`id6472858223`). App names must be unique on the App Store, so either choose a different name for the listing (the app's display name inside macOS can stay the same) or ask the original author to transfer the app to your team.
- You must host a **privacy policy URL**. [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md) in this repository is a suitable text; a GitHub page or the raw file URL works.
- Category: Productivity. Age rating: 4+. Price: free (or whatever you decide).
- The app declares `ITSAppUsesNonExemptEncryption = NO`, so no export compliance questions are asked per build.
- Review notes: explain that the app installs a Shortcut named `calendar-focus-sync` because macOS exposes Focus Modes to third-party apps only via Shortcuts, and that calendar access is required to know when events start.

## 2. GitHub repository secrets

**Settings → Secrets and variables → Actions → New repository secret**. Encode binary files with `base64 -i FILE | pbcopy` on a Mac.

| Secret | Value | Needed by |
| --- | --- | --- |
| `APPLE_TEAM_ID` | 10-character Team ID (Membership details) | both |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID of the API key | both |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID of the API key | both |
| `APP_STORE_CONNECT_API_KEY_P8` | Full contents of the `AuthKey_XXXXXXXXXX.p8` file (plain text, including the BEGIN/END lines) | both |
| `CERTIFICATES_P12_PASSWORD` | Password used when exporting the `.p12` files | both |
| `DEVELOPER_ID_APPLICATION_P12` | base64 of the Developer ID Application `.p12` | `dmg` |
| `APPLE_DISTRIBUTION_P12` | base64 of the Apple Distribution `.p12` | `app-store` |
| `MAC_INSTALLER_DISTRIBUTION_P12` | base64 of the Mac Installer Distribution `.p12` | `app-store` |
| `APP_STORE_PROVISIONING_PROFILE` | base64 of the `.provisionprofile` from 1.4 | `app-store` |

Each job checks for its secrets first and fails with a list of what is missing.

## 3. Cutting a release

1. Bump the version. This sets `MARKETING_VERSION` and increments `CURRENT_PROJECT_VERSION` in `Config/Shared.xcconfig` (App Store Connect rejects a build number it has already seen):

   ```sh
   scripts/bump-version.sh 0.8.0
   ```

2. Add a `## 0.8.0` section to `CHANGELOG.md`.
3. Commit, tag and push:

   ```sh
   git commit -am "Release 0.8.0"
   git tag v0.8.0
   git push origin main --tags
   ```

   The workflow refuses to run if the tag does not match `MARKETING_VERSION`.

4. Watch the **Release** workflow. When it finishes:
   - the GitHub Release for `v0.8.0` carries `Calendar-Focus-Sync-0.8.0.dmg` and its SHA-256;
   - the build shows up under **TestFlight / Builds** in App Store Connect after Apple's processing (usually a few minutes). Attach it to a version in App Store Connect and **Submit for Review**. Submission itself is a manual step on purpose.

## 4. Releasing from Xcode instead

The pipeline is the preferred path, but everything can also be done locally:

- **DMG**: Product → Archive → Distribute App → **Direct Distribution** (Xcode signs with Developer ID and notarizes). Export the app, then `scripts/make-dmg.sh "Calendar Focus Sync.app" out.dmg "Developer ID Application"` and `xcrun notarytool submit out.dmg --keychain-profile ... --wait && xcrun stapler staple out.dmg`.
- **App Store**: Product → Archive → Distribute App → **App Store Connect** → Upload.

## 5. Troubleshooting

- **`errSecInternalComponent` / "unable to build chain to self-signed root"**: an Apple intermediate certificate is missing from the keychain. `scripts/ci/import-certificates.sh` installs the current Developer ID G2 and WWDR G3/G4 intermediates; if Apple issues a new one, add it to the list in that script.
- **Notarization `Invalid`**: the job prints `notarytool log` output. The usual causes are a missing secure timestamp (the workflow passes `--timestamp`), a non-hardened binary, or an unsigned nested binary.
- **`No profiles for '<bundle id>' were found`**: the provisioning profile secret does not match `APP_BUNDLE_IDENTIFIER`, or it was created for a different certificate. Regenerate it (1.4).
- **`ITMS-90xxx` errors on upload**: read the message; most are about the bundle version (bump `CURRENT_PROJECT_VERSION`), the missing privacy policy URL, or App Store Connect metadata, not the build.
- **Gatekeeper still complains on a user's Mac**: run `spctl --assess --type open --context context:primary-signature -v file.dmg` and `xcrun stapler validate "Calendar Focus Sync.app"`. Both must say accepted; the workflow runs the same checks before publishing.
