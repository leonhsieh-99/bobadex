# Bobadex

A Pokédex for boba shops. Catalog shops and drinks, rate them, and share the log with friends.

The iOS app is live: [Bobadex on the App Store](https://apps.apple.com/us/app/bobadex/id6752920262) (v1.0.2).

## Demo

[![Watch 80-second demo](https://img.youtube.com/vi/4EYwQm6eHbI/hqdefault.jpg)](https://youtu.be/4EYwQm6eHbI "Watch the short demo on YouTube")

<details>
  <summary>Screenshots</summary>

  <p align="center">
    <img width="260" alt="IMG_3568" src="https://github.com/user-attachments/assets/968727ce-8b93-4163-884a-ec87acb80cc3" />
    <img width="260" alt="IMG_3572" src="https://github.com/user-attachments/assets/5b0dc286-e4bf-4dc4-af33-69ccf182307e" />
    <img width="260" alt="IMG_3570" src="https://github.com/user-attachments/assets/0843c2f5-11cc-477d-bb8b-4ce037108f49" />
    <br/>
    <img width="260" alt="IMG_3567" src="https://github.com/user-attachments/assets/0a458bfd-ce71-4eb9-8f4a-e1d710a8ec8c" />
    <img width="260" alt="IMG_3571" src="https://github.com/user-attachments/assets/b3d3cfea-9c35-4562-8e05-630d617e7dde" />
    <img width="260" alt="IMG_3569" src="https://github.com/user-attachments/assets/10736282-f19a-40d1-8bc7-62e636f9f4e0" />
    <br/>
    <img width="260" alt="IMG_3565" src="https://github.com/user-attachments/assets/9827c86c-be98-49f4-8d84-f958d23a6435" />
    <img width="260" alt="IMG_3566" src="https://github.com/user-attachments/assets/a77528ba-5cf7-4fe5-aceb-95afa4c25bd6" />
  </p>
</details>

## Features

- **Shop log** — add visits from a brand catalog, rate, favorite, pin a drink, and keep notes
- **Drinks** — per-shop drink ratings and tasting notes
- **Photos** — shop galleries, banners, compressed uploads, and cached thumbs
- **Friends** — requests, profiles, and viewing someone else’s Bobadex
- **Social** — friend activity feed and a friends-shop grid
- **Brands** — brand pages with stats, about copy, photos, and search that matches aliases
- **Rankings** — user and brand leaderboards
- **Achievements** — unlocks tied to shops, drinks, friends, notes, and uploads
- **Account** — theme, home grid layout, privacy/analytics, password, data export, and account deletion

The public brand catalog is currently California-focused.

## Stack

| Layer | Choice |
|---|---|
| App | Flutter (iOS / Android), Dart `>=3.10` |
| State | Provider + `ChangeNotifier` |
| Routing | go_router (`/splash`, `/auth`, `/home`, `/reset`) |
| Backend | Supabase (Postgres, Auth/PKCE, Storage, RPCs, RLS) |
| Observability | Firebase Analytics, Sentry |
| Local cache | SharedPreferences + on-disk brand catalog |

Related (not in this repo): a SvelteKit admin tool, and a web client that is still in progress.

## Layout

```
lib/
  main.dart              bootstrap (env, Firebase, Supabase, Sentry)
  bobadex.dart           MultiProvider + themed MaterialApp.router
  app_initializer.dart   auth session → load user data
  pages/                 screens
  state/                 ChangeNotifier stores
  widgets/               shared UI
  models/                data types
  helpers/               router, uploads, cache, retries
```

Sign-in loads user, shops, drinks, brands, friends, media banners, achievements, and feed in `AppInitializer`. Stores reset on sign-out.

## Local development

Requires [Flutter](https://docs.flutter.dev/get-started/install) with Dart 3.10+.

```bash
git clone https://github.com/leonhsieh-99/bobadex.git
cd bobadex
flutter pub get
```

Keys come from `.env.dev` / `.env.prod` at compile time (not bundled as assets). Needed: `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Optional: `SENTRY_DSN`.

```bash
flutter run --dart-define-from-file=.env.dev
flutter build ipa --dart-define-from-file=.env.prod
```

iOS uses Swift Package Manager. CocoaPods is not required.

## Current progress

Shipped on iOS as **1.0.2**. Recent work in this tree:

- Brand search reads `brand_aliases` (cache v2), not a column on `brands`
- Hive removed; brand catalog is a JSON file cache so Swift Package Manager can build
- Provider rebuilds narrowed: `context.select` instead of watching whole notifiers, shop tiles subscribe per shop, theme listens to `themeSlug` only, loads no longer notify at start

Still on Provider. A Riverpod move is not planned until per-route / per-id state or context-free testing actually hurts.

Not shipped yet: in-app notification settings (the screen exists but is commented out of Settings).

## License & legal

[Privacy](https://leonhsieh-99.github.io/bobadex-legal/privacy.html) · [Terms](https://leonhsieh-99.github.io/bobadex-legal/terms.html)

Personal project. Feedback: leonchsieh@gmail.com
