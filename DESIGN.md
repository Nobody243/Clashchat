# Design System: ClashChat

Single source of truth for how ClashChat looks and moves. Code lives in `lib/core` (tokens, theme) and `lib/ui` (component kit). Anything not covered here defaults to restraint.

## 1. Visual Theme & Atmosphere

A debate arena after hours. Warm near-black surfaces, one brass accent used like a trophy, and typography that does the talking. Density is "daily app balanced" (5/10): generous padding, never cramped, never empty. Variance is moderate (5/10): left-aligned headers, asymmetric hero on Home, strict single column on phones. Motion is fluid but short (5/10): things settle in under 260 ms, nothing loops except the timer under one minute and the typing indicator.

What it is not: a neon purple AI app. No glows, no gradient buttons, no emoji as icons, no spinning robots.

## 2. Color Palette & Roles

Two themes, one personality. Dark is the default.

### Dark ("Arena Night")
- **Canvas** `#121113` — scaffold background. Warm off-black, never pure black.
- **Surface** `#1A181B` — cards, sheets, app bar fill when scrolled.
- **Surface Raised** `#232025` — nested panels, AI message bubbles, input fills.
- **Inset** `#0D0C0E` — recessed wells (progress tracks, code-like blocks).
- **Ink** `#F2EFEA` — primary text. Warm white.
- **Ink Muted** `#A39E99` — secondary text, descriptions.
- **Ink Hint** `#7A756F` — placeholders, timestamps. Passes 4.5:1 on Canvas.
- **Hairline** `#2A272B` — 1 px borders. **Hairline Strong** `#3A363C` — dividers that must read.
- **Brass** `#D4A84B` — the one accent. CTAs, active nav, focus rings, rank highlights. Text on Brass is `#1A1409`.
- **Brass Soft** `rgba(212,168,75,0.12)` — accent tint for selected rows and chips.
- **Sage** `#6FC29B` on `#15302A` — "For" stance, strengths, success, Easy difficulty.
- **Terracotta** `#ED8B72` on `#3A1E1A` — "Against" stance, weaknesses, errors, Hard difficulty.
- **Amber** `#E2B45C` on `#3A2C12` — warnings, Medium difficulty, ranked points.
- **Sky** `#86B0E3` on `#182637` — informational, Learning mode.

### Light ("Arena Day")
- **Canvas** `#F6F4F0` (warm paper), **Surface** `#FFFFFF`, **Inset** `#EDE9E2`.
- **Ink** `#1A1719`, **Ink Muted** `#605B58`, **Ink Hint** `#7A7570`.
- **Hairline** `#E6E1D9`, **Hairline Strong** `#D3CCC1`.
- **Brass** darkens to `#9A7520` for text and icons so it passes contrast. Primary buttons in light mode are **Ink** `#1A1719` with paper text; brass stays an accent, not a fill.
- Semantic pairs lighten: Sage `#256B4D` on `#E3F2EA`, Terracotta `#A8482F` on `#FBE7E1`, Amber `#8A5E10` on `#FBF0D9`, Sky `#355F9A` on `#E4ECF7`.

### Rank colors (both themes)
Newcomer stone `#8E8A85`, Challenger bronze `#B5793F`, Debater silver `#A9B0BA`, Orator brass `#D4A84B`, Grandmaster ice `#CFE3F0`. Ranks are drawn with Lucide icons, never emoji.

## 3. Typography Rules

- **Display & UI:** Outfit. Geometric but warm. Headlines use weight 600–700, tracking −0.02em. Never above 48 px on phones.
- **Numbers:** JetBrains Mono for anything that counts: timers, scores, rank points, usage. Tabular, weight 500–600.
- **Scale** (see `app_typography.dart`): display 48/40/36, headline 32/28/24, title 20/18/16, body 16/14/13, label 14/12/11. Body line-height 1.5, max ~65 characters per line.
- Hierarchy comes from weight and color (Ink vs Ink Muted), not from size jumps.
- **Banned:** Inter, Poppins, Roboto defaults, any serif in UI, emoji in text.

