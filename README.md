<div align="center">
  <img src="assets/logo.png" alt="PUJO24 Logo" width="200"/>
  <br/>
  <img src="assets/icons/icon_ios.png" alt="PUJO24 Icon" width="100"/>
</div>

# PUJO24

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
├── lib                                    # Main source code directory
│   ├── core                               # Core application utilities and shared resources
│   │   ├── network                        # Network configuration and services
│   │   │   ├── api_config.dart            # API endpoints and configuration settings
│   │   │   ├── graphql_service.dart       # GraphQL client and query executions
│   │   │   └── route_service.dart         # Service handling map routing and directions
│   │   ├── services                       # Global services used throughout the application
│   │   │   ├── ad_service.dart            # Service for managing and displaying advertisements
│   │   │   ├── background_location_service.dart # Handles device location tracking in the background
│   │   │   ├── places_api_service.dart    # Integration with Google Places API
│   │   │   └── rewards_api_service.dart   # Service for the gamification and rewards system
│   │   ├── theme                          # Application theme and styling definitions
│   │   │   ├── app_colors.dart            # Centralized color palette
│   │   │   ├── app_theme.dart             # Global theme configuration (light and dark mode)
│   │   │   └── app_typography.dart        # Defined text styles and fonts
│   │   ├── utils                          # Helper functions and utilities
│   │   │   └── permission_helper.dart     # Helper to manage device permissions (location, camera, etc.)
│   │   └── widgets                        # Reusable, shared UI components
│   │       ├── app_button.dart            # Custom styled button widget
│   │       ├── app_card.dart              # Custom styled card widget for content display
│   │       ├── app_chip.dart              # Custom chip widget for tags/categories
│   │       ├── app_loader.dart            # Loading indicator widget
│   │       ├── app_text_field.dart        # Custom styled text input field
│   │       ├── banner_ad_widget.dart      # Widget to display banner ads
│   │       ├── native_ad_widget.dart      # Widget to display native ads
│   │       ├── network_image.dart         # Caching wrapper for network images
│   │       └── skeleton_loader.dart       # Shimmering skeleton loader for placeholders
│   ├── features                           # Feature-based modular architecture
│   │   ├── advertisement                  # Advertisement feature module
│   │   │   └── presentation               # UI layer for advertisements
│   │   │       └── advertisement_details_screen.dart # Screen showing detailed ad information
│   │   ├── auth                           # Authentication module
│   │   │   └── presentation               # UI and state for authentication flows
│   │   │       ├── providers              # Riverpod state providers for auth
│   │   │       │   └── auth_provider.dart # Manages authentication state and logic
│   │   │       ├── login_screen.dart      # User login and sign-up interface
│   │   │       ├── map_picker_screen.dart # Screen to pick a default location during sign-up
│   │   │       ├── otp_screen.dart        # OTP verification screen for phone login
│   │   │       ├── profile_creation_screen.dart # Screen for setting up a new user profile
│   │   │       └── splash_screen.dart     # Initial splash screen shown on app launch
│   │   ├── food                           # Food and restaurant discovery module
│   │   │   ├── data                       # Data layer for the food feature
│   │   │   │   └── repositories           # Repositories for fetching food data
│   │   │   │       └── food_repository.dart # API calls for restaurants and food stalls
│   │   │   ├── domain                     # Domain models for the food feature
│   │   │   │   └── models                 
│   │   │   │       └── restaurant_model.dart # Data model representing a restaurant
│   │   │   └── presentation               # UI layer for food discovery
│   │   │       ├── providers              # Riverpod providers for food
│   │   │       │   └── food_provider.dart # Manages food-related state
│   │   │       ├── cafe_directory_screen.dart # Screen listing nearby cafes and restaurants
│   │   │       └── restaurant_detail_screen.dart # Detailed view of a specific restaurant
│   │   ├── groups                         # Group planning and coordination module
│   │   │   ├── data                       # Data layer for groups
│   │   │   │   ├── group_websocket_service.dart # WebSocket integration for live group updates
│   │   │   │   └── groups_api_service.dart # API calls for group management
│   │   │   └── presentation               # UI layer for groups
│   │   │       ├── widgets                
│   │   │       │   └── itinerary_selection_sheet.dart # Bottom sheet to select group itineraries
│   │   │       ├── create_group_screen.dart # Form screen to create a new group
│   │   │       ├── group_details_screen.dart # Main screen for a specific group
│   │   │       ├── group_info_screen.dart # Information and settings for a group
│   │   │       ├── group_live_map_screen.dart # Real-time map tracking group members
│   │   │       ├── groups_dashboard_screen.dart # Dashboard listing all user groups
│   │   │       └── join_group_screen.dart # Screen to join an existing group via code or link
│   │   ├── home                           # Main home screen and feeds module
│   │   │   ├── data                       # Data layer for home feed
│   │   │   │   ├── repositories           
│   │   │   │   │   └── home_repository.dart # API calls for the home feed
│   │   │   │   └── pass_repository.dart   # API calls for purchasing VIP passes
│   │   │   ├── domain                     # Domain models for home
│   │   │   │   └── models                 
│   │   │   │       ├── banner_model.dart  # Data model for home promotional banners
│   │   │   │       ├── pass_package_model.dart # Data model for VIP puja passes
│   │   │   │       └── user_voucher_model.dart # Data model for user discounts/vouchers
│   │   │   └── presentation               # UI layer for home
│   │   │       ├── providers              # Riverpod providers for home
│   │   │       │   ├── home_provider.dart # Manages home screen state
│   │   │       │   └── pass_provider.dart # Manages state for purchasing passes
│   │   │       ├── widgets                
│   │   │       │   └── hero_banner_carousel.dart # Image carousel widget for home banners
│   │   │       ├── home_screen.dart       # The main home dashboard screen
│   │   │       ├── pass_purchase_form_screen.dart # Form screen to buy a VIP pass
│   │   │       ├── payment_success_screen.dart # Success screen displayed after payment
│   │   │       └── puja_pass_details_screen.dart # Details screen for a purchased pass
│   │   ├── pandals                        # Durga Puja pandal directory module
│   │   │   ├── data                       # Data layer for pandals
│   │   │   │   └── repositories           
│   │   │   │       └── puja_repository.dart # API calls fetching pandal information
│   │   │   ├── domain                     # Domain models for pandals
│   │   │   │   └── models                 
│   │   │   │       └── puja_detail_model.dart # Data model representing a single pandal
│   │   │   ├── presentation               # UI layer for pandals
│   │   │   │   ├── providers              # Riverpod providers for pandals
│   │   │   │   │   ├── plan_pandal_provider.dart # Manages state for adding pandals to planner
│   │   │   │   │   ├── puja_detail_provider.dart # State for a single pandal's detailed view
│   │   │   │   │   ├── puja_list_provider.dart # State for the general list of pandals
│   │   │   │   │   └── save_pandal_provider.dart # State for saving favorite pandals
│   │   │   │   ├── widgets                
│   │   │   │   │   ├── live_update_bottom_sheet.dart # Bottom sheet for real-time status updates
│   │   │   │   │   ├── pandal_card_skeleton.dart # Skeleton loader for a pandal card
│   │   │   │   │   ├── puja_basic_info.dart # UI component showing basic pandal info (name, location)
│   │   │   │   │   ├── puja_detail_skeleton.dart # Skeleton loader for the pandal details screen
│   │   │   │   │   ├── puja_facilities.dart # UI component listing nearby facilities (washrooms, food)
│   │   │   │   │   ├── puja_live_status.dart # UI component showing live crowd status
│   │   │   │   │   ├── puja_nearby_places.dart # UI component listing nearby attractions
│   │   │   │   │   ├── puja_theme_section.dart # UI component describing the pandal's theme
│   │   │   │   │   └── puja_transit.dart  # UI component showing transit options to the pandal
│   │   │   │   ├── puja_detail_screen.dart # Full detailed screen of a specific pandal
│   │   │   │   ├── puja_directory_screen.dart # Screen listing all available pandals
│   │   │   │   └── puja_map_screen.dart   # Map view displaying all pandal locations
│   │   │   └── providers                  
│   │   │       └── pandals_list_provider.dart # General provider managing the list of pandals
│   │   ├── planner                        # Itinerary planning module
│   │   │   ├── domain                     
│   │   │   │   └── models                 
│   │   │   │       └── plan_item_model.dart # Data model for an item in the user's itinerary
│   │   │   └── presentation               # UI layer for the planner
│   │   │       ├── providers              
│   │   │       │   └── planner_provider.dart # Manages state for the user's daily itinerary
│   │   │       └── planner_screen.dart    # Screen displaying the planned pandal hopping route
│   │   ├── profile                        # User profile module
│   │   │   └── presentation               # UI layer for user profile
│   │   │       ├── widgets                
│   │   │       │   └── map_location_picker.dart # Reusable widget to pick a location on a map
│   │   │       ├── about_us_screen.dart   # Information screen about the application and team
│   │   │       ├── my_passes_screen.dart  # Screen displaying the user's purchased VIP passes
│   │   │       ├── privacy_policy_screen.dart # Screen displaying the app's privacy policy
│   │   │       ├── profile_screen.dart    # Main user profile and settings screen
│   │   │       └── terms_of_service_screen.dart # Screen displaying the terms of service
│   │   ├── rewards                        # Rewards and gamification module
│   │   │   └── presentation               
│   │   │       └── rewards_screen.dart    # Screen showing user's earned rewards and points
│   │   ├── saved                          # Saved/Bookmarked pandals module
│   │   │   ├── domain                     
│   │   │   │   └── models                 
│   │   │   │       └── saved_item_model.dart # Data model for a saved pandal or location
│   │   │   └── presentation               
│   │   │       ├── providers              
│   │   │       │   └── saved_provider.dart # Manages state of the user's saved items
│   │   │       └── saved_screen.dart      # Screen listing all saved/bookmarked items
│   │   └── transport                      # Navigation and transit guide module
│   │       ├── domain                     
│   │       │   └── metro_data.dart        # Static data configuration for local metro routes
│   │       └── presentation               # UI layer for transport
│   │           ├── metro_guide_screen.dart # Informational guide on using the metro during Puja
│   │           ├── metro_live_map_screen.dart # Real-time tracking of public transport on a map
│   │           └── parking_map_screen.dart # Map view highlighting available parking zones
│   ├── routes                             # Application routing configuration
│   │   ├── app_router.dart                # Main GoRouter configuration defining all app routes
│   │   └── route_names.dart               # Constant string definitions for all route names
│   ├── shell                              # Application shell and main layout wrapper
│   │   ├── widgets                        
│   │   │   └── liquid_nav_bar.dart        # Custom animated liquid bottom navigation bar
│   │   └── app_shell.dart                 # Scaffold wrapper implementing the bottom navigation
│   └── main.dart                          # Application entry point & initialization setup
├── .env                                   # Local environment variables and secret API keys (Git ignored)
├── .gitignore                             # Git ignore configuration file
├── README.md                              # This file, serving as the main project documentation
├── pubspec.lock                           # Automatically generated file locking dependency versions
└── pubspec.yaml                           # Flutter configuration file defining dependencies and assets
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
