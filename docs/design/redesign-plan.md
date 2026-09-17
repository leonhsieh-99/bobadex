# Bobadex visual system + UX redesign plan

Status: proposal (no frontend code changed yet).
Scope: Flutter app in `lib/`. Backend asks are listed separately in §11 and are not blocking for Phases 0–3.

This document is written so another model can execute it with minimal ambiguity. Where a value is given (hex, dp, ms) treat it as the spec. Where a choice is left open it is marked **[decision]**.

---

## 0. Audit summary: what exists today

### 0.1 Theming and styling (the root problem)

| Area | Current state | Problem |
|---|---|---|
| Theme catalog | `Constants.themeMap`: 12 raw `MaterialColor` swatches (`Colors.yellow`, `Colors.cyan`, …), default `'Brown'`. DB default is `'grey'` (not in map → falls back to Brown). | Palettes are Material demo colors, not designed. `Yellow.shade400` + white text fails contrast. Nothing about them says "Bobadex". |
| ThemeData | `bobadex.dart` seeds `ColorScheme.fromSeed`, then overrides scaffold/appBar to `shade50`, cards to `shade100`, **both** `ElevatedButton` and `TextButton` to filled `shade400` + white text. | TextButton looking like a filled button forces `AppButtonStyles.textButton` overrides scattered around. Whole background is tinted by the accent, so brand marks and photos compete with the chrome. |
| Color access | `Constants.getThemeColor(user.themeSlug).shadeNNN` in 15 files; plus hardcoded `Colors.black`, `Colors.grey.shade300`, `Colors.white`, `Colors.amber`, `Colors.orange`, `Colors.red`, `Colors.deepPurple` (onboarding selection!), `Colors.blueGrey` (drink icon), `Color(0xFFF5F5F5)`. | Two sources of truth. Dark themes are impossible. Skeletons are 6 hand-rolled copies with `grey.shade300`. |
| Typography | Default Material text theme. One custom font (`NotoSerif` SemiBold) used only by `NumberRating`. | No hierarchy system; the serif numeral is a good instinct that isn't carried through. |
| Icon art | Material icons + SVGs: `star`, `half_star`, `outlined_star`, `heart`, `heart_outlined`, `boba1` (cup), `tapioca_pearls/pearl_{outline,half,full}`. | Pearl SVGs exist but are unused. Star fill `#F8EE9B` reads washed-out. |
| Badge art | 34 illustrated shield badges (pastel, sparkles, roman-numeral tiers). | Strongest "collectible" asset in the app, but the flat Material chrome around it makes badges look imported from a different product. |
| Brand marks | `BrandMark` → mascot `IconPic` or deterministic `BrandLettering` (8 dark palettes, 1–2 letters). | Good foundation. Reuse and extend (silhouette state, accent stripe). |

### 0.2 Navigation
`/home` is the only real root. Everything else (Friends, Social, Rankings, Profile, Settings, Achievements) is `Navigator.push`. The floating pill bar (Friends · Social · + · Rankings · Profile) exists only on the current user's Home. Settings/Achievements/About/Sign out live in a Drawer. There is no slot for a Collection page.

### 0.3 Mental model mismatch in vocabulary
The data model already *is* a dex: **Brand** = the collectible; **Shop row** (`shops`) = the user's entry for that brand (one per brand per user, see `getShopByBrand`); **Drinks** = the logbook for that entry. The UI calls all of this "shops", which hides the collection structure ("Shops: 24" reads like a store list, "24 brands collected" reads like progress).

### 0.4 Stay / evolve / replace

| Pattern | Verdict | Why |
|---|---|---|
| Home = grid of your entries | **Stay** | Correct for a collection app. Frame it, don't replace it. |
| Two tile modes (brand mark vs banner photo), 2/3 columns | **Stay** (unify into one component with a style enum) | Users chose these; both are valid dex views. |
| `BrandMark` / `BrandLettering` | **Stay + extend** | Add silhouette (uncollected) state and accent stripe. |
| `FilterSortBar` (search + sort chips) | **Evolve** | Keep behaviour; restyle; fold asc/desc into the chip. |
| Floating pill nav | **Evolve** | Keep the look, make it persistent across 4 root tabs with a raised "+". |
| Drawer | **Replace** | Its items move to Profile/Settings. |
| `ProfileSummaryCard` + sections + inline feed | **Evolve → `CollectorCard`** | Already card-like; make it one object that fits one screen; move activity to its own page. |
| `StatCard` with emoji | **Evolve** | Keep count-up; replace emoji with app glyphs; compact layout. |
| `FeedEventCard` (elevated card per event) | **Replace → `FeedEventRow` + day groups** | Heavy, generic-social; brand identity missing. |
| `FeedCardOptions` variants | **Stay as concept** (friends / profile / brand) | Same three contexts; simpler options. |
| `FriendsShopGrid` "pearls" | **Evolve → `SharedBrandTile`** | Add social context (avatar stack, "You: 4.5"). |
| `FriendsShopDetailsPage` glow card + ExpansionTiles | **Replace → `SharedBrandPage`** | Add comparison view; drop the amber glow; unify icons. |
| Auth page (bare form) | **Replace presentation, keep logic** | OTP state machine, cooldowns, error codes stay untouched. |
| Onboarding wizard (2 pages, wall of text, hardcoded purple) | **Replace** | 3 short steps; layout prefs move to Settings. |
| `OnboardingGate` / `FirstRunCard` overlay | **Evolve** | Becomes an "empty dex" in-grid state. |
| Splash fun-fact | **Stay** | Charming, on-brand. Re-skin only. |
| `ShopDetailPage` banner + draggable sheet | **Stay** | Re-token only. |
| `BrandDetailsPage` | **Stay** | Re-token; add "in your collection" chip. |
| Settings pages (ListTiles) | **Evolve** | Group into sections; fix Privacy icon; theme picker → preview cards. |
| Rankings | **Stay** | Restyle rows; keep as "Leaderboard" inside Friends. |
| Hand-rolled skeletons (×6) | **Replace → `SkeletonBox`** | One primitive, token-driven. |
| `TopSnackBar` | **Stay** | Re-token colors. |

### 0.5 Things that currently fight the collection identity
1. Raw Material swatches as "themes"; accent tints the entire background.
2. Home shows an inventory with no count, progress, or "what's missing" signal.
3. Feed leads with the person and a verb; the collected brand has no visual presence.
4. Profile is a scrolling social profile with an inline feed, not an object.
5. Rich illustrated badges vs flat default chrome.
6. Emoji in stat cards (platform-inconsistent, cheap next to badge art).
7. "Shops" vocabulary hides the brand→entry→drinks structure.
8. Amber glow, orange stars for favorites, red badges: ad-hoc accents outside any system.

---

## 1. Visual direction: "Collector's Ledger"

A warm, paper-and-ink collector's binder. Not a game HUD, not a Pokédex screen. Cues:

