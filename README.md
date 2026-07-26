# Sajilo Yatra — Smart Bus Tracker

Sajilo Yatra is a Flutter mobile application for planning local bus journeys in Kathmandu. It combines destination search, current-location routing, simulated live bus movement, and crowd-level prediction to make public transport information easier to understand.

## Key features

- Phone-number authentication using Supabase OTP
- Current-location permission handling and live location updates
- Destination search with OpenStreetMap Nominatim
- Road-route generation through OSRM
- Simulated live bus tracking with ETA and distance updates
- Crowd-level prediction using a k-nearest-neighbours model and historical CSV data
- Responsive Material 3 interface with clear tracking controls

## Architecture

The project follows a feature-first clean architecture:

```text
presentation (Bloc/Cubit + screens) → domain (entities + repositories) → data (API/asset data sources)
```

## Run locally

1. Install Flutter SDK 3.11 or later.
2. Create `.env` with the Supabase credentials required by the project.
3. Run `flutter pub get`.
4. Connect an Android/iOS device or emulator and run `flutter run`.

Android location and internet permissions are included in the manifest. For the best demo, allow precise location when prompted and search for a Kathmandu destination such as `Pashupatinath` or `Thamel`.
