# Chaty — Modern Flutter Messaging App

Chaty is a full-featured, mobile-first instant messaging application built in Flutter with Riverpod, GoRouter, Dio, SQLite, and WebSocket. It connects seamlessly to the backend server with real-time bidirectional communication, rich attachments, offline caching, stories, and customizable themes.

---

## 🚀 Features

- **Authentication & Onboarding**:
  - Phone, username, display name, and password registration & login.
  - Secure token storage with auto-login on app launch and graceful logout.
- **Conversations & Real-Time Chat**:
  - Live chat list with avatars, unread message badges, last message previews, timestamps, and online indicators.
  - Optimistic message sending with `client_id` and retry capability on failure.
  - Message status ticks (Sent `✓`, Delivered `✓✓`, Read `✓✓` colored).
  - Infinite scroll upward for paginated message history.
  - Real-time typing indicators.
- **Rich Media & Attachments**:
  - Image messages with thumbnail previews and full-screen pinch-to-zoom viewer.
  - Voice notes: hold-to-record with slide-to-cancel, timer, waveform/progress indicator, playback speed adjustment (`1.0x`, `1.5x`, `2.0x`).
  - File messages with icon, filename, formatted file size, download, and external viewer integration.
  - 3 bundled vector sticker packs (36 SVG stickers total: Emojis, Cute Cats, Gestures) with recent stickers drawer.
- **Stories**:
  - Top stories carousel with "My Story" (add story button) and contacts' stories rings.
  - Create photo/camera stories with captions or text stories with customizable color backgrounds.
  - Full-screen story viewer with segmented progress bars, tap navigation (left to rewind, right to skip), hold to pause, swipe-down to dismiss, viewer list, and story deletion for owners.
- **Social & Discovery**:
  - Global user search by `@username` or phone number.
  - Following & Followers lists with one-tap follow/unfollow.
  - Rich user profiles showing avatar, bio, online status, story integration, and direct chat actions.
- **Offline First**:
  - SQLite local database caching for conversations, messages, and user directory.
  - Instant app open and message reading even with poor or zero connectivity.
- **Customization & Internationalization**:
  - Material 3 design with Light, Dark, and System modes.
  - 4 customizable accent color schemes: **Emerald Green**, **Ocean Blue**, **Royal Violet**, and **Amber Gold**.
  - Customizable chat wallpaper patterns.
  - Full RTL (Arabic default) and LTR (English) localization with instant dynamic switching.

---

## 📡 Backend Connection & Configuration

The app is configured to connect to the Chaty backend VPS:
- **REST Base URL**: `http://185.196.20.220:5050`
- **WebSocket URL**: `ws://185.196.20.220:5050/ws`