- **Paper base, ink text, one accent.** Backgrounds are warm off-whites (or deep browns in dark themes). The theme accent is used sparingly: header, nav, primary buttons, progress fill, chips. Cards are near-white "printed" surfaces with a 1px ink-tinted outline and no drop shadow. Only floating chrome (nav pill, sheets, menus) gets a soft shadow.
- **Stars mean quality; pearls mean progress.** Ratings keep the star (re-colored to a warm gold). Collection progress, counts, and completion use the existing pearl SVGs (outline → half → full). This gives Bobadex a signature progress glyph without inventing new art.
- **Brand identity carries the color.** Tiles are neutral so each brand's mascot or lettering palette is the color on screen. A 2–3dp accent "spine" on entry tiles and region cards uses a brand/region-derived hue, so a grid of 30 entries has visible variety like a shelf of different cards.
- **Serif numerals and headlines.** A soft display serif for titles, counts, and ratings (the wordmark is a chunky script; a soft serif sits next to it comfortably and next to the badge illustrations). Body text stays system sans for legibility and native feel.
- **Collected vs uncollected is a first-class visual state.** Uncollected entries render as monochrome silhouettes with dashed outlines. This single state, applied everywhere (Collection page, Brand page chip, Feed "you have this too"), is what makes it feel like a dex.
- **Restraint in motion.** Short (150–300ms) transitions, one celebratory moment (region complete / badge unlock), count-ups for stats. Respect `MediaQuery.disableAnimations`.

---

## 2. Design tokens

All tokens live in `lib/ui/theme/`. Nothing in `lib/pages/` or `lib/widgets/` may reference `Colors.*` or `Constants.getThemeColor` after Phase 0.

### 2.1 `BobaTokens` (a `ThemeExtension<BobaTokens>`)

```dart
class BobaTokens extends ThemeExtension<BobaTokens> {
  // surfaces
  final Color bg;          // scaffold
  final Color surface;     // cards, sheets, nav
  final Color surfaceAlt;  // inset fields, chips-off, skeleton base
  final Color outline;     // 1px card borders, hairlines
  // ink
  final Color ink;         // primary text/icons
  final Color inkMuted;    // secondary text, timestamps
  final Color inkFaint;    // disabled, uncollected silhouettes
  // accent
  final Color accent;      // buttons, active nav, progress fill
  final Color onAccent;    // text on accent
  final Color accentSoft;  // tinted chip/pill backgrounds
  final Color accentInk;   // accent-colored text on bg (contrast ≥ 4.5:1)
  // semantic (theme-independent hue, light/dark tuned)
  final Color star;        // rating fill
  final Color starOutline; // rating stroke (transparent on dark)
  final Color heart;       // favorite
  final Color pearl;       // progress "tapioca" fill
  final Color success;
  final Color danger;
  // misc
  final Color shadow;      // used only by floating chrome
  final Brightness brightness;
}
```

Access via `extension BobaContext on BuildContext { BobaTokens get boba => Theme.of(this).extension<BobaTokens>()!; }`.

### 2.2 Non-color tokens (constants in `boba_tokens.dart`)

| Token | Value |
|---|---|
| `BobaRadius.xs / sm / md / lg / xl / pill` | 6 / 10 / 14 / 20 / 28 / 999 |
| `BobaSpace.x1 … x8` | 4, 8, 12, 16, 20, 24, 32, 40 |
| `BobaStroke.hairline / card / focus` | 0.5 / 1.0 / 2.0 |
| `BobaShadow.floating` | `BoxShadow(color: tokens.shadow, blurRadius: 24, offset: Offset(0, 8))` |
| `BobaMotion.press / fast / normal / slow` | 120 / 180 / 260 / 420 ms |
| `BobaMotion.stamp` | 500 ms, `Curves.easeOutBack` |
| `BobaSize.tap` | 44 |
| `BobaSize.markSm / markMd / markLg / markXl` | 32 / 44 / 64 / 96 |
| `BobaSize.avatarSm / avatarMd / avatarLg / avatarXl` | 24 / 40 / 56 / 88 |

### 2.3 Typography (`boba_typography.dart`)

Display font: **Fraunces** (Google Fonts, OFL) static TTFs at weights 500, 600, 700, high `SOFT` axis cut. Until the font files are added, fall back to the bundled `NotoSerif` SemiBold (already in `pubspec.yaml`). Body/UI: platform default (SF on iOS, Roboto on Android). **[decision]** if the owner prefers a single bundled font for both platforms, use Inter for body; not required.

| Role | Font | Size/line | Weight | Use |
|---|---|---|---|---|
| `display` | Fraunces | 32/38 | 600 | Page titles ("Leon's Bobadex", "Santa Clara County") |
| `headline` | Fraunces | 24/30 | 600 | Card names, big counts ("18 / 50") |
| `title` | Fraunces | 18/24 | 600 | Section headers, tile names on Brand page |
| `numeral` | Fraunces, tabular figures | inherits | 600 | Ratings, stat values, progress fractions |
| `body` | system | 16/22 | 400 | Notes, descriptions |
| `bodySm` | system | 14/20 | 400 | Secondary rows, subtitles |
| `label` | system | 13/16 | 600 | Chips, buttons, nav labels |
| `caption` | system | 12/16 | 500 | Timestamps, counts under tiles |

Map into `TextTheme`: `displaySmall=display`, `headlineSmall=headline`, `titleMedium=title`, `bodyLarge=body`, `bodyMedium=bodySm`, `labelLarge=label`, `labelSmall=caption`. Expose `context.bobaText.numeral`.

### 2.4 Iconography
- Use `*_rounded` Material icons everywhere (`Icons.settings_rounded`, etc.). Audit and replace non-rounded variants.
- App glyphs (SVG, `lib/assets/icons/`): `star`, `heart`, `boba1` → rename usage as "cup" (drinks), `pearl_*` (progress). Add two SVGs: `shield.svg` (badges stat), `seal.svg` (region placeholder). Tint via `ColorFilter.mode(color, BlendMode.srcIn)`; never bake theme colors into SVG.
- Stat glyph mapping: Brands → `pearl_full`, Drinks → `cup`, Badges → `shield`, Friends → `Icons.group_rounded`.

---

## 3. Curated theme catalog

Themes are named, complete token sets. Users pick a theme, never a raw color. Each theme is explicitly light or dark. (System-following light/dark pairing is a later addition via an optional `darkPartnerSlug`.)

Shared semantic values used by all themes unless overridden:
- Light: `star #E8B84A`, `starOutline #6B4E1A @ 60%`, `heart #E07A7A`, `pearl #2B1F17`, `success #4E8A5B`, `danger #C4453F`, `shadow #2B1F17 @ 12%`.
- Dark: `star #F0C25A`, `starOutline transparent`, `heart #EA8B8B`, `pearl #D9B08C`, `success #6FB07C`, `danger #E06B66`, `shadow #000000 @ 50%`.

### 3.1 Light themes