## 4. Component Stylings

All components live in `lib/ui`. Screens compose them; screens do not invent new button styles.

- **Buttons** (`AppButton`): four variants. *Primary* is the CTA fill (Brass in dark, Ink in light), 52 px tall, radius 14, label 14/600, optional leading Phosphor icon. *Secondary* is Surface with Hairline Strong border. *Ghost* is text only. *Danger* is Terracotta text on Terracotta soft. Press feedback is a 0.98 scale over 90 ms. No gradients, no shimmer, no outer glow. Loading replaces the label with a 16 px progress ring in the label color.
- **Icon buttons** (`AppIconButton`): 44 px hit target, 20 px Lucide icon, circular Surface Raised fill on hover/press only.
- **Cards** (`AppCard`): Surface fill, 1 px Hairline, radius 20, padding 20. Elevation is expressed by surface step, not shadow. Light mode may add a 8% warm shadow at y 6 / blur 20. Interactive cards use `Pressable` for scale feedback.
- **Chips / pills** (`AppPill`): 28 px tall, radius pill, 12/600 label, semantic bg/text pairs above. Optional 14 px leading icon.
- **Inputs**: label above in Ink Muted 12/600, field fill Surface Raised (dark) or Inset (light), radius 14, 1 px Hairline, focus ring 2 px Brass, error text below in Terracotta. No floating labels.
- **Navigation bar**: Surface with top Hairline, Lucide icons, heavier stroke when selected, Brass Soft indicator pill, 12/600 labels.
- **Loaders**: `AppSkeleton` shimmer blocks matching the layout. Circular spinners only inside buttons.
- **Empty states** (`AppEmptyState`): 48 px duotone icon in Ink Hint, title 16/600, one line of body, one Secondary button.
- **Avatars**: Dicebear SVG in a circle with a 2 px ring in the rank color.
- **Score ring**: 8 px stroke, Inset track, Brass fill, JetBrains Mono number centered.

## 5. Layout Principles

- Page gutter 20 px. Section gap 24 px. Related items 12 px. Max content width 560 px on desktop for forms, 960 px for dashboards, centered.
- Home is asymmetric: greeting + avatar row, then a wide rank card beside a narrow usage card, then mode rows as full-width list items with a leading icon tile. No three-equal-cards row.
- Lists use rows with Hairline dividers inside one Surface instead of a card per item.
- One primary action per screen, bottom-anchored on phones.
- Everything collapses to one column under 600 px. No horizontal scrolling on phones.

## 6. Motion & Interaction

- Durations: 90 ms press, 180 ms state change, 260 ms enter. Curve `easeOutCubic`. Nothing linear.
- Screen content enters as a stagger: each block 40 ms after the previous, fade + 8 px rise. Only on first build, never on tab switch.
- Respect `MediaQuery.disableAnimations`.
- Permitted loops: typing indicator dots, timer pulse under 60 s.
- Banned: shimmer sweeps on buttons, aurora blobs, infinite floating, radial glows behind content.

## 7. Icons

Lucide icons via `lucide_icons_flutter`. The regular stroke is the default; the 600-weight stroke (`*Filled` names) marks the selected navigation item and rank emblems. Mapped once in `lib/ui/app_icons.dart`; screens never reference `Icons.*` or `LucideIcons.*` directly.

## 8. Anti-Patterns (Banned)

- Emoji anywhere in UI.
- Purple or neon anything. Outer glows. Gradient-filled buttons or text.
- Pure black `#000000`.
- More than one accent color on a screen.
- Three equal cards in a row.
- Hardcoded `Colors.white`, `Colors.grey`, hex literals in screens. Use `context.colors`.
- Inline font sizes. Use `context.text` roles.
- `isDark ? a : b` in widgets. Add a token instead.
- Fake "searching for opponent" states. Say what is happening.
