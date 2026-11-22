# Bus Tracker

A Flutter-based mobile application that simulates real-time bus tracking with live map visualization, route planning, ETA calculation, and crowd level prediction using the K-Nearest Neighbors (KNN) algorithm.

## Features

- 🔐 OTP-based phone authentication
- 🗺️ Live map with real-time location tracking
- 🚌 Simulated bus tracking with smooth animation
- ⏱️ Live ETA, distance & crowd level prediction
- 🧠 Crowd level prediction using KNN algorithm

## Tech Stack

- **Frontend:** Flutter
- **State Management:** Flutter Bloc / Cubit
- **Architecture:** Clean Architecture
- **Backend & Authentication:** Supabase
- **Maps:** flutter_map + OpenStreetMap / Carto tiles
- **Geocoding:** Nominatim
- **Routing:** OpenRouteService
- **Machine Learning:** K-Nearest Neighbors (KNN)

## Development Model

The project was developed using the **Incremental Development Model**, with functionality delivered through successive design, implementation, and testing cycles.

## App Screenshots

### Authentication

| Phone number sign-in | OTP verification |
| --- | --- |
| <img src="assets/screenshots/phone-authentication.png" width="230" alt="Phone authentication screen with a phone number field and Send OTP button"> | <img src="assets/screenshots/otp-verification.png" width="230" alt="OTP verification screen with a code field and confirmation button"> |

### Find available buses

| Map and destination search | Available buses for the selected destination |
| --- | --- |
| <img src="assets/screenshots/map-destination-entry.png" width="230" alt="Map screen with destination search and current location"> | <img src="assets/screenshots/available-buses.png" width="230" alt="Available bus types and crowd levels for the selected destination"> |

### Live bus tracking

<p align="center">
  <img src="assets/screenshots/live-bus-tracking.png" width="260" alt="Live bus route map with ETA, distance, and crowd level">
</p>