### Single-Point Configuration File
All endpoints and URLs are centralized in a single file:
[`lib/core/config/app_config.dart`](file:///home/kali/chaty-project/chaty/lib/core/config/app_config.dart)

To change the backend server address globally, update the constants in `lib/core/config/app_config.dart`:
```dart
static const String defaultBaseUrl = 'http://185.196.20.220:5050';
static const String defaultWsUrl = 'ws://185.196.20.220:5050/ws';
```

Additionally, users can customize or override the server URL dynamically inside the app by navigating to **Settings -> Server Configuration**.

### Cleartext & Transport Security
- **Android**: Cleartext traffic is enabled in `android/app/src/main/AndroidManifest.xml` via `android:usesCleartextTraffic="true"` and configured through `android/app/src/main/res/xml/network_security_config.xml`.
- **iOS**: Configured in `ios/Runner/Info.plist` with `NSAppTransportSecurity` and `NSAllowsArbitraryLoads: true`.

---

## 🔑 CI/CD & Android Release Signing Setup

The application is built automatically via GitHub Actions on every push, pull request, manual workflow dispatch, and version tag (`v*`).

### Keystore Repository Secrets
A dedicated release keystore is used for signing production APKs. The keystore and credentials are stored securely in GitHub Secrets.

To set up the repository secrets on GitHub via the GitHub CLI (`gh`), run:

```bash
# 1. Base64-encode your release keystore and save to secret
gh secret set RELEASE_KEYSTORE_BASE64 -b "$(base64 -w 0 path/to/release.jks)"

# 2. Set the keystore password
gh secret set KEYSTORE_PASSWORD -b "YourKeystorePasswordHere"

# 3. Set the key alias
gh secret set KEY_ALIAS -b "chaty"

# 4. Set the key password
gh secret set KEY_PASSWORD -b "YourKeyPasswordHere"
```

> [!NOTE]
> The Gradle build configuration (`android/app/build.gradle.kts`) automatically checks if the release signing environment variables or properties are provided. If absent, it gracefully falls back to debug signing so that CI builds never fail due to missing secrets.

---

## 📦 Downloading Release APKs

On each CI run, GitHub Actions builds release APKs split per ABI for optimal file size:
- `app-arm64-v8a-release.apk` (modern Android devices)
- `app-armeabi-v7a-release.apk` (32-bit ARM devices)
- `app-x86_64-release.apk` (emulators and x86 devices)

### From GitHub Actions Workflow Artifacts
1. Go to the GitHub repository: [github.com/mkdevofficial/chaty](https://github.com/mkdevofficial/chaty).
2. Click on the **Actions** tab.
3. Select the latest workflow run on the `main` branch.
4. Scroll to the bottom to the **Artifacts** section and download the `release-apks` bundle.

Or via CLI:
```bash
gh run download --name release-apks
```

### From GitHub Releases
When a tag like `v1.0.0` is pushed:
```bash
git tag v1.0.0
git push origin v1.0.0
```
The workflow builds the APKs and creates a GitHub Release with the split APKs attached.

---

## 🧪 Local Verification & Tests

To run the test suite and static analysis locally:

```bash
# Run unit & widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## 🛠️ Architecture & Tech Stack

- **UI Framework**: Flutter 3.38+ / Material Design 3
- **State Management**: `flutter_riverpod: ^2.6.1`
- **Routing**: `go_router: ^14.8.1`
- **Networking**: `dio: ^5.8.0+1` with custom auth & error interceptors
- **Real-Time**: `web_socket_channel: ^3.0.3` with exponential backoff auto-reconnect and foreground resync
- **Local Storage**: `sqflite: ^2.4.2` (SQLite) + `flutter_secure_storage: ^9.2.4`
- **Media & Audio**: `image_picker`, `image_cropper`, `file_picker`, `record: ^5.2.1`, `just_audio: ^0.10.5`
- **Vector Graphics**: `flutter_svg: ^2.1.0`
- **Localization**: Custom native AR/EN dictionary with `AppLocalizations` supporting dynamic language toggle without restarting.

---

## 🔍 Known Server Issues & Client Tolerances

During contract verification against the live VPS deployment (`http://185.196.20.220:5050`), several minor API contract deviations were observed. The Flutter client has been made resilient to handle both the strict contract and live server quirks:

1. **Conversation Peer User Field**:
   - *Contract*: `Conversation` contains `peer` (full User object).
   - *Live Server*: Emits `user` (full User object).
   - *Client Handling*: The client checks `json['peer'] ?? json['user'] ?? json['other_user']`.
2. **Follow / Unfollow Request & Response**:
   - *Contract*: `POST /api/friends/{userId}` and `DELETE /api/friends/{userId}` return the updated `User`.
   - *Live Server*: Returns `{"following": true/false, "user": {...}}`. Additionally, the server rejects requests without a body (`400 VALIDATION_ERROR`).
   - *Client Handling*: The client sends an empty JSON body `{}` and extracts `response['user'] ?? response`.
3. **Stories List**:
   - *Contract*: `GET /api/stories` returns `{ "groups": [...] }`.
   - *Live Server*: Returns a raw JSON array of story groups `[{"user": ..., "stories": [...]}]` directly, with individual stories using `viewer_count` rather than `view_count`.
   - *Client Handling*: The client supports both a raw array and a `{ "groups": [...] }` wrapper, and checks `view_count ?? viewer_count`.
4. **Story Viewers List**:
   - *Contract*: Returns viewers array where each viewer item has `user` and `viewed_at`.
   - *Client Handling*: Checks `item['user'] ?? item['viewer'] ?? item`.
5. **Friends Following & Followers List**:
   - *Contract*: Returns `users` wrapper.
   - *Client Handling*: Supports both raw array and `response['users'] ?? response['following'] ?? response['followers']`.

