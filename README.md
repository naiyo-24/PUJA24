<div align="center">
  <img src="assets/logo.png" alt="PUJO24 Logo" width="200"/>
  <br/>
  <img src="assets/icons/icon_ios.png" alt="PUJO24 Icon" width="100"/>
</div>

# PUJO24

A comprehensive Flutter application designed to enhance the Durga Puja experience. This app serves as your ultimate guide for pandal hopping, discovering local food, planning itineraries, and connecting with groups during the festival.

## 📖 Table of Contents

- [Project Overview](https://github.com/naiyo-24/PUJA24#project-overview)
- [Tech Stack](https://github.com/naiyo-24/PUJA24#tech-stack)
- [Prerequisites](https://github.com/naiyo-24/PUJA24#prerequisites)
- [Getting Started](https://github.com/naiyo-24/PUJA24#getting-started)
- [Environment Configuration](https://github.com/naiyo-24/PUJA24#environment-configuration)
- [Project Structure](https://github.com/naiyo-24/PUJA24#project-structure)
- [Architecture Deep Dive](https://github.com/naiyo-24/PUJA24#architecture-deep-dive)
  - [Layered Architecture](https://github.com/naiyo-24/PUJA24#layered-architecture)
  - [Data Flow Diagram](https://github.com/naiyo-24/PUJA24#data-flow-diagram)
- [State Management (Riverpod)](https://github.com/naiyo-24/PUJA24#state-management-riverpod)
  - [Provider ↔ Notifier Pattern](https://github.com/naiyo-24/PUJA24#provider--notifier-pattern)
- [Models Layer](https://github.com/naiyo-24/PUJA24#models-layer)
- [Services Layer](https://github.com/naiyo-24/PUJA24#services-layer)
  - [API Service (GraphQL & Dio)](https://github.com/naiyo-24/PUJA24#api-service-graphql--dio)
  - [Auth Service](https://github.com/naiyo-24/PUJA24#auth-service)
  - [WebSocket Service](https://github.com/naiyo-24/PUJA24#websocket-service)
  - [Location & Map Services](https://github.com/naiyo-24/PUJA24#location--map-services)
- [Routing (GoRouter)](https://github.com/naiyo-24/PUJA24#routing-gorouter)
- [Theming System](https://github.com/naiyo-24/PUJA24#theming-system)
- [Feature Modules](https://github.com/naiyo-24/PUJA24#feature-modules)
  - [Authentication Flow](https://github.com/naiyo-24/PUJA24#authentication-flow)
  - [Pandal Discovery & Planner](https://github.com/naiyo-24/PUJA24#pandal-discovery--planner)
  - [Group Planning](https://github.com/naiyo-24/PUJA24#group-planning)
  - [Food & Transport](https://github.com/naiyo-24/PUJA24#food--transport)
  - [Puja Passes](https://github.com/naiyo-24/PUJA24#puja-passes)
- [Backend API Contract](https://github.com/naiyo-24/PUJA24#backend-api-contract)
- [Real-Time Communication](https://github.com/naiyo-24/PUJA24#real-time-communication)
- [Firebase Integration](https://github.com/naiyo-24/PUJA24#firebase-integration)
- [Key Design Decisions](https://github.com/naiyo-24/PUJA24#key-design-decisions)
- [Common Gotchas](https://github.com/naiyo-24/PUJA24#common-gotchas)
- [Adding a New Feature](https://github.com/naiyo-24/PUJA24#adding-a-new-feature)
- [Contributing](https://github.com/naiyo-24/PUJA24#contributing)
- [License](https://github.com/naiyo-24/PUJA24#license)

## Project Overview
PUJO24 is designed to simplify and enhance the festival experience. It is a one-stop companion app for Durga Puja. During the peak of the festival, coordination among friends, discovering new pandals, finding nearby food stalls, and securing VIP passes become logistical challenges. PUJO24 solves this by offering real-time tracking of groups on a live map via WebSockets, deep integration with Google Maps for location services and route guidance, and a comprehensive database of pandals and food options. The app is built with a strong focus on modularity and performance, utilizing Flutter for a beautiful cross-platform UI and Riverpod for reactive state management.

## Tech Stack
- **Framework**: Flutter (SDK: ^3.12.2)
- **State Management**: Riverpod (`flutter_riverpod`) for compile-safe, robust dependency injection and state reactivity.
- **Routing**: GoRouter for declarative, path-based routing.
- **Networking**: Dio for REST API calls & `graphql_flutter`/custom implementation for GraphQL interactions. WebSockets are used for real-time telemetry.
- **Backend/Services**: Firebase (Auth, Core), Google Maps Platform, Google Places API.
- **UI & Animations**: `flutter_animate` for micro-interactions, `google_nav_bar` and `curved_navigation_bar` for fluid navigation, `shimmer` for skeleton loading states.
- **Payments**: Razorpay for VIP Puja Passes transactions.

## Prerequisites
- Flutter SDK (>= 3.12.2)
- Dart SDK
- Android Studio / VS Code with Flutter extensions installed
- A valid Firebase project configuration (`google-services.json` for Android / `GoogleService-Info.plist` for iOS)
- Google Maps API key with Places and Directions API enabled

## Getting Started
1. **Clone the repository**
   ```bash
   git clone https://github.com/naiyo-24/PUJA24.git
   cd PUJA24
   ```
2. **Install dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app**
   ```bash
   flutter run
   ```

## Environment Configuration
Create a `.env` file in the root directory and configure the environment variables carefully. Ensure this file is never committed to version control.
```env
# API Configurations
API_BASE_URL=https://backend.pujo24.com
GRAPHQL_URL=https://backend.pujo24.com/graphql
WEBSOCKET_URL=wss://backend.pujo24.com/ws/groups

# Third-Party Keys
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

## Project Structure
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

## Architecture Deep Dive

### Layered Architecture
The application is structured using a strict **Feature-First Layered Architecture**. Each domain of the application (e.g., Auth, Groups, Pandals) is encapsulated within its own folder inside `lib/features/`. Within each feature, we enforce a strict separation of concerns:
- **Data Layer**: Contains API services, WebSockets, and Repositories. It is responsible for fetching raw data and parsing it into domain models.
- **Domain Layer**: Contains the core business logic, strongly typed Data Models, and entities. This layer is independent of any UI framework.
- **Presentation Layer**: Contains the UI widgets, Screens, and Riverpod Notifiers/Providers. The presentation layer exclusively communicates with the Data layer via Providers.

### Data Flow Diagram
The data flows unidirectionally, adhering to reactive programming principles:
```text
UI Event (User taps button)
      │
      ▼
Riverpod Notifier (Processes business logic)
      │
      ▼
Repository (Requests data)
      │
      ▼
Service (Dio / GraphQL / WebSocket)
      │
      ▼
Backend API (Returns JSON)
      │
      ▼
Model (Parsed via fromJson)
      │
      ▼
Riverpod State Updates (State = AsyncData(Model))
      │
      ▼
UI Re-builds (Widget consumes state via ref.watch)
```

## State Management (Riverpod)

### Provider ↔ Notifier Pattern
We rely on the modern Riverpod `Notifier` and `AsyncNotifier` patterns to manage business logic. This ensures state is isolated and strongly typed.
- **AsyncNotifierProvider**: Used for fetching and mutating data asynchronously (e.g., fetching a list of pandals).
- **NotifierProvider**: Used for synchronous local state management (e.g., toggling a UI filter).
Instead of passing data down the widget tree via constructors, widgets use `ConsumerWidget` or `ConsumerStatefulWidget` to listen (`ref.watch`) or read (`ref.read`) state directly from the globally accessible providers.

## Models Layer
Every entity received from the backend is strongly typed. We do not pass raw Maps (`Map<String, dynamic>`) to the UI.
Models are defined in the `domain/models/` directory of each feature. They use factory constructors like `fromJson` to parse data safely.
- **Examples**: `PujaDetailModel`, `RestaurantModel`, `PassPackageModel`, `UserVoucherModel`.

## Services Layer

### API Service (GraphQL & Dio)
- **REST via Dio**: Used for transactional operations like Authentication (`/auth/login`), Group management, and Passes purchases. Configured in `core/network/api_config.dart`.
- **GraphQL**: The app relies heavily on a GraphQL endpoint for complex, nested data fetching, reducing over-fetching on the mobile client. Handled by `graphql_service.dart`.

### Auth Service
Manages authentication bridges between Firebase and our custom backend. Firebase is used to seamlessly handle Phone OTP and Google Sign-in. The resulting Firebase ID token is then verified against the backend to receive an application-specific JWT session token.

### WebSocket Service
The `group_websocket_service.dart` establishes a persistent connection to the backend. It pushes local GPS coordinates and receives real-time coordinate updates from other group members. This service is decoupled from the UI and updates a Riverpod state stream directly.

### Location & Map Services
The `places_api_service.dart` orchestrates calls to the Google Places API. It handles geocoding user inputs, retrieving place details, and fetching nearby transit stations (Metro) and parking lots.

## Routing (GoRouter)
Routing is strictly declarative using the `go_router` package.
- The router configuration is centralized in `routes/app_router.dart`.
- Deep linking is inherently supported.
- Navigation utilizes `context.go()` or `context.push()` referencing hardcoded strings defined in `routes/route_names.dart` to prevent typos.

## Theming System
The UI is fully customized to reflect the vibrant spirit of Durga Puja.
- **Tokens**: `app_colors.dart` and `app_typography.dart` define a strict design system.
- **Theme**: `app_theme.dart` constructs the global `ThemeData`, supporting both Light and Dark modes seamlessly.

## Feature Modules

### Authentication Flow
A frictionless onboarding experience. Users can authenticate using Phone Number (OTP via Firebase) or Google Sign-In. Post-login, users undergo a profile setup flow, including a map picker screen to set their default base location.

### Pandal Discovery & Planner
The core utility of the app. It lists hundreds of pandals. Users can view detailed information (theme, facilities, history), check the live crowd status, and tap to add the pandal to a personalized daily itinerary (Planner).

### Group Planning
Solves the problem of losing friends in massive crowds. Users can create a private group and share an invite code. Once inside the group, members can view a shared itinerary and track each other's live locations on a shared map via WebSockets.

### Food & Transport
Integrates seamlessly with the Places API to discover top-rated food stalls and restaurants near specific pandals. The transport module provides real-time metro guide maps and locates nearby authorized parking zones.

### Puja Passes
An integrated e-commerce flow allowing users to purchase VIP express entry passes. Razorpay handles the transaction. Purchased passes are stored securely and rendered as QR codes for offline scanning at entry gates.

## Backend API Contract
The client seamlessly interacts with a robust suite of APIs:
- **Authentication**: `POST /auth/login`, `POST /auth/verify-otp`, `POST /auth/logout`
- **GraphQL Engine**: `POST /graphql` (Pandal listings, Food data)
- **Groups**: `GET /groups`, `POST /groups`, `POST /groups/join`, `POST /groups/{groupId}/itinerary`
- **Passes**: `GET /passes/packages`, `POST /passes/purchase`, `POST /passes/verify`
- **Rewards**: `GET /rewards/balance`, `POST /rewards/scan`, `POST /rewards/redeem`
- **External**: Google Places API (`/nearbysearch`), Google Directions API.

## Real-Time Communication
WebSockets are the backbone of the live tracking feature. When a user enters the `group_live_map_screen.dart`, a WebSocket connection is initialized. A background isolate safely polls GPS coordinates and streams them through the socket, updating the state of markers on the Google Map in real-time.

## Firebase Integration
- **Firebase Authentication**: Used as the primary identity provider.
- **Firebase Cloud Messaging (FCM)**: Used in tandem with `flutter_local_notifications` to deliver push notifications (e.g., group invites, pass confirmations).

## Key Design Decisions
- **Modularity via Feature-First**: By structuring by feature rather than layer (e.g., putting all models in one folder), the codebase scales infinitely without becoming a tangled mess.
- **Riverpod over Provider**: Eliminated `BuildContext` dependencies in state logic, making the app much more testable and robust.
- **GraphQL for Discovery**: Instead of maintaining 50 REST endpoints for different filter combinations of Pandals and Food, GraphQL provides dynamic querying capabilities.

## Common Gotchas
- **WebSocket Drops**: Network changes (e.g., switching from WiFi to Cellular) will drop the socket. Ensure the retry logic in `group_websocket_service.dart` is resilient.
- **Google Maps API Quotas**: The Places API is expensive. Aggressive caching strategies are implemented to prevent duplicate requests when moving the map slightly. Ensure your `.env` key is restricted to avoid abuse.

## Adding a New Feature
1. Create a new directory under `lib/features/my_new_feature/`.
2. Scaffold `data/`, `domain/`, and `presentation/` sub-directories.
3. Define your data models in `domain/models/`.
4. Create an API Service and Repository in `data/`.
5. Create a Notifier in `presentation/providers/` that consumes the Repository.
6. Build your UI screens in `presentation/` and watch the Notifier.
7. Expose the new screen as a route in `routes/app_router.dart`.

## Contributing
We welcome contributions!
1. Fork the repository and create your feature branch (`git checkout -b feature/AmazingFeature`).
2. Adhere strictly to the `flutter_lints` rules defined in `analysis_options.yaml`.
3. Commit your changes with descriptive messages.
4. Open a Pull Request for review.

## License
This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
