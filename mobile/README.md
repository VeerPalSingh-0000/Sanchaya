# 📱 Sanchaya - Flutter Mobile App

> The mobile experience of **Sanchaya** – a unified, dark-mode media tracker for Anime, Movies, and Web Series built with Flutter & Riverpod.

---

## 🌟 Key Mobile Features

- 🎬 **Unified Media Vault**: Track Movies, TV Shows, and Anime in one unified watchlist.
- 📺 **Episode Progress Tracker**: Detailed episode tracking for TV series and Anime with season/episode breakdown.
- 🎨 **Dynamic Palette Extraction**: Color palettes dynamically generated from media poster art.
- ⚡ **Supabase Synchronization**: Real-time cloud sync for user preferences, watch history, and watchlist status.
- ⚡ **AniList & TMDB Integration**: Live data fetched from AniList (Anime) and TMDB (Movies & Web series).
- 📊 **Statistics & History**: Detailed watch history graphs and status distribution.
- 🚀 **Offline First**: Fast image and data caching with Hive & `cached_network_image`.

---

## 🛠️ Architecture & Tech Stack

- **Framework**: Flutter 3.x (Dart 3.x)
- **State Management**: Flutter Riverpod 3.x (`AsyncNotifier` & `StateNotifier`)
- **Navigation**: `go_router` 17.x with deep-linking & tab shell routing
- **HTTP & Networking**: `dio` 5.x with custom retry & cache interceptors
- **Backend / Database**: `supabase_flutter` 2.x
- **Animations**: `flutter_animate` 4.x
- **Local Storage**: `hive_flutter` 1.x

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.12.0` or higher
- Android Studio / Xcode for emulator or physical device testing

### Environment Configuration

Create a `.env` file inside the `flutter_app` folder with your credentials:

```env
SUPABASE_URL=https://your-supabase-project.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
TMDB_API_KEY=your-tmdb-api-key
```

### Installation & Execution

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run static analysis check
flutter analyze

# 3. Launch app on connected device/emulator
flutter run
```

### Building Release Packages

```bash
# Build Android APK
flutter build apk --release

# Build Android App Bundle
flutter build appbundle --release
```