| slug | name | bg | surface | surfaceAlt | outline | ink | inkMuted | inkFaint | accent | onAccent | accentSoft | accentInk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `classic_milk_tea` (default) | Classic Milk Tea | `#F5EEE3` | `#FFFCF7` | `#EFE5D6` | `#E3D6C5` | `#2B1F17` | `#6F6157` | `#B8AB9E` | `#8A5A3C` | `#FFFFFF` | `#EBD9C7` | `#6E4429` |
| `matcha` | Matcha | `#EFF3E9` | `#FBFDF8` | `#E4EBDC` | `#D6DFCC` | `#1E271C` | `#5F6B5A` | `#A9B3A3` | `#5C7F4C` | `#FFFFFF` | `#DAE7CF` | `#46633A` |
| `taro` | Taro | `#F2EEF7` | `#FCFAFE` | `#E8E1F0` | `#DCD3E6` | `#27203A` | `#695F7A` | `#B0A7BF` | `#7B5AA6` | `#FFFFFF` | `#E5DAF1` | `#5E4384` |
| `strawberry` | Strawberry | `#FAEFF0` | `#FFFAFA` | `#F3E1E3` | `#EBD5D7` | `#33201F` | `#7A625F` | `#BFA9A7` | `#C5566A` | `#FFFFFF` | `#F6D6DC` | `#9E3F52` |
| `thai_tea` | Thai Tea | `#FAF0E6` | `#FFFAF5` | `#F2E2D3` | `#EAD8C6` | `#33241A` | `#7A6656` | `#BFAB9B` | `#D0703A` | `#FFFFFF` | `#F5DBC8` | `#A6512A` |
| `mango` | Mango | `#FBF4E2` | `#FFFCF4` | `#F3E8CF` | `#EADDBE` | `#33290F` | `#77693F` | `#BBAE86` | `#D9A23A` | `#2A2008` | `#F7E6B8` | `#8C6716` |
| `oolong` | Oolong | `#F1F1EE` | `#FBFBF9` | `#E6E7E2` | `#D8DAD4` | `#22252A` | `#646A72` | `#A6ABB2` | `#4E6F6C` | `#FFFFFF` | `#D8E5E3` | `#3B5654` |

### 3.2 Dark themes

| slug | name | bg | surface | surfaceAlt | outline | ink | inkMuted | inkFaint | accent | onAccent | accentSoft | accentInk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `brown_sugar` | Brown Sugar | `#1B1411` | `#251C18` | `#2F2520` | `#3A2E28` | `#F4EADF` | `#B5A493` | `#6E6055` | `#DDA46A` | `#1B1411` | `#3B2C22` | `#E8B981` |
| `black_sesame` | Black Sesame | `#121212` | `#1B1B1B` | `#262626` | `#2F2F2F` | `#ECECEC` | `#A3A3A3` | `#616161` | `#CFC7BA` | `#121212` | `#2C2A26` | `#D9D2C6` |
| `midnight_taro` | Midnight Taro | `#15121D` | `#1E1A29` | `#2A2438` | `#332C44` | `#EFEAF7` | `#ADA4C0` | `#6A6280` | `#B08BE0` | `#15121D` | `#2F2542` | `#C4A6EC` |

Contrast requirements (verify in a unit test, `test/theme_contrast_test.dart`): `ink` on `bg` and on `surface` ≥ 7:1; `inkMuted` on `surface` ≥ 4.5:1; `onAccent` on `accent` ≥ 4.5:1; `accentInk` on `bg` ≥ 4.5:1.

### 3.3 Slug migration (client-side, no DB migration required)

```dart
const legacyThemeMap = {
  'Brown': 'classic_milk_tea', 'grey': 'classic_milk_tea',
  'Green': 'matcha', 'Teal': 'matcha',
  'Purple': 'taro', 'Deep Purple': 'taro', 'Indigo': 'taro',
  'Pink': 'strawberry', 'Red': 'strawberry',
  'Orange': 'thai_tea', 'Yellow': 'mango',
  'Blue Grey': 'oolong', 'Cyan': 'oolong',
};
```
`BobaThemes.resolve(slug)` → known slug, else `legacyThemeMap[slug]`, else default. When a legacy slug is resolved for the current user, write the new slug back via `UserState.saveTheme()` once. Backend: change `user_settings.theme_slug` default from `'grey'` to `'classic_milk_tea'` (non-blocking).

### 3.4 Theme → `ThemeData` mapping (`boba_theme_builder.dart`)

| ThemeData field | Source |
|---|---|
| `colorScheme` | `ColorScheme(brightness, primary: accent, onPrimary: onAccent, primaryContainer: accentSoft, onPrimaryContainer: accentInk, secondary: accent, surface: surface, onSurface: ink, surfaceContainerHighest: surfaceAlt, outline: outline, outlineVariant: outline, error: danger, onError: white/bg)` |
| `scaffoldBackgroundColor` | `bg` |
| `appBarTheme` | bg `bg`, fg `ink`, elevation 0, `scrolledUnderElevation 0`, `titleTextStyle = title` |
| `cardTheme` | color `surface`, elevation 0, shape `RoundedRectangleBorder(lg)` with `BorderSide(outline, 1)` |
| `dialogTheme` | bg `surface`, shape `xl` |
| `bottomSheetTheme` | bg `surface`, shape top `xl` |
| `elevatedButtonTheme` | filled `accent`/`onAccent`, min height 48, shape `pill`, `label` text |
| `filledButtonTheme` | same as elevated (prefer `FilledButton` going forward) |
| `outlinedButtonTheme` | fg `ink`, side `outline`, shape `pill` |
| `textButtonTheme` | fg `accentInk`, transparent bg, `label` text (**this fixes the filled-TextButton problem; delete `AppButtonStyles.textButton`**) |
| `inputDecorationTheme` | filled, fill `surfaceAlt`, border none, focused border `accent` 2dp, radius `md`, content padding 14/16 |
| `chipTheme` | bg `surfaceAlt`, selected `accentSoft`, label `label`, side none, shape `pill` |
| `segmentedButtonTheme` | selected bg `accentSoft`, selected fg `accentInk`, side `outline` |
| `dividerTheme` | color `outline`, thickness 1, space 1 |
| `popupMenuTheme` | color `surface`, shape `md`, shadow via elevation 6 |
| `snackBarTheme` | unused (TopSnackBar) |
| `tabBarTheme` | indicator `accent`, label `ink`, unselected `inkMuted` |
| `textTheme` | §2.3 |
| `extensions` | `[tokens]` |

`bobadex.dart` becomes: `theme: BobaThemeBuilder.build(BobaThemes.resolve(themeSlug))`.

---

## 4. Shared component library (`lib/ui/components/`)

Every component below is theme-token driven, has explicit states, and a `Skeleton` variant where it loads data. Names are the spec.

