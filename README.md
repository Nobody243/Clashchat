# ClashChat

A mobile-first Flutter application that enables users to engage in AI-powered debates on various topics. Engaging in structured debates with an AI opponent, users can choose their stance, track their progress, and view performance analytics.

A responsive web build is also available as a secondary deployment target to provide broader accessibility (e.g., for quick portfolio viewing without installing an application).

## 📥 Downloads & Demos

- **Android Mobile App**: Download the latest release APK from **[GitHub Releases](https://github.com/Nobody243/ClashChat/releases/latest)**.  
  *(Note: Since this APK is distributed outside the Google Play Store, Android will display an "Unknown Sources" or Play Protect warning during installation. This is expected and safe for this portfolio/demo build.)*
- **Web Version (Secondary)**: Engage directly on the web at **[ClashChat Web Demo](https://clashchat-54dc0.web.app)**.  
  *(Note: The web build adapts the mobile layout for wider screens. For the full native experience, we recommend downloading the Android APK.)*

### 🌐 Browser Notes
If you are accessing the web version using a browser with aggressive built-in privacy tools or VPNs enabled (such as Opera GX with its built-in VPN turned on), these features may block client connections to Firebase Auth or the proxy. If you encounter issues loading the demo or logging in, please try temporarily disabling these browser settings or using a standard browser.


## Table of Contents

- [About](#about)
- [Features](#features)
- [Screenshots](#screenshots)
- [Prerequisites](#prerequisites)
- [Running Locally](#running-locally)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Dependencies](#dependencies)
- [Contributing](#contributing)
- [Security Notes](#security-notes)
- [License](#license)

## About

ClashChat is a portfolio/learning project demonstrating:
- Firebase Authentication with Email/Password and Google Sign-In
- Firestore-backed user profiles and debate history
- AI-powered debate scoring and chat via Groq API
- Responsive Flutter UI with dark/light theme support
- Session management and user profile editing

## Features

- Firebase Authentication (Email + Google Sign-In)
- Firestore-backed user profiles and debate records
- AI scoring and chat via Groq API integration (routed securely via proxy)
- Dicebear avatars (thumbs style, brand palette) rendered as SVG
- Daily per-user usage quota of 40 debates (client-enforced for demo)
- Dark/Light theme with smooth transitions
- Debate history with filtering capabilities
- 24-hour session management
- Three game modes: Casual (free practice), Ranked (competitive scoring), and Learning (coached feedback and tips)
- Responsive layout support adapting the mobile-first UI for desktop/tablet browser windows

## Prerequisites

- Flutter SDK 3.11.1 or higher
- Dart SDK 3.11.1 or higher
- Android SDK (for Android deployment)
- Xcode (for iOS deployment)
- Firebase project setup
- APP_SHARED_SECRET (configured in local env)

## Running Locally

This repo does not include Firebase configuration files (`lib/firebase_options.dart`, 
`android/app/google-services.json`) since they're tied to the developer's own Firebase 
project and API keys.

To run this project yourself:

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/clashchat.git
   cd clashchat
   ```
2. Create your own Firebase project at https://console.firebase.google.com
3. Install the FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
4. Run the configure command from the project root and follow the prompts to link your Firebase project:
   ```bash
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` with your own credentials.
5. Enable **Authentication** (Email/Password & Google Sign-In) and **Firestore** in your Firebase project console — these are required for the app to function.
6. If building for Android, download `google-services.json` from your Firebase project settings and place it in `android/app/`.
7. Install dependencies and run:
   ```bash
   flutter pub get
   flutter run
   ```

> [!NOTE]
> The AI chat feature uses the Groq API via a Cloudflare Worker proxy (sibling repo `clashchat-proxy`). You'll need your own Groq API key and your own Worker deployment for that feature to work — the deployed proxy is tied to the maintainer's account and only accepts ID tokens from the maintainer's Firebase project.

## Configuration

### Environment Variables

Copy `env.example` to `env` and fill in your values:

```bash
cp env.example env
```

Edit `env` with your client settings:

```
APP_SHARED_SECRET=your_app_shared_secret_here
GOOGLE_WEB_CLIENT_ID=your_google_web_client_id_here
```

> [!NOTE]
> Groq API calls are routed through a separate, privately-hosted server-side proxy (not included in this repository) to keep the Groq API key out of the client app. The client uses `APP_SHARED_SECRET` as a lightweight header token when talking to the proxy for basic abuse deterrence.

### Firebase Setup

#### Web
- Register a web app in Firebase Console
- Add the configuration to `lib/firebase_options.dart`

#### Android
- Add `google-services.json` to `android/app/`
- Configure SHA-1 fingerprints for Google Sign-In

#### iOS
- Add `GoogleService-Info.plist` to `ios/Runner/`
- Configure URL schemes in Xcode

## Usage

### Development

Run in Chrome (recommended for development):

```bash
flutter run -d chrome
```

Run on Android device/emulator:

```bash
flutter run -d <device-id>
```

Run on iOS simulator:

```bash
flutter run -d ios
```

### Building for Production

Android:

```bash
flutter build apk --release
```

iOS:

```bash
flutter build ios --release
```

Web:

```bash
flutter build web --release
```

## Architecture

The project follows a modular architecture pattern:

```
lib/
├── core/           # Theme, design tokens (colors, typography, spacing), providers
├── models/         # Data structures (ChatMessage, DebateRecord)
├── screens/        # UI screens and navigation
├── services/       # Business logic (Auth, AI, Session)
└── widgets/        # Reusable UI components
```

### Design System

`DESIGN.md` is the source of truth. Code lives in two places:

- `lib/core` — tokens and theme. `app_colors_ext.dart` holds the semantic palette for both themes (read via `context.colors`), `app_typography.dart` the Outfit type scale (`context.text`) plus `context.mono()` for JetBrains Mono numerics, `app_spacing.dart` the spacing/radius/duration scales, and `app_theme.dart` builds `ThemeData` from them. The theme choice is persisted by `ThemeProvider`.
- `lib/ui` — the atmosphere layer (`AppBackdrop` stage lights + grain, `GlassCard`/`GlassBar`, `AnimatedNumber`, `ParticleBurst`, `Bento`, `AppSegmented`, `AppPage` with `AppBreakpoints`) and the component kit: `AppButton`, `AppIconButton`, `AppCard`/`AppListGroup`/`AppIconTile`, `AppPill`, `AppTextField`, `AppSkeleton`, `AppEmptyState`, `AppSectionHeader`, `ScoreRing`, `Pressable`, `StaggeredColumn`, and `AppIcons` (Lucide). Screens compose these and never hardcode colors, font sizes, `Icons.*`, or emoji.

### Key Components

- **AuthService**: Handles Firebase Authentication and Google Sign-In
- **AIService**: Manages AI conversation and scoring with multi-model fallback support (`openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `groq/compound`)
- **SessionService**: Manages 24-hour user sessions
- **ThemeProvider**: Manages dark/light theme state

### API Routing Architecture

Groq is never called from the client. Every AI request goes through a Cloudflare Worker
(`clashchat-proxy`, a sibling repo) that holds the Groq key:

```
[Flutter App] --(X-App-Secret + Firebase ID token)--> [Cloudflare Worker] --(GROQ_API_KEY)--> [Groq]
```

The Worker:
- verifies the **Firebase ID token** (RS256, Google public keys) so it knows which user is calling,
- checks the `X-App-Secret` header with a timing-safe compare (abuse deterrent only; the value ships in the client),
- rate-limits per user (20 completions / minute),
- allow-lists models, caps `max_tokens`, strips unknown fields, and rejects bodies over 64 KB,
- streams Groq's SSE body straight through when `stream: true`.

`AIService` sends the current user's ID token on every call and cycles through the allowed models on failover.

### Responsive Layout Support

To support wider viewports on desktop browsers, the app uses a mobile-first design adapted for wider screens via the following new components:
- **ResponsiveLayout** ([responsive_layout.dart](file:///e:/Projects/MAD%20CLASHCHAT/clashchat/lib/core/responsive_layout.dart)): Centralizes standard viewport width breakpoints and device checking helper methods.
- **DesktopPageShell** ([desktop_page_shell.dart](file:///e:/Projects/MAD%20CLASHCHAT/clashchat/lib/widgets/desktop_page_shell.dart)): A dual-column layout wrapper that constrains, centers, and adapts mobile forms and debate windows gracefully on desktop dimensions.

## Dependencies

### Core Framework
| Package | Version | Purpose |
|---------|---------|---------|
| flutter | sdk | UI framework |
| firebase_core | ^3.6.0 | Firebase initialization |
| firebase_auth | ^5.3.1 | Authentication |
| cloud_firestore | ^5.4.4 | Database |

### UI & Animations
| Package | Version | Purpose |
|---------|---------|---------|
| google_fonts | ^6.2.1 | Custom typography |
| flutter_animate | ^4.5.0 | Animations |
| flutter_svg | ^2.0.10+1 | SVG rendering |
| lucide_icons_flutter | ^3.1.25 | Icon set |

### State Management & Storage
| Package | Version | Purpose |
|---------|---------|---------|
| provider | ^6.1.2 | State management |
| shared_preferences | ^2.2.3 | Key-value storage |

### Utilities
| Package | Version | Purpose |
|---------|---------|---------|
| http | ^1.1.0 | HTTP requests |
| flutter_dotenv | ^5.2.1 | Environment variables |
| uuid | ^4.4.0 | UUID generation |

## Contributing

We welcome contributions. Please read our contributing guidelines for details on:

- Keeping secrets out of the repository
- Setting up the development environment
- Code style and submission process

See [CONTRIBUTING.md](CONTRIBUTING.md) for more information.

## Security Notes

This is a demo/portfolio application and is not production-hardened. Important considerations:

- **Proxy-based API Routing**: Groq API calls are routed through the Cloudflare Worker described above so the Groq key never reaches the client. The Worker also verifies Firebase ID tokens and rate-limits per user.
- **Abuse Deterrence**: `APP_SHARED_SECRET` is a lightweight header token. It is present in the compiled client, so it is not a security boundary on its own; the Firebase ID token is.
- **Do Not Commit Secrets**: `env`, `lib/firebase_options.dart`, `android/app/google-services.json` and the Flutter `ephemeral/` folders are git-ignored and must stay that way. The release workflow reads them from GitHub Actions secrets (`APP_SHARED_SECRET`, `FIREBASE_OPTIONS_B64`, `GOOGLE_SERVICES_B64`, optional `GOOGLE_WEB_CLIENT_ID`) and fails if any is missing.
- **Local dev**: `flutter run -d chrome` works out of the box; the Worker allows any `localhost` port. Other origins must be listed in the Worker's `ALLOWED_ORIGINS`.
- **Deploy order**: deploy the Worker first (it ships with `REQUIRE_FIREBASE_AUTH: "false"`, accepting old and new clients), then the clients, then flip the Worker to required auth. The web build cannot talk to the pre-token Worker because of its CORS allow-list.
- **Rotating `APP_SHARED_SECRET`**: generate a new value (`openssl rand -hex 32`) and set it in three places: the Worker (`npx wrangler secret put APP_SHARED_SECRET`), the GitHub Actions secret, and your local `env`. Old builds stop working the moment the Worker secret changes.
- **Firestore rules** validate quota and rank fields on the client-owned user document. Rank points may only move by one debate's worth per write (+50 / -20). Moving scoring and point awards server-side is the next step.
- **Avatars**: Avatar seeds are stored as strings and rendered via `flutter_svg` for consistent avatar generation.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- Flutter team for the cross-platform framework
- Firebase for backend services
- Groq for AI API capabilities