# Hotspot Tic Tac Toe

Offline 3x3 Tic Tac Toe for two Android phones using Flutter and TCP sockets over a WiFi hotspot. No external backend and no internet dependency for gameplay.

## Table of Contents

1. Problem Statement
2. Start From Scratch
3. Developer Mode
4. Project Overview
5. How the App Works
6. Functions and Their Uses
7. How to Play
8. How IP Address Is Taken
9. How the Two Devices Connect
10. Frontend Working
11. Backend Working
12. Flutter Commands and Uses
13. File and Folder Arrangement
14. Extensions Used
15. How to Run
16. Interview Talking Points
17. Share on LinkedIn
18. Download and Install (For Users)

## Problem Statement

Build a real-time 3x3 Tic Tac Toe game for two physical Android devices connected through a local WiFi hotspot. One device acts as the host and the other joins using the host IP address. The game must work offline, use TCP sockets, send only moves, maintain turn order, persist scores, handle disconnects, and provide a polished mobile UI.

## Start From Scratch

If you are starting on a new machine, follow this order.

### 1. Install Flutter

1. Download Flutter stable from flutter.dev.
2. Extract Flutter to a simple path like `C:\src\flutter`.
3. Add `flutter\bin` to your user PATH.
4. Open PowerShell and run:

```powershell
flutter --version
```

### 2. Install Android Studio and SDK

1. Install Android Studio.
2. Open SDK Manager.
3. Install these components:
	1. Android SDK Platform
	2. Android SDK Platform-Tools
	3. Android SDK Build-Tools
4. Accept all SDK licenses.

### 3. Verify Flutter setup

Run:

```powershell
flutter doctor
```

Fix every red item before building.

### 4. Open the project

Open this folder in VS Code or Android Studio:

```text
C:\Users\rajku\OneDrive\Desktop\Tic-Tac-Toe
```

Then run:

```powershell
flutter pub get
```

## Developer Mode

Developer mode is needed on both Android phones so they can be connected, debugged, and installed from the PC.

### On each phone

1. Open Settings.
2. Go to About phone.
3. Tap Build number 7 times.
4. Enter the PIN if asked.
5. Open Developer options.
6. Turn on USB debugging.
7. If needed, also enable Install via USB.

### Why it matters

1. It allows APK installation from your computer.
2. It allows adb communication during development.
3. It helps when testing on real devices.

## Project Overview

This app has no cloud backend. The host phone becomes the local game server and the join phone becomes the client. The board lives on each phone locally and stays synchronized only through move messages.

### Core rules

1. Board size is 3x3.
2. Host is `X`.
3. Client is `O`.
4. Host starts first.
5. Only moves are sent over the socket.
6. Board state is never sent in full.
7. Scores are saved per opponent IP.

## How the App Works

### Flow

1. Home screen shows `Host Game` and `Join Game`.
2. Host starts a server socket on port `4040`.
3. Host device displays its local WiFi IP.
4. Join device enters that IP and connects.
5. Both devices open the game screen after connection.
6. Each tap is validated locally before it is sent.
7. The receiving side updates its board from the move message.

### Protocol

All messages are UTF-8 text and newline separated.

1. `MOVE:<index>` for a move from 0 to 8.
2. `RESET` to restart a round.
3. `DISCONNECT` to notify peer exit.

### Turn control

1. `isMyTurn` controls input.
2. If it is not your turn, taps are ignored.
3. After a local move, the turn changes to the other player.
4. After a remote move, the turn comes back to you.

## Functions and Their Uses

These are the important app functions and what they do in a few words.

| Function | Use |
| --- | --- |
| `main()` | Starts the Flutter app |
| `TicTacToeApp` | Builds global app theme |
| `_hostGame()` | Starts the local server |
| `_joinGame()` | Connects to host IP |
| `_showSnackBar()` | Shows error or status message |
| `_handleTap()` | Sends local move safely |
| `_handleNetworkMessage()` | Processes incoming socket messages |
| `_handleRemoteMove()` | Applies opponent move locally |
| `_resetRound()` | Restarts current round |
| `_leaveGame()` | Disconnects cleanly |
| `getLocalIpAddress()` | Reads hotspot IP address |
| `startServer()` | Binds server socket on 4040 |
| `connectToServer()` | Opens client socket connection |
| `listenToMessages()` | Listens for UTF-8 messages |
| `sendMessage()` | Sends protocol text |
| `shutdown()` | Closes socket and server |
| `placeMove()` | Writes symbol to board |
| `detectWinner()` | Checks all win patterns |
| `resetRound()` | Clears board state |