| Component | Replaces | Props / states |
|---|---|---|
| `BobaCard` | ad-hoc `Card`, `Container(decoration…)` | `child, padding=x4, variant: flat (default: surface+outline, no shadow) \| floating (surface+shadow) \| inset (surfaceAlt, no outline)`, `onTap` (adds press scale 0.98 over `press`), `accentSpine: Color?` (2dp left stripe) |
| `BobaSheet` | `DraggableScrollableSheet` container in ShopDetail; auth form container | rounded top `xl`, surface, 4×36 grabber when draggable |
| `BobaButton` | `ElevatedButton`/`TextButton` mixes, `AppButtonStyles` | `variant: primary \| secondary(outlined) \| tertiary(text) \| danger`, `size: md(48) \| sm(36)`, `icon?`, `loading` (spinner replaces label, width preserved), `expanded` |
| `BobaChip` | `ChoiceChip`, `ActionChip`, `_VerbPill`, `_ShopLink` | `label, icon?, selected, onTap, trailing?` |
| `BobaSearchField` | `CustomSearchBar`, `CompactTextRow` | `controller, hint, onChanged, trailing?` |
| `FilterSortBar` | existing | keep API; render search + scrollable `BobaChip`s; tapping selected chip toggles direction and shows ↑/↓ trailing glyph; removes vertical divider |
| `RatingText` | `NumberRating`, inline star+number rows | `value: double?, size: sm(13) \| md(16) \| lg(22)`, `numeral` style + gold star; `null` → "—" |
| `PearlProgress` | none | `value 0..1, count: 5 \| 10, size`, renders `pearl_outline/half/full` SVGs tinted `pearl`; `semanticsLabel` |
| `PearlProgressBar` | none | linear, 8dp tall, track `surfaceAlt`, fill `accent`, optional label "18 / 50" in `numeral` |
| `StatChip` | `StatCard` | `glyph (SVG or IconData), value:int, label`, count-up 600ms (reuse `_CountUp`), compact horizontal |
| `StatTrio` | 3× `StatCard` row | `[StatChip×3]`, equal widths |
| `SectionHeader` | ad-hoc `Text(bold)` + Spacer | `title, trailing? (BobaButton.tertiary sm), padding` |
| `EmptyState` | `Constants.emptyListTextStyle` centers | `illustration (pearl cluster default), title, body?, action?` |
| `SkeletonBox` | 6 hand-rolled skeletons | `width, height, radius`, shimmer `surfaceAlt`→`outline` 1200ms loop; `SkeletonCircle`, `SkeletonText(lines)` helpers |
| `BrandMark` | existing | add `silhouette: bool` (renders lettering in `inkFaint` on `surfaceAlt` with dashed `outline`; mascot desaturated 100% + 45% opacity), `accent: Color` getter derived from slug hash → one of 8 hues (reuse `_palettes[i].background` lightened), `showAccentRing: bool` |
| `EntryTile` | `ShopGridTile` | see §6.3 |
| `AvatarStack` | none | `paths: List<String?>, size 24, max 3, overflow "+N"` |
| `BobaNavBar` | pill bar in `home_page.dart` | see §5 |
| `CollectorCard` | `ProfileSummaryCard` + badge/stat sections | see §7 |
| `FeedEventRow`, `DayHeader` | `FeedEventCard`, `FeedCardOptions` | see §8 |
| `SharedBrandTile` | `_buildShopPearl` | see §8.4 |
| `RegionSeal`, `RegionCard` | none | see §9 |
| `SettingsSection`, `SettingsRow` | `ListTile`s | see §10 |
| `CelebrationOverlay` | none | badge unlock / region complete; see §9.5 |

Rules enforced by a lint script (`tool/check_tokens.sh`, run in CI): in `lib/pages` and `lib/widgets`, zero matches for `Colors\.(black|white|grey|amber|orange|red|deepPurple|blueGrey|green)`, `Constants\.getThemeColor`, `themeColor\.shade`.

---

## 5. Navigation architecture

Move to a 4-tab persistent shell using go_router `StatefulShellRoute.indexedStack` (state persists per tab):

| Tab | Route | Contents |
|---|---|---|
| **Dex** | `/dex` | current `HomePage` for the signed-in user |
| **Collect** | `/collect` | new `CollectionPage` (§9). Until backend lands, ships behind `FeatureFlags.collection`; tab hidden when false (3 tabs + center "+"). |
| **Friends** | `/friends` | segmented: Feed · Shared · People. Merges `SocialPage` and `FriendsPage`; People shows request badge; Leaderboard (Rankings) entry lives at top of People. |
| **You** | `/you` | `AccountViewPage` for self, with `CollectorCard`; rows to Achievements, Settings, About. |
| **+** (center, raised) | pushes `AddShopSearchPage` | unchanged flow |

`BobaNavBar`: floating pill (same silhouette as today), `surface` bg, `BobaShadow.floating`, 64dp tall, 16dp side margins, 16dp from bottom safe area. Icons `*_rounded` 24; selected = `accent` icon + `label` under it; unselected = `inkMuted` icon only. Center "+" is a 52dp `accent` circle raised 8dp above the pill. Hides when keyboard is open (existing check) and on pushed detail pages.

Other users' pages (`HomePage(userId: other)`, `AccountViewPage(other)`) remain pushed routes without the shell. Drawer is removed: Settings/Achievements/About move to **You**; Sign out moves to Settings (bottom).

---

## 6. Page: Dex (Home)

### 6.1 Structure (`CustomScrollView`)
1. `SliverAppBar` (pinned, bg `bg`, no elevation): title in `display` "Leon's Bobadex" (other users: "Ana's Bobadex"). Trailing: current user → avatar 32 (tap → You); other user → none.
2. **`DexHeader` sliver**: one line of `StatChip`s in a row (no card): `● 24 brands  ◇ 87 drinks  ⛨ 6 badges`. When Collection is enabled, a second line: `RegionSeal 20 + "Santa Clara County" + PearlProgressBar 18/50` (tap → RegionDetail). Collapses on scroll.
3. `FilterSortBar` (pinned as `SliverPersistentHeader`): search + chips `Favorites (heart, toggle filter) · Rating · Name · Recent`; default sort favorite-desc (current default is `favorite-asc`, which puts favorites last — **fix to desc**).
4. Grid sliver of `EntryTile`, `crossAxisCount = user.gridColumns`, spacing 8 (from 4), padding 12, aspect 1.0 (mark style) or 0.85 (photo style shows more image).
5. Bottom padding 120 for nav.

### 6.2 States
- Loading: `EntryTileSkeleton` grid (8) + header skeleton.
- Empty, own dex: grid shows 6 `EntryTile.placeholder` (dashed, `inkFaint` pearl glyph) and an `EmptyState` card overlaid at top: "Your dex is empty" / "Add your first brand to start your collection." / `BobaButton.primary "Add a brand"`. Replaces `FirstRunCard` overlay.
- Empty, other user: `EmptyState` "No entries yet".
- No search results: `EmptyState` "Nothing matches "xyz"" with tertiary "Clear".

### 6.3 `EntryTile` spec
Props: `shop, brand?, style: mark | photo, columns, isNew (createdAt < 48h), onTap`.

