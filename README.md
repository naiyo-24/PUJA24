# Durga Puja Explorer 🌺

A comprehensive Flutter application designed to enhance the Durga Puja experience. This app serves as your ultimate guide for pandal hopping, discovering local food, planning itineraries, and connecting with groups during the festival.

## ✨ Features

- **Auth & Profiles**: Secure authentication using Firebase & Google Sign-In with personalized user profiles.
- **Pandal Discovery**: Explore and locate Durga Puja pandals using Google Maps.
- **Group Planning**: Create or join groups for coordinated pandal hopping.
- **Planner & Saved**: Save your favorite pandals and plan your daily itineraries.
- **Food & Transport**: Discover nearby food stalls and navigate transportation options.
- **Rewards**: Earn and track rewards through app interactions.
- **Real-time Updates**: Powered by WebSockets for live features and notifications.

## 🛠 Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK: ^3.12.2)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod`)
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)
- **Networking**: [Dio](https://pub.dev/packages/dio) & WebSockets
- **Backend/Services**: Firebase (Auth, Core) & Google Maps
- **UI & Animations**: `flutter_animate`, `google_nav_bar`, `curved_navigation_bar`, `shimmer`

## 📁 Project Structure

The project follows a feature-driven architecture for scalability and maintainability:

```text
lib/
├── core/                  # Core utilities, constants, themes, and shared widgets
├── features/              # Feature modules
│   ├── advertisement/     # Ad integrations and banners
│   ├── auth/              # Authentication flows and state
│   ├── food/              # Food stall discovery and reviews
│   ├── groups/            # Group creation and management
│   ├── home/              # Main dashboard and feeds
│   ├── pandals/           # Pandal listings, details, and maps
│   ├── planner/           # Itinerary planning tools
│   ├── profile/           # User profile and settings
│   ├── rewards/           # Gamification and rewards system
│   ├── saved/             # Saved pandals and bookmarks
│   └── transport/         # Navigation and transport assistance
├── routes/                # GoRouter configuration and route definitions
├── shell/                 # App shell, main layout, and navigation bars
└── main.dart              # Application entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>= 3.12.2)
- Dart SDK
- Android Studio / VS Code
- A valid Firebase project configuration
- Google Maps API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd PUJA24
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Environment Setup**
   Create a `.env` file in the root directory and add your API keys and configuration variables:
   ```env
   # Add required environment variables here
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📦 Key Dependencies

- `flutter_riverpod`: ^2.6.1 - Reactive state management
- `go_router`: ^17.5.0 - Declarative routing
- `dio`: ^5.11.0 - HTTP client
- `firebase_auth` & `google_sign_in` - Authentication
- `google_maps_flutter` & `geolocator` - Maps and location services
- `razorpay_flutter` - Payment gateway integration

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
