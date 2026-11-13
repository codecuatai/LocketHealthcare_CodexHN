# VitaSnap

A local Flutter 3 / Material 3 nutrition demo with Provider state management. No API key, backend, or network connection is needed at runtime.

## Run

```sh
flutter pub get
flutter run
```

Choose either one-tap demo profile on the login screen. The email and password form is a local UI simulation: any valid email and nonempty password open a generic profile. Credentials are never stored or sent.

## Demo flow

1. Enter as User A or User B.
2. Tap the white shutter to view a mock nutrition result.
3. Tap **Lưu & Chia sẻ lên Feed** to add the phở card to the local feed.
4. Use the bottom tabs for the feed and dashboard. Tap the user pill on the camera screen to switch profiles or sign out.

Food photos, nutrition numbers, activity calories, and coach suggestions are bundled mock content. The camera viewfinder does not access the device camera. Shared posts exist in memory for the current session.

## Verify

```sh
flutter analyze
flutter test
```