Mark style (default):
- `BobaCard.flat`, radius `lg`, `accentSpine = brand.accent` (2dp, left edge).
- Top-right 20dp: heart glyph in `heart` when favorite; "NEW" `caption` pill in `accentSoft` when `isNew` (heart takes precedence; both → heart).
- Center: `BrandMark` at 52% of tile width (max 96), circular.
- Below mark: name, `label` weight 600 in `ink`, 1 line ellipsis, centered.
- Footer row: `RatingText.sm` left; `cup` glyph 14 + count in `caption` right.
- Press: scale 0.98 over `press`; ripple none.

Photo style: as today (cover image, bottom gradient `ink@80%→0`), text in white with `numeral` rating; radius `lg`; heart top-right white; fallback to `BrandLettering(expand)` when no banner. Keep `useMascots` logic.

Placeholder style (empty state and Collection uncollected): `BobaCard.inset`, dashed 1dp `outline` border (custom painter), `BrandMark(silhouette: true)` or pearl glyph, name in `inkFaint`, footer shows "N locations" (Collection) or nothing.

Semantics: `"Gong Cha, rated 4.5, 6 drinks, favorite"`.

---

## 7. Page: You / Profile → `CollectorCard`

Goal: fits one screen (≤ ~640dp content on a 390×844 device), reads as an object, screenshot-friendly.

### 7.1 `CollectorCard` (widget, `variant: full | compact`)
Full variant layout, width = screen − 32, `BobaCard.flat`, radius `xl`, `clipBehavior: antiAlias`:
1. **Header band** 72dp: `accentSoft` background with a very subtle repeated pearl-dot pattern (`CustomPainter`, `accent@8%`, 6dp dots, 18dp pitch). Left: small caps `caption` "BOBADEX" in `accentInk`. Right: "Collector since Mar 2024" (`users.created_at`, add to select) in `accentInk`.
2. **Avatar** 88dp, centered, overlapping the band by 44dp, 3dp `surface` ring.
3. Name in `headline`, `@username` in `bodySm inkMuted`; bio `bodySm`, max 2 lines, centered; empty bio → nothing (not "No bio set").
4. **`StatTrio`**: Brands / Drinks / Badges with glyphs (§2.4), `numeral` values.
5. **Badge slots**: always 3 circles 56dp. Filled = badge art on `surfaceAlt`; empty = dashed `outline` circle with `inkFaint` shield glyph. Below each: name in `caption`, 1 line. Tap (owner) → Achievements page with pin mode; tap (other) → badge detail bottom sheet (name, description).
6. **Favorite brand row** (existing favTile data): `BrandMark 40` + brand name `label` + top drink `caption inkMuted` + chevron; `inset` background. Hidden when none.
7. Footer 8dp of `accentSoft` (closes the "card" frame).

Compact variant (for People list, Leaderboard rows): avatar 40 + name + @username + `caption` "24 brands · 6 badges" + optional trailing.

### 7.2 Page composition (`AccountViewPage`)
- AppBar: title none; actions: existing friend/report popup for others; for self: `Icons.ios_share_rounded` (Phase 4, see 7.3) and `Icons.settings_rounded`.
- Body: `CollectorCard.full`, 12dp, then **action row**: self → `BobaButton.secondary "Edit profile"`; other → `BobaButton.primary "Add friend" | "Accept" | "Friends ✓"(disabled secondary)` + `BobaButton.secondary "View Bobadex"`.
- Then a `SettingsSection`-style list (self only): Achievements ›, Recent activity ›, Settings ›, About + Contact ›. For others: Recent activity › only.
- **Recent activity moves to `UserActivityPage`** (full-screen `UserFeedView` with `FeedEventRow(context: profile)`), which is what lets the profile fit one screen.

### 7.3 Share (Phase 4, optional)
Wrap `CollectorCard` in `RepaintBoundary`; export PNG at 3× with 24dp `bg` margin and a footer wordmark; share via `share_plus`. No layout differences between on-screen and export.

---

## 8. Friends: Feed, Shared, People

### 8.1 Feed hierarchy
`FeedView` renders a `ListView` of **day groups**: `DayHeader` ("Today", "Yesterday", "Sep 12") in `caption inkMuted` uppercase tracking 0.6, then a `BobaCard.flat` containing rows separated by 1dp `outline` hairlines. Pagination/refresh unchanged.

### 8.2 `FeedEventRow(event, context: friends | profile | brand)`
Anatomy (72dp min, padding 12/16):
- **Leading (44dp)**: brand-first. `shop_add`/`drink_add` → `BrandMark 44`; `achievement` → badge art 44 on `surfaceAlt` circle (hidden → lock glyph). In `friends` context, overlay the actor avatar 20dp at bottom-left with 2dp `surface` ring. In `brand` context, leading = avatar 44 (brand is implied). In `profile` context, no avatar overlay.
- **Title** (`bodySm`, actor and object bold `ink`, verb `inkMuted`):
  - `shop_add`: "**Ana** collected **Gong Cha**" (profile: "Collected **Gong Cha**")
  - `drink_add`: "**Ana** logged **Brown Sugar Latte** at Gong Cha" (needs payload `drink_name`, `shop_name`; if absent, "logged a drink at Gong Cha")
  - `achievement`: "**Ana** unlocked **Bobaholic III**"; hidden: "unlocked a hidden badge"
- **Trailing**: `RatingText.sm` for shop/drink events with rating; else none.
- **Body** (optional): notes `bodySm` max 2 lines; photos → horizontal strip of 64dp squares radius `sm`, max 4 + "+N" (reuse `HorizontalPhotoPreview` with new sizes).
- **Footer row**: time ago `caption inkMuted` left (**not accent**); right: context chip. `friends` context, `shop_add`: if `ShopState.getShopByBrand(currentUserId, brandSlug) != null` → `BobaChip` sm "In your dex ✓" (`accentSoft`), else `BobaChip` sm "Add to dex" (tertiary, → BrandDetails). This is the relevance hook.
- Taps: row → `BrandDetailsPage` (shop/drink) or badge sheet (achievement); avatar → profile.
- Skeleton: `SkeletonCircle 44` + two `SkeletonText` lines.

### 8.3 Feed empty state
`EmptyState`: "Quiet in here" / "Add friends to see what they're collecting." / `BobaButton.primary "Find friends"` → People segment.

### 8.4 Shared (`FriendsShopGrid` → `SharedBrandGrid`)
2-column grid of `SharedBrandTile`: `BobaCard.flat`, `BrandMark 56` centered, name `label`, `RatingText.sm` "4.3" + `caption` "avg", `AvatarStack` of friends (max 3, +N), and when the current user has it a `caption accentInk` "You: 4.5". Tap → `SharedBrandPage`. Sort: by number of friends desc, then avg rating.

