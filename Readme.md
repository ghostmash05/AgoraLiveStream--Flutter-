# Agora Live Stream Flutter Module

A Flutter module for integrating Agora live streaming functionality into your Flutter applications. This module provides both broadcaster and audience interfaces for live streaming. Built with **GetX** for state management, but can be easily integrated with any state management solution by modifying the navigation/routing code.

## Features

- Join as a broadcaster to start live streaming
- Join as an audience member to watch live streams
- Real-time audio/video streaming
- Toggle camera and microphone
- Switch between front and back cameras
- Leave the live stream

## Prerequisites

- Flutter SDK (latest stable version)
- Agora Developer Account (for App ID and Token)
- Android Studio / Xcode (for platform-specific setup)
- Physical device or emulator with camera and microphone access

## Installation

**Please replace your Agora App ID in the `controller/live_stream_controller.dart` and `controller/live_watch_controller.dart` files.**

1. Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  agora_rtc_engine: ^6.1.0
  permission_handler: ^10.4.0
  get: ^4.6.5
```

2. Run `flutter pub get`

## Setup

### Android

1. Add the following permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

2. Set `android:hardwareAccelerated="true"` in the `<application>` tag.

### iOS

1. Add the following permissions to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera permission is required for video calls</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone permission is required for audio calls</string>
```

2. Enable background modes in Xcode:
   - Open your project in Xcode
   - Select the Runner target
   - Go to the "Signing & Capabilities" tab
   - Add "Background Modes" and check "Audio, AirPlay, and Picture in Picture"

## Usage

### 1. Import the package

```dart
import 'package:your_package_name/view/live_stream_screen.dart';
import 'package:your_package_name/view/live_watch_screen.dart';
```

### 2. Join as a Broadcaster

To start a live stream as a broadcaster:

```dart
Get.to(
  () => LiveStreamScreen(
    token: 'YOUR_AGORA_TOKEN',
    channelName: 'YOUR_CHANNEL_NAME',
  ),
);
```

### 3. Join as an Audience

To join a live stream as an audience member:

```dart
Get.to(
  () => LiveWatchScreen(
    token: 'YOUR_AGORA_TOKEN',
    channelName: 'YOUR_CHANNEL_NAME',
  ),
  arguments: 'Live Stream Title',
);
```

## Configuration

### LiveStreamScreen Parameters

| Parameter    | Type   | Required | Description                           |
|--------------|--------|----------|---------------------------------------|
| token        | String | Yes      | Agora token for authentication        |
| channelName  | String | Yes      | Name of the channel to join           |

### LiveWatchScreen Parameters

| Parameter    | Type   | Required | Description                           |
|--------------|--------|----------|---------------------------------------|
| token        | String | Yes      | Agora token for authentication        |
| channelName  | String | Yes      | Name of the channel to join           |

## Features Implementation

### For Broadcasters:
- Toggle camera on/off
- Mute/unmute microphone
- Switch between front and back cameras
- End the live stream

### For Audience:
- Watch the live stream
- See the broadcaster's video
- Listen to the audio
- Leave the stream

## Error Handling

The module includes basic error handling for:
- Network connectivity issues
- Camera/microphone permissions
- Invalid tokens or channel names
- Connection timeouts

## Dependencies

- `agora_rtc_engine`: For Agora's real-time communication
- `permission_handler`: For handling runtime permissions
- `get`: For state management and navigation (can be replaced with other state management solutions)

## State Management

This module uses **GetX** for state management and navigation. However, it's designed to be flexible and can be used with any state management solution. The only part that's tightly coupled with GetX is the navigation/routing.

### Using with Other State Management Solutions

If you're using a different state management solution (like Provider, Riverpod, Bloc, etc.), you can still use this module by creating wrapper widgets or modifying the navigation code. Here's how:

1. **For Navigation**: Replace Get.to() with your preferred navigation method

```dart
// Example with Navigator
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LiveStreamScreen(
      token: 'YOUR_AGORA_TOKEN',
      channelName: 'YOUR_CHANNEL_NAME',
    ),
  ),
);

// Example with GoRouter
context.push(
  '/live-stream',
  extra: {
    'token': 'YOUR_AGORA_TOKEN',
    'channelName': 'YOUR_CHANNEL_NAME',
  },
);
```

2. **For State Management**: The controllers (`LiveStreamController` and `LiveWatchController`) are self-contained and don't depend on GetX for state management. You can use them with any state management solution by:
   - Creating an instance of the controller in your preferred state management solution
   - Passing the required parameters to the screens
   - Using the controller methods as needed

## Troubleshooting

1. **Black screen on iOS**
   - Make sure you've added the required permissions in Info.plist
   - Check that you're using a physical device (simulator has camera limitations)

2. **No audio/video**
   - Verify the device's microphone and camera permissions
   - Check your Agora token and channel name
   - Ensure you have a stable internet connection

3. **Connection issues**
   - Verify your Agora App ID and Token
   - Check your network connection
   - Ensure you're using the correct channel name

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please open an issue on the repository.

## Acknowledgments

- [Agora.io](https://www.agora.io/) for the real-time communication platform
