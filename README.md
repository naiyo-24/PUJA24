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
PUJA24/
├── lib
│   ├── core
│   │   ├── network
│   │   │   ├── api_config.dart
│   │   │   ├── graphql_service.dart
│   │   │   └── route_service.dart
│   │   ├── services
│   │   │   ├── ad_service.dart
│   │   │   ├── background_location_service.dart
│   │   │   ├── places_api_service.dart
│   │   │   └── rewards_api_service.dart
│   │   ├── theme
│   │   │   ├── app_colors.dart
│   │   │   ├── app_theme.dart
│   │   │   └── app_typography.dart
│   │   ├── utils
│   │   │   └── permission_helper.dart
│   │   └── widgets
│   │       ├── app_button.dart
│   │       ├── app_card.dart
│   │       ├── app_chip.dart
│   │       ├── app_loader.dart
│   │       ├── app_text_field.dart
│   │       ├── banner_ad_widget.dart
│   │       ├── native_ad_widget.dart
│   │       ├── network_image.dart
│   │       └── skeleton_loader.dart
│   ├── features
│   │   ├── advertisement
│   │   │   └── presentation
│   │   │       └── advertisement_details_screen.dart
│   │   ├── auth
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── auth_provider.dart
│   │   │       ├── login_screen.dart
│   │   │       ├── map_picker_screen.dart
│   │   │       ├── otp_screen.dart
│   │   │       ├── profile_creation_screen.dart
│   │   │       └── splash_screen.dart
│   │   ├── food
│   │   │   ├── data
│   │   │   │   └── repositories
│   │   │   │       └── food_repository.dart
│   │   │   ├── domain
│   │   │   │   └── models
│   │   │   │       └── restaurant_model.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── food_provider.dart
│   │   │       ├── cafe_directory_screen.dart
│   │   │       └── restaurant_detail_screen.dart
│   │   ├── groups
│   │   │   ├── data
│   │   │   │   ├── group_websocket_service.dart
│   │   │   │   └── groups_api_service.dart
│   │   │   └── presentation
│   │   │       ├── widgets
│   │   │       │   └── itinerary_selection_sheet.dart
│   │   │       ├── create_group_screen.dart
│   │   │       ├── group_details_screen.dart
│   │   │       ├── group_info_screen.dart
│   │   │       ├── group_live_map_screen.dart
│   │   │       ├── groups_dashboard_screen.dart
│   │   │       └── join_group_screen.dart
│   │   ├── home
│   │   │   ├── data
│   │   │   │   ├── repositories
│   │   │   │   │   └── home_repository.dart
│   │   │   │   └── pass_repository.dart
│   │   │   ├── domain
│   │   │   │   └── models
│   │   │   │       ├── banner_model.dart
│   │   │   │       ├── pass_package_model.dart
│   │   │   │       └── user_voucher_model.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   ├── home_provider.dart
│   │   │       │   └── pass_provider.dart
│   │   │       ├── widgets
│   │   │       │   └── hero_banner_carousel.dart
│   │   │       ├── home_screen.dart
│   │   │       ├── pass_purchase_form_screen.dart
│   │   │       ├── payment_success_screen.dart
│   │   │       └── puja_pass_details_screen.dart
│   │   ├── pandals
│   │   │   ├── data
│   │   │   │   └── repositories
│   │   │   │       └── puja_repository.dart
│   │   │   ├── domain
│   │   │   │   └── models
│   │   │   │       └── puja_detail_model.dart
│   │   │   ├── presentation
│   │   │   │   ├── providers
│   │   │   │   │   ├── plan_pandal_provider.dart
│   │   │   │   │   ├── puja_detail_provider.dart
│   │   │   │   │   ├── puja_list_provider.dart
│   │   │   │   │   └── save_pandal_provider.dart
│   │   │   │   ├── widgets
│   │   │   │   │   ├── live_update_bottom_sheet.dart
│   │   │   │   │   ├── pandal_card_skeleton.dart
│   │   │   │   │   ├── puja_basic_info.dart
│   │   │   │   │   ├── puja_detail_skeleton.dart
│   │   │   │   │   ├── puja_facilities.dart
│   │   │   │   │   ├── puja_live_status.dart
│   │   │   │   │   ├── puja_nearby_places.dart
│   │   │   │   │   ├── puja_theme_section.dart
│   │   │   │   │   └── puja_transit.dart
│   │   │   │   ├── puja_detail_screen.dart
│   │   │   │   ├── puja_directory_screen.dart
│   │   │   │   └── puja_map_screen.dart
│   │   │   └── providers
│   │   │       └── pandals_list_provider.dart
│   │   ├── planner
│   │   │   ├── domain
│   │   │   │   └── models
│   │   │   │       └── plan_item_model.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── planner_provider.dart
│   │   │       └── planner_screen.dart
│   │   ├── profile
│   │   │   └── presentation
│   │   │       ├── widgets
│   │   │       │   └── map_location_picker.dart
│   │   │       ├── about_us_screen.dart
│   │   │       ├── my_passes_screen.dart
│   │   │       ├── privacy_policy_screen.dart
│   │   │       ├── profile_screen.dart
│   │   │       └── terms_of_service_screen.dart
│   │   ├── rewards
│   │   │   └── presentation
│   │   │       └── rewards_screen.dart
│   │   ├── saved
│   │   │   ├── domain
│   │   │   │   └── models
│   │   │   │       └── saved_item_model.dart
│   │   │   └── presentation
│   │   │       ├── providers
│   │   │       │   └── saved_provider.dart
│   │   │       └── saved_screen.dart
│   │   └── transport
│   │       ├── domain
│   │       │   └── metro_data.dart
│   │       └── presentation
│   │           ├── metro_guide_screen.dart
│   │           ├── metro_live_map_screen.dart
│   │           └── parking_map_screen.dart
│   ├── routes
│   │   ├── app_router.dart
│   │   └── route_names.dart
│   ├── shell
│   │   ├── widgets
│   │   │   └── liquid_nav_bar.dart
│   │   └── app_shell.dart
│   └── main.dart
├── .env
├── .gitignore
├── README.md
├── pubspec.lock
└── pubspec.yaml
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