### 8.5 `SharedBrandPage` (replaces `FriendsShopDetailsPage`)
1. Header: `BrandMark 96` (tap → BrandDetails), name `headline`, `RatingText.lg` avg + `caption` "from 4 friends", `AvatarStack`.
2. **Your status card**: if you have the brand → `BobaCard.inset` "Your entry · 4.5 ★ · 6 drinks ›" (→ your `ShopDetailPage`); else `BobaButton.primary "Add to your dex"` (→ BrandDetails).
3. **`RatingComparisonBar`**: 1–5 axis (ticks at 1, 2, 3, 4, 5 in `caption`), 48dp tall; each friend's avatar 24dp placed at `rating`, your avatar with `accent` ring; collisions stack vertically (max 2 rows, then +N). Tap avatar → scrolls to their row.
4. `SectionHeader "Friends' entries"`, list of `FriendEntryRow` sorted by rating desc: avatar 40 (crown glyph 14 `star`-colored at bottom-right for `mostDrinksUser`, caption "most drinks"), name `label`, heart glyph if favorite (**not** `Icons.star`), `RatingText.sm`, `caption` "6 drinks". Expand (chevron, same `ExpansionTile` behaviour, flat) → note `bodySm`, "Top drinks" list `name — RatingText.sm`. Rows inside one `BobaCard.flat` with hairlines. No glow.
5. **Photos from friends** strip (`HorizontalPhotoPreview`) if the RPC returns media paths; `galleryCount`/`filePath` already exist in `FriendShopInfo` but are unused; if paths are absent, section hidden (backend ask §11).

### 8.6 People
`CollectorCard.compact` rows; search field; "Requests (N)" row at top → `FriendRequestsPage`; "Leaderboard ›" row → `RankingsPage` (restyled rows using `CollectorCard.compact` and `RatingText`).

---

## 9. Collection page (new)

### 9.1 Domain
- **Region**: a boundary (`ref.boundaries`, `level 6 = county` for v1; cities later). Fields: `id, name, level, parentId?, abbreviation (derived: first letters, e.g. "SCC"), silhouettePath? (simplified SVG path string, backend-provided)`.
- **Collectible**: `(regionId, brandSlug, locationCount)` where `locationCount ≥ threshold` (threshold is server-side; default 3; hidden from UI except in an info sheet).
- **Progress**: `collected = collectibles ∩ user.shops.brandSlug`; `fraction = collected / total`.
- **Tier** by fraction: `< 0.25 Sipper`, `< 0.5 Regular`, `< 0.75 Local`, `< 1 Devotee`, `1.0 Legend`. **[decision]** names are placeholders in the boba register; keep them un-gamey.
- Repository interface (`lib/collection/collection_repository.dart`) with `MockCollectionRepository` (fixture JSON under `lib/assets/fixtures/collection_mock.json`) and `SupabaseCollectionRepository` (Phase 4b). UI is built against the interface.

### 9.2 Concepts considered

| Concept | Description | Pros | Cons | Verdict |
|---|---|---|---|---|
| A. Literal map | Vector/tile map with brand pins per region | Geographic fantasy; discoverability | It's a store finder, not a collection; 50 brands × many locations = clutter; heavy SDK; no clean completion read; hard to screenshot; pushes toward Yelp-ness | Reject as primary; allow a static silhouette only |
| B. Region passport / stamp book | Regions as passport pages with a seal, progress, and brand grid; completing a region "stamps" it | Strong collection fantasy; scales linearly with regions; reuses `EntryTile`; screenshot-worthy; celebrations fall out naturally | Needs seals (degrade gracefully without silhouettes) | **Primary frame** |
| C. Progression list | Plain list of regions → flat brand checklist | Simplest, most scalable | Feels like settings; little identity | Use its structure for the region list and filters |
| D. Binder slot board | Fixed 3×3 slots per page, swipe pages within a region | Very tactile, card-binder feel | Paging fights scanning 50 brands; awkward with variable counts | Borrow the dashed empty-slot visual only |

Recommendation: **B as the frame, C's list/filters for scale, D's empty-slot visual for uncollected entries. No interactive map in v1.**

### 9.3 `CollectionPage` (tab root)
1. `SliverAppBar` title `display` "Collection". Trailing info icon → bottom sheet "How regions work" (threshold explanation, one paragraph).
2. Summary line: `StatChip`s "3 regions started · 41 collected".
3. **Home region** (first `RegionCard`, larger): user-selected in a picker (search over regions by name; v1 has no GPS). Stored client-side (`AppPrefs.homeRegionId`) until a `user_settings.home_region_id` column exists.
4. `SectionHeader "Regions"` + list of `RegionCard` sorted: home first, then progress desc, then name. Only regions where the user has ≥1 collected or home region appear; others via "Explore regions" search row at the bottom.
5. Empty (no regions, no home): `EmptyState` "Pick your home region" + `BobaButton.primary "Choose region"`.

`RegionCard`: `BobaCard.flat`, `accentSpine = region hue` (hash of id → 8 hues), left `RegionSeal 48`, name `title`, `numeral` "18 / 50" right, `PearlProgressBar` full width, `caption` row "Regular · +2 this month" (delta = collected entries with `createdAt` in last 30 days), then a row of the 5 most recently collected `BrandMark 28`s. Completed regions: seal filled `accent`, small `caption` "Complete ✓". Tap → `RegionDetailPage`.

`RegionSeal`: circular 1.5dp `ink` ring, inner `surfaceAlt`; if `silhouettePath` present, draw it centered in `inkMuted` at 70% of diameter; else abbreviation in `numeral`. Completed: ring + fill `accent`, silhouette/abbr in `onAccent`, 6 tiny notches around the ring (stamp look, `CustomPainter`).

### 9.4 `RegionDetailPage`
1. Hero (not a card, on `bg`): `RegionSeal 72`, name `display`, `numeral` 40/44 "18 / 50", `caption inkMuted` "brands collected", `PearlProgressBar` with tier label "Regular · 7 to Local".
2. Filter chips: All · Collected (18) · Missing (32); sort: A–Z · Most locations · Recently collected.
3. Grid (`gridColumns` from settings, min 3 on this page for scanability): `EntryTile` — collected → mark style with your `RatingText`; missing → placeholder style with real brand name (knowing what exists is part of the fun) and `caption` "12 locations". Tap collected → your `ShopDetailPage`; tap missing → `BrandDetailsPage` (its "Add Visit" button completes the loop).
4. "Elsewhere" section (collapsed by default): your entries for brands that are *not* collectibles in this region (below threshold / outside region) so denominators stay honest.
5. Static silhouette only; no interactive map.

### 9.5 Celebration (`CelebrationOverlay`)
Trigger: after `ShopState.add` when `collected == total` for any region (or on badge unlock, reuse for achievements). Full-screen scrim `ink@40%`, `BobaCard.floating` center: `RegionSeal 120` stamps in (`stamp` motion: scale 1.6→1.0, rotate −8°→0, `HapticFeedback.mediumImpact`), title `headline` "Santa Clara County complete", `caption` "50 / 50 brands", 20 pearl particles fall for 900ms, `BobaButton.primary "Nice"`. Dismiss on tap outside. Skips animation when `disableAnimations`.

