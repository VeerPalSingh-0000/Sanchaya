<div align="center">

# 🌌 S A N C H A Y A 🌌

**The only media tracker that actually has rizz.** 

[![Next.js](https://img.shields.io/badge/Built_with-Next.js_14-black?style=for-the-badge&logo=next.js)](#)
[![Flutter](https://img.shields.io/badge/Mobile_App-Flutter_3.x-02569B?style=for-the-badge&logo=flutter)](#)
[![TypeScript](https://img.shields.io/badge/Language-TypeScript-blue?style=for-the-badge&logo=typescript)](#)
[![Dart](https://img.shields.io/badge/Language-Dart-0175C2?style=for-the-badge&logo=dart)](#)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase)](#)
[![Tailwind CSS](https://img.shields.io/badge/Styling-Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css)](#)
[![Android APK](https://img.shields.io/badge/Download-Android_APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://raw.githubusercontent.com/VeerPalSingh-0000/Sanchaya/main/releases/sanchaya-app.apk)

<br/>

> *Track your anime, movies, and web series without the UI looking like it was built in 2005.*

</div>

<br/>

## 🛑 The Problem

Let's be real. MyAnimeList, TMDB, and Letterboxd are cool and all, but tracking everything across 5 different apps gives total **NPC energy**. You watch a hype anime, a 10/10 movie, and a mid Netflix series, and you gotta open three different sites just to log them? Massive L.

---

## 🚀 Enter Sanchaya

**Sanchaya** is a unified, ultra-aesthetic, glassmorphic media vault that tracks *literally everything*. Movies? Yes. Anime? Yes. Webseries? Obviously. Available on both **Web** and native **Mobile (Android/iOS)**.

It hits different because it actually looks like a flagship app. No cap, the UI is so clean you might forget to touch grass.

<br/>

## 🔥 Features That Pass The Vibe Check

<table>
  <tr>
    <td width="50%">
      <h3>🔮 Unified Vault</h3>
      <p>Keep your entire watch history (Anime + Movies + Series) in one pristine grid. No more app-hopping. <b>Valid.</b></p>
    </td>
    <td width="50%">
      <h3>✨ Next-Level Aesthetics</h3>
      <p>Heavy glassmorphism, buttery smooth micro-animations, and a dark mode UI that radiates <b>main character energy</b>.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>🧠 Big Brain Recommendations</h3>
      <p>An intelligent <b>"For You"</b> page that analyzes your top-rated stuff and feeds you personalized bangers. It actually <i>knows</i> your taste.</p>
    </td>
    <td width="50%">
      <h3>⚡ Instant Franchise Tracking</h3>
      <p>Watch a movie with 8 sequels? <b>One click</b> marks the entire cinematic universe as "Completed." Ultimate W feature.</p>
    </td>
  </tr>
  <tr>
    <td width="50%">
      <h3>📱 Native Mobile App</h3>
      <p>Seamless cross-platform mobile experience built with Flutter, Riverpod state management, smooth animations, and offline caching.</p>
    </td>
    <td width="50%">
      <h3>📊 Watch History & Stats</h3>
      <p>Track your watching habits, total time spent, breakdown by genres, and track episodes watch progress with interactive widgets.</p>
    </td>
  </tr>
</table>

<br/>

## 📱 Download & Install the Mobile App

Get the native Android app directly and track your media anywhere:

<p align="center">
  <a href="https://raw.githubusercontent.com/VeerPalSingh-0000/Sanchaya/main/releases/sanchaya-app.apk">
    <img src="https://img.shields.io/badge/Direct_Download-Sanchaya.apk-brightgreen?style=for-the-badge&logo=android&logoColor=white" alt="Download APK" height="42" />
  </a>
</p>

| Source | Link | Notes |
| :--- | :--- | :--- |
| 🚀 **Direct APK (Recommended)** | [Download Sanchaya.apk](https://raw.githubusercontent.com/VeerPalSingh-0000/Sanchaya/main/releases/sanchaya-app.apk) | Instant download from repo (`releases/sanchaya-app.apk`) |
| 📦 **GitHub Releases** | [Releases Page](https://github.com/VeerPalSingh-0000/Sanchaya/releases) | Release tags & changelogs |

### 📲 Quick Install Guide:
1. Tap the **[Download Sanchaya.apk](https://raw.githubusercontent.com/VeerPalSingh-0000/Sanchaya/main/releases/sanchaya-app.apk)** button on your Android phone.
2. If prompted, tap **"Download anyway"** and open the downloaded `.apk` file.
3. Allow **"Install unknown apps"** for your browser when requested.
4. Tap **Install** and start tracking!

### 🔨 Building the APK Yourself:
```bash
cd mobile
flutter pub get
flutter build apk --release
# Output will be located at: mobile/build/app/outputs/flutter-apk/app-release.apk
```

---

## ⚙️ Powered By The Giants

Under the hood, Sanchaya hooks seamlessly into the best APIs on the internet so your data is always fresh, accurate, and blazing fast.

- 🎬 **TMDB**: Powering the flawless metadata for Movies and Webseries.
- 🌸 **AniList**: Delivering real-time, comprehensive anime databases.
- ⚡ **Supabase**: Powering real-time synchronization, user authentication, and watchlists.

---

## 🛠️ Tech Stack (For the nerds)

This app wasn't built on vibes alone.

### Web Application
| Layer | Tech | Why? |
| :--- | :--- | :--- |
| **Framework** | Next.js 14 (App Router) | Because we like it blazingly fast. |
| **Styling** | TailwindCSS + Custom CSS | For those buttery smooth glows and glass layers. |
| **Database** | PostgreSQL + Prisma | To keep your watchlist securely locked in. |
| **Auth** | NextAuth.js | Glitch-free, secure logins. |

### Mobile Application (Flutter)
| Layer | Tech | Why? |
| :--- | :--- | :--- |
| **Framework** | Flutter 3.x (Dart) | Silky smooth 60fps native mobile UI. |
| **State Management** | Riverpod | Reactive, compile-safe state handling. |
| **Routing** | GoRouter | Declarative URL & deep-link navigation. |
| **Backend / Sync** | Supabase Flutter | Instant cloud sync for watchlists & watch history. |
| **Caching** | Hive Caching | Instant load times & offline caching support. |

<br/>

## 💻 Wanna run it locally? Say less.

### 🌐 Web App Setup
**1. Clone it down**
```bash
git clone https://github.com/VeerPalSingh-0000/Sanchaya.git
cd Sanchaya/website
```

**2. Install dependencies**
```bash
npm install
```

**3. Set up environment variables**
Create a `.env` file in the `website/` directory:
```env
TMDB_API_KEY=your_key
DATABASE_URL=your_postgres_url
NEXTAUTH_SECRET=your_secret
NEXTAUTH_URL=http://localhost:3000
```

**4. Fire it up**
```bash
npm run dev
```
Open `http://localhost:3000` and enjoy the aesthetic.

<br/>

### 📱 Flutter Mobile App Setup

**1. Navigate to the mobile directory**
```bash
cd Sanchaya/mobile
```

**2. Install Flutter dependencies**
```bash
flutter pub get
```

**3. Configure environment variables**
Create a `.env` file in `mobile/`:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
TMDB_API_KEY=your_tmdb_api_key
```

**4. Run the Flutter app**
```bash
flutter run
```

---

<div align="center">
  <sub>Built with ❤️ and way too much caffeine. Stay winning. 👑</sub>
</div>