## How to Play

### Host phone

1. Open the app.
2. Tap `Host Game`.
3. Wait until the local IP appears.
4. Share the IP with the other player.
5. Wait for the client to connect.

### Join phone

1. Connect to the host hotspot.
2. Open the app.
3. Tap `Join Game`.
4. Enter the host IP.
5. Connect and wait for the game screen.

### Game rules

1. Host plays as `X`.
2. Joiner plays as `O`.
3. Host moves first.
4. Tap only on your turn.
5. First to make three in a row wins.
6. Full board with no winner is a draw.
7. Reset starts a new round.

## How IP Address Is Taken

The host IP is read from the device network interfaces in `SocketService.getLocalIpAddress()`.

### Implementation idea

1. The app calls `NetworkInterface.list(...)`.
2. It filters for IPv4 addresses.
3. It ignores loopback and link-local addresses.
4. It takes the first valid non-loopback IPv4 address.
5. That IP is shown to the host player.

### Why this works

The hotspot creates a local network. The host phone gets an IP on that network, and the join phone uses that IP to connect directly over WiFi.

## How the Two Devices Connect

### Host side

1. `ServerSocket.bind(InternetAddress.anyIPv4, 4040)` opens a local server.
2. The app waits for one incoming client.
3. When a socket connects, the game screen opens.

### Join side

1. The user enters the host IP.
2. `Socket.connect(hostIp, 4040)` opens the client socket.
3. On success, the game screen opens.

### After connection

1. Both sides use the same socket protocol.
2. Each message is decoded as UTF-8.
3. Only moves, reset, and disconnect messages are exchanged.
4. The board remains synchronized because each move is applied in the same order on both devices.

## Frontend Working

The frontend is built with Flutter Material widgets and a dark neon visual style.

### Home screen

1. Shows host and join actions.
2. Provides IP input field.
3. Displays friendly connection feedback through SnackBar.

### Game screen

1. Shows current symbol for the player.
2. Shows turn status text.
3. Shows scoreboard for both players.
4. Shows glowing 3x3 grid.
5. Animates tapped cells with scale and glow.
6. Provides reset and disconnect buttons.

### UI style choices

1. Dark background with `#0D0D0D` tone.
2. Neon blue, purple, and pink accents.
3. Rounded cards and buttons.
4. Soft shadows for depth.
5. Responsive layout for different screen sizes.

## Backend Working

The backend in this app is the local socket layer inside the host and client devices. There is no server on the internet.

### What the backend does

1. Starts and manages the TCP socket connection.
2. Sends protocol messages.
3. Receives and parses move messages.
4. Handles disconnects and errors.
5. Keeps the game flow in sync.

### Why `dart:io` is used

`ServerSocket` and `Socket` come from `dart:io`, which is the correct low-level API for direct TCP communication on Android.

### Score persistence

1. `SharedPreferences` stores score locally.
2. Score key format is `score_<ip>`.
3. Scores are loaded when the game starts.
4. Score increments only when the local player wins.

## Flutter Commands and Their Uses

| Command | Use |
| --- | --- |
| `flutter doctor` | Checks Flutter setup |
| `flutter pub get` | Downloads packages |
| `flutter run` | Runs app on device |
| `flutter run -d <id>` | Runs on selected device |
| `flutter clean` | Clears build cache |
| `flutter build apk` | Builds installable APK |
| `flutter build apk --release` | Builds release APK |
| `flutter test` | Runs widget tests |
| `flutter analyze` | Checks code quality |
| `flutter devices` | Lists connected devices |

## File and Folder Arrangement

### Source files

| Path | Meaning |
| --- | --- |
| `lib/main.dart` | App entry point and theme |
| `lib/screens/home_screen.dart` | Host and join UI |
| `lib/screens/game_screen.dart` | Gameplay UI and logic |
| `lib/services/socket_service.dart` | TCP socket singleton |
| `lib/models/game_state.dart` | Board and win state |
| `lib/utils/constants.dart` | App constants and colors |
| `test/widget_test.dart` | Basic widget smoke test |

### Android files

| Path | Meaning |
| --- | --- |
| `android/app/src/main/AndroidManifest.xml` | Release manifest and permissions |
| `android/app/src/debug/AndroidManifest.xml` | Debug permission config |
| `android/app/src/profile/AndroidManifest.xml` | Profile permission config |
| `android/app/build.gradle.kts` | Android build config |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle version wrapper |