Also emit an achievement: `depends_on: {type: 'region_complete', region_id}` (backend §11).

### 9.6 Scalability notes
Regions list is paginated by relevance (home, touched, then search). Brand grid uses `SliverGrid` with cached brand lookups from `BrandState`. Silhouette paths are ≤ 2 KB each after `ST_Simplify(0.01)`; cache in `BrandCacheStore`-style local store.

---

## 10. Settings

- `SettingsPage` → grouped `SettingsSection`s (each a `BobaCard.flat` with hairline rows):
  - **Account**: Your account ›
  - **Appearance**: Theme › (subtitle = current theme name, leading 20dp swatch of `accent`), Layout ›
  - **Privacy & data**: Privacy › (fix icon → `Icons.lock_outline_rounded`), AI & automated systems ›, Export my data (move from Account)
  - **About**: About + Contact ›, Version (read-only, `package_info_plus`)
  - **Sign out** (danger tertiary, bottom; moved from Drawer)
- `SettingsRow`: leading icon 22 `inkMuted`, title `bodySm ink`, subtitle `caption`, trailing chevron or value or `Switch`.
- **Theme page**: 2-column grid of `ThemePreviewCard`s (aspect 0.8): renders that theme's `bg` with a mini `EntryTile` mark-style mock (with a real `BrandLettering` "GC"), a `RatingText`, and a pill button, wrapped in `Theme(data: build(theme))` so preview is exact. Name below; selected → 2dp `accent` ring + check. Sections "Light" / "Dark". Live-apply on tap (existing `setTheme`), save on pop (existing `PopScope` logic).
- **Layout page**: keep switches (columns, banner photos, mascots/minimal) and add a live two-tile `EntryTile` preview at the top that reflects the toggles.
- **Account page**: `SettingsRow`s with label/value (drop bold-left ListTiles); avatar 96 with pencil overlay 28dp `accent` circle; Delete account stays as bottom danger button.

Functionality unchanged in all settings pages.

---

## 11. Login, splash, onboarding

### 11.1 Splash
`bg` (default theme), logo SVG 160, fun-fact `BobaCard.flat` with `Icons.lightbulb_outline_rounded` in `accent`. Nothing else changes.

### 11.2 Auth page (presentation only; `_AuthPageState` logic, OTP client, cooldowns, error codes untouched)
- Layout: `Scaffold(bg)`, no AppBar. Top region (≈38% height): decorative `DexBackdrop` painter (a faint 4×3 grid of rounded empty-tile outlines in `outline@60%` with three tiles filled with `BrandLettering`-style blocks at 12% opacity), logo wordmark SVG centered 140 wide, tagline `bodySm inkMuted` "Your boba collection, one cup at a time."
- Bottom: `BobaSheet` (surface, top radius `xl`, padding 24, `SafeArea`) containing the form; scrolls with keyboard. Sheet title `headline`: "Log in" / "Create account" / "Check your inbox" (code step, with masked identifier `bodySm inkMuted`). Back arrow inside sheet on code step (existing behaviour).
- Controls: `SegmentedButton` Email/Phone (themed), `TextFormField`s (themed `inputDecorationTheme`), `OtpCodeField`, `BobaButton.primary expanded loading:_loading` primary action. Secondary links become a compact footer: one `BobaButton.tertiary` ("Use password instead" / "Use a code instead"), resend row (`caption` countdown), and one `bodySm` footer "Don't have an account? **Sign up**" (rich text tap). "Create an account" for `unknownUser` appears inline under the error text as a tertiary button (existing condition).
- Error text: `caption danger` under the field, live region (existing).

### 11.3 Onboarding wizard (3 steps, replaces current 2)
1. **Welcome**: badge art `where_it_began.png` 120, `headline` "Welcome to Bobadex", `body` two sentences: "Every brand you try becomes an entry in your collection. Rate drinks, earn badges, and see what your friends are collecting." `BobaButton.primary "Next"`. The developer's personal note moves to About.
2. **Pick a theme**: `ThemePreviewCard` grid (same widget as Settings), live-apply; Back/Next.
3. **First entry**: `headline` "Add your first brand", embedded `AddShopSearchPage` search (constructor gets `embedded: true` to hide its AppBar) so the user can pick a brand → BrandDetails → Add Visit; or `BobaButton.tertiary "Skip for now"`. Finishing calls `saveTheme()` + `setOnboarded()` (existing).
Layout choices (columns, photos vs icons) are removed from onboarding; defaults stay (2 columns, mark style). `OnboardingGate` keeps its gating logic but renders the §6.2 empty-dex state instead of `FirstRunCard`.

---

## 12. Other pages (re-token only unless noted)

- `ShopDetailPage`: sheet → `BobaSheet` on `surface`; drink rows flat inside one `BobaCard.flat` with hairlines; `RatingText`; "+ Drink" → `BobaButton.secondary sm`; banner placeholder → `surfaceAlt` with `cup` glyph `inkFaint`.
- `BrandDetailsPage`: add `BobaChip` under the name: "In your dex ✓ since Mar 2024" or "Not collected"; "Add Visit" → `BobaButton.primary sm`; About/Photos use `SectionHeader`; chips → `BobaChip`.
- `AchievementsPage`: group by family (strip trailing `_N`/roman numeral from asset name or add `family` to achievements) into `SettingsSection`-style cards; row = badge art 44 (locked hidden → `inkFaint` silhouette of `default_badge.png`), name `label`, description `caption`, trailing `numeral` "3/5" or check in `success`. Pin toggle shown when opened from Profile with `pinMode: true`.
- `RankingsPage`: rows → `CollectorCard.compact` with trailing `numeral` count; brands tab rows → `BrandMark 40` + name + `RatingText`.
- `AddShopSearchPage`: rows → `BrandMark 40` leading; owned → trailing `BobaChip` sm "In dex ✓"; "Request a new brand" row → `SettingsRow` style.
- `TopSnackBar`: bg by type: success `success`, error `danger`, info `ink` (dark themes: `surfaceAlt` + `ink` text), radius `md`.

---

## 13. Copy and vocabulary
- "Shops" → **"Brands"** where it counts entries (stats, headers). Keep "shop" in user-facing flows where it means the visit ("Add Visit" stays).
- Verbs: **collected** (first entry for a brand), **logged** (drink), **unlocked** (badge), **complete** (region).
- Stat labels: Brands · Drinks · Badges.
- Never say "Pokédex". The word "dex" appears only in the app name and the tab label "Dex".

---

## 14. Accessibility & platform
- Min tap target 44dp; tiles announce `"{brand}, rated {x}, {n} drinks[, favorite][, not collected]"`.
- All text ≥ 12dp; contrast tested in `theme_contrast_test.dart`.
- `disableAnimations` → skip shimmer, stamp, particles; keep opacity transitions.
- Dark themes verified for status bar icon brightness (`SystemUiOverlayStyle` from `tokens.brightness`).
- `flutter_native_splash` color updated to `#F5EEE3` (default `bg`).

