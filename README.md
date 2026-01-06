# roku-ssdp

Flutter app for discovering and controlling Roku and Google TV devices on your local network.

![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)

## Requirements

- Flutter SDK 3.9.2 or higher
- Dart 3.9.2 or higher
- Android device (minimum SDK 21)
- Devices must be on the same local network

## How It Works

The app uses native Android platform channels to discover devices on your network:

- **Roku Discovery**: Uses SSDP (Simple Service Discovery Protocol) via UDP multicast to discover Roku devices. The app sends M-SEARCH requests to the standard SSDP multicast address (239.255.255.250:1900) and parses the responses to extract device IP addresses.

- **Google TV Discovery**: Uses Android's NSD Manager to discover Google TV and Chromecast devices via mDNS. The app searches for `_googlecast._tcp` services and resolves them to get device information.

- **Roku Control**: Once a Roku device is discovered, the app uses Roku's ECP (External Control Protocol) to send commands. This is a simple HTTP-based API where POST requests are sent to `http://<ROKU_IP>:8060/keypress/<KEY>` endpoints.

- **Google TV Control**: Attempts to use Google Cast SDK and HTTP methods, though full control requires an active Cast session which isn't automatically established.

The app follows a clean architecture pattern with separate data, domain, and presentation layers. State management is handled using Provider, and the UI is built with responsive design using flutter_screenutil.

## How to Use

### Discovering Devices

1. Open the app and tap the "Discover Roku Devices" or "Discover Google TV Devices" button
2. Wait a few seconds while the app searches your network
3. Select a device from the dropdown menu that appears

### Controlling Roku Devices

1. After selecting a Roku device, tap "Open Remote Control"
2. Use the directional buttons (Up, Down, Left, Right) to navigate
3. Commands are sent directly to your Roku device over the network

### Google TV Devices

Google TV control has limitations. The app will attempt to control your device, but full functionality requires a Google Cast SDK connection. For reliable Google TV control, consider using the official Google Home app.

### Test Mode

Enable test mode from the toggle in the header to test the app without physical devices. You can add mock devices and simulate control commands.

## Building

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── data/
│   ├── models/          # Device models
│   └── services/        # Discovery and control services
├── presentation/
│   ├── controllers/     # Provider controllers
│   └── view/
│       ├── screens/     # UI screens
│       └── widgets/    # Reusable widgets
└── main.dart           # App entry point

android/
└── app/src/main/kotlin/
    └── MainActivity.kt  # Native platform channels
```

## Dependencies

- `provider`: State management
- `shimmer`: Loading animations
- `http`: HTTP requests for Roku ECP
- `flutter_screenutil`: Responsive UI sizing
- `google_fonts`: Custom typography
- `page_transition`: Navigation animations

## Contributing

Contributions are welcome. Feel free to open issues or submit pull requests. When contributing, please:

- Follow the existing code style
- Add comments for complex logic
- Test your changes on both Roku and Google TV devices if possible
- Update documentation as needed

## Limitations

- Google TV control requires Google Cast SDK connection which must be established manually
- Some Google TV devices may not support HTTP remote control at all
- Roku devices work reliably via ECP protocol
- All devices must be on the same local network

## License

This project is open source and available for personal and educational use.

---

Made with Flutter and 💙