### Project and tool files

| Path | Meaning |
| --- | --- |
| `pubspec.yaml` | Dependencies and app metadata |
| `pubspec.lock` | Locked package versions |
| `analysis_options.yaml` | Lint rules |
| `.dart_tool/` | Generated Dart tool cache |
| `.idea/` | Android Studio settings |
| `build/` | Generated build output |
| `tic_tac_toe_hotspot.iml` | IntelliJ project file |
| `README.md` | Project documentation |

### Generated or non-core files

| Path | Meaning |
| --- | --- |
| `build/` | Auto-generated build artifacts |
| `.dart_tool/` | Auto-generated package metadata |
| `Lab.py` | Extra workspace file, not used by app |

## Extensions Used

Recommended VS Code extensions for this project:

1. Flutter
2. Dart

Useful Android Studio support is also provided by the Flutter plugin and Android SDK tools.

## How to Run

### From scratch on your PC

1. Install Flutter stable.
2. Install Android Studio and SDK.
3. Enable Developer mode and USB debugging on both phones.
4. Connect one phone to the PC with USB if you want to test directly.
5. Run:

```powershell
flutter doctor
flutter pub get
flutter devices
```

### Run on a phone

```powershell
flutter run -d <deviceId>
```

Example:

```powershell
flutter run -d 10BEA70AYS003DF
```

### Build APK and install manually

```powershell
flutter build apk --release
```

APK path:

```text
build/app/outputs/flutter-apk/app-release.apk
```

You can send this APK to both phones and install it manually.

## Share on LinkedIn

Use this checklist so people can understand the project quickly and download it.

1. Upload your code to GitHub.
2. Keep this repository `README.md` as your project page.
3. Keep the installable APK in `APK/Hotspot-TicTacToe-v1.0.0.apk`.
4. Add a 20 to 40 second demo video in your LinkedIn post.
5. Add these links in your post:
	1. GitHub repository link
	2. Direct APK link (GitHub Release asset preferred)

### LinkedIn post template

```text
Built an offline multiplayer Tic Tac Toe app using Flutter and TCP sockets over hotspot.

Highlights:
- Works without internet or backend
- Real-time gameplay across two Android phones
- Host/client architecture with direct socket communication
- Score persistence using SharedPreferences

Try it:
- Source Code: <your-github-repo-link>
- Download APK: <your-apk-download-link>

Feedback is welcome.
#flutter #dart #android #networking #mobileappdevelopment #project
```

## Download and Install (For Users)

If you are sharing this project publicly, these are the exact steps for any user.

### Option A: Download from GitHub (recommended)

1. Open your repository link.
2. Go to `APK/Hotspot-TicTacToe-v1.0.0.apk` and download it.
3. Send the APK to your Android phone if downloaded on PC.

### Option B: Download from a GitHub Release (best UX)

1. In GitHub, open `Releases` and create a new release (example tag `v1.0.0`).
2. Upload `APK/Hotspot-TicTacToe-v1.0.0.apk` as a release asset.
3. Share the release URL in LinkedIn for one-click APK download.

### Install on Android phone

1. Open the downloaded APK on the phone.
2. If prompted, enable `Install unknown apps` for the app you used to open the APK.
3. Tap `Install`.
4. Open the app and allow local network access if Android asks.

### Play with two users

1. Both phones must be on the same hotspot.
2. One user taps `Host Game` and shares the shown IP.
3. Other user taps `Join Game` and enters that IP.
4. Game starts after successful connection.

## Interview Talking Points

If an interviewer asks about the project, these are the important points to explain.

1. The game works offline over a hotspot.
2. The host acts as the local TCP server.
3. The joiner connects using the host IP.
4. Only move messages are transmitted.
5. The board stays synchronized locally on both phones.
6. Turn management prevents double moves.
7. `SharedPreferences` stores scores per opponent.
8. Socket disconnects are handled cleanly.
9. The UI is responsive and polished.
10. The architecture is small, readable, and production focused.

## Notes

1. The app needs Android network permission for socket communication.
2. The host and join phone must be on the same hotspot network.
3. The host IP must be entered correctly on the join device.
4. If the connection drops, start a fresh host and reconnect.

## Quick Summary

1. Host phone starts the server.
2. Join phone connects using IP.
3. Moves are sent as short text messages.
4. UI updates locally after each valid move.
5. Scores persist by opponent IP.