---

## 15. Implementation roadmap (ordered by dependency, then impact)

### Phase 0 — Foundation (blocks everything)
1. Add `lib/ui/theme/{boba_tokens,boba_themes,boba_theme_builder,boba_typography}.dart`; add Fraunces TTFs to `lib/assets/fonts/` + `pubspec.yaml`.
2. `bobadex.dart` uses `BobaThemeBuilder.build(BobaThemes.resolve(slug))`. Delete `Constants.themeMap`, `getThemeColor`, `AppButtonStyles`, `heartColor`, `starColor`, `badgeBgColor`, `emptyListTextStyle`, `badgeLabelStyle`. `Constants.defaultTheme = 'classic_milk_tea'`. Add `legacyThemeMap` + one-time write-back in `UserState.loadUser`.
3. Add primitives: `BobaCard`, `BobaSheet`, `BobaButton`, `BobaChip`, `BobaSearchField`, `RatingText`, `PearlProgress(+Bar)`, `StatChip/StatTrio`, `SectionHeader`, `EmptyState`, `SkeletonBox`, `AvatarStack`. Extend `BrandMark` (silhouette, accent).
4. Mechanical migration of the 15 `getThemeColor` call sites and all hardcoded colors to tokens/primitives: `bobadex.dart`, `home_page.dart`, `shop_grid_tile.dart`, `shop_detail_page.dart`, `brand_details_page.dart`, `brand_about_section.dart`, `account_view_page.dart`, `friends_shop_details_page.dart`, `friends_shop_grid.dart`, `friend_requests_page.dart`, `filter_sort_bar.dart`, `custom_search_bar.dart`, `add_circle_button.dart`, `onboarding_wizard.dart`, `settings_theme_page.dart`, plus `stat_box.dart`, `feed_event_card.dart`, `top_snack_bar.dart`, `splash_page.dart`, `rankings_page.dart`, `achievements_page.dart`, `thumb_pic.dart`, `icon_pic.dart`, `rating_picker.dart`, `number_rating.dart`.
5. Theme picker page (`ThemePreviewCard`) and onboarding theme step, since old slugs no longer exist.
6. Add `tool/check_tokens.sh` and `test/theme_contrast_test.dart`; CI green.
Done when: app runs with every theme, zero forbidden color references outside `lib/ui/theme`, screenshots of Home/Profile/Feed in Classic, Mango, Brown Sugar reviewed.

### Phase 1 — Shell + Dex (highest daily impact)
1. `StatefulShellRoute` with 4 tabs (Collect hidden behind flag), `BobaNavBar`, remove Drawer, move Sign out to Settings, merge Friends+Social into Friends with segments.
2. Home → `CustomScrollView` with `DexHeader`, pinned `FilterSortBar`, `EntryTile` (unify modes), default sort favorite-desc, empty-dex state replacing `FirstRunCard`.
3. Settings grouped sections + fixes (Privacy icon, Export moved, Version row).

### Phase 2 — First impression + Profile
1. Splash re-skin; Auth page presentation rework (`BobaSheet`, `DexBackdrop`); onboarding 3 steps; `AddShopSearchPage(embedded)`.
2. `CollectorCard` full/compact; `AccountViewPage` restructure; `UserActivityPage`; `users.created_at` in profile select; badge slots; achievements pin mode.
3. `AchievementsPage` grouping; `RankingsPage` restyle.

### Phase 3 — Social relevance
1. `FeedEventRow` + `DayHeader` + day grouping in `FeedView`, `UserFeedView`, `BrandFeedView`; "In your dex ✓ / Add to dex" chip; `drink_add` rendering.
2. `SharedBrandTile` grid; `SharedBrandPage` with `RatingComparisonBar`, `FriendEntryRow`, photos strip (if backend provides paths).
3. `BrandDetailsPage` collected chip; `AddShopSearchPage` rows.

### Phase 4 — Collection
4a (no backend): `CollectionRepository` + mock, `RegionSeal`, `RegionCard`, `CollectionPage`, `RegionDetailPage`, home-region picker (client pref), `CelebrationOverlay`; ship behind `FeatureFlags.collection` for internal testing.
4b (backend ready): `SupabaseCollectionRepository`, silhouette paths, `home_region_id` setting, `region_complete` achievement, flag on.
4c (optional polish): profile share export, theme unlocks as rewards (e.g., "Brown Sugar" unlocked at 25 brands — a real collection hook; keep all v1 themes free), system light/dark pairing.

---

## 16. Backend asks (non-blocking until Phase 4b unless noted)
1. `user_settings.theme_slug` default `'classic_milk_tea'` (cosmetic).
2. `users.created_at` already exists; include in profile fetches (client change only).
3. Feed payload for `drink_add`: `drink_name`, `shop_name`, `rating`, `brand_slug` (Phase 3 uses graceful fallback if missing).
4. `get_friends_shops`: include up to 4 public `image_path`s per friend entry (Phase 3 photos strip).
5. Collection RPCs (Phase 4b): `get_region_progress(user_id)` → `[{region_id, name, level, total, collected, recent_brand_slugs[5], last_collected_at}]`; `get_region_brands(region_id, user_id)` → `[{brand_slug, location_count, collected, user_shop_id?, user_rating?}]`; `get_region_silhouette(region_id)` → simplified SVG path (`ST_AsSVG(ST_Simplify(geom, 0.01))`), cache-friendly.
6. `user_settings.home_region_id bigint null`.
7. `achievements.depends_on` type `region_complete` with `region_id`; unlock check in `AchievementsState`.

---

## 17. File layout after Phase 0

```
lib/
  ui/
    theme/
      boba_tokens.dart          # BobaTokens, BobaRadius, BobaSpace, BobaMotion, BobaSize, BobaShadow
      boba_themes.dart          # catalog + legacyThemeMap + resolve()
      boba_theme_builder.dart   # tokens -> ThemeData
      boba_typography.dart      # TextTheme + numeral style
      boba_context.dart         # context.boba, context.bobaText
    components/
      boba_card.dart boba_sheet.dart boba_button.dart boba_chip.dart boba_search_field.dart
      rating_text.dart pearl_progress.dart stat_chip.dart section_header.dart empty_state.dart
      skeleton_box.dart avatar_stack.dart boba_nav_bar.dart theme_preview_card.dart
      entry_tile.dart collector_card.dart feed_event_row.dart day_header.dart
      shared_brand_tile.dart rating_comparison_bar.dart region_seal.dart region_card.dart
      celebration_overlay.dart settings_section.dart dex_backdrop.dart
  collection/
    collection_models.dart collection_repository.dart mock_collection_repository.dart
    supabase_collection_repository.dart
  pages/ … (existing, migrated; friends_shop_details_page.dart -> shared_brand_page.dart;
            new: collection_page.dart region_detail_page.dart user_activity_page.dart)
tool/check_tokens.sh
test/theme_contrast_test.dart
```
